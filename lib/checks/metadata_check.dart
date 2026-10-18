import 'dart:convert';
import 'dart:typed_data';

import 'package:exif/exif.dart';

import '../core/signal.dart';

enum FileKind { jpeg, png, pdf, other }

/// Text that AI image tools or their settings often leave inside files.
const List<String> _aiMarkers = [
  'trainedalgorithmicmedia', // official AI label, also matches the composite version
  'midjourney',
  'stable diffusion',
  'stablediffusion',
  'dall-e',
  'dalle',
  'openai',
  'chatgpt',
  'gpt-4o',
  'gpt-image',
  'imagen',
  'gemini',
  'synthid',
  'bing image creator',
  'microsoft designer',
  'dreamstudio',
  'adobe firefly',
  'comfyui',
  'automatic1111',
  'novelai',
  'leonardo.ai',
  'ideogram',
  'cfg scale',
  'sampler:',
];

/// Software names that mean the file was edited or re saved by an editor.
const List<String> _editorTools = [
  'photoshop',
  'gimp',
  'canva',
  'pixlr',
  'snapseed',
  'lightroom',
  'facetune',
  'picsart',
  'paint.net',
  'illustrator',
  'sejda',
  'ilovepdf',
  'smallpdf',
  'pdfescape',
];

FileKind detectKind(Uint8List b) {
  if (b.length > 4 && b[0] == 0xFF && b[1] == 0xD8) return FileKind.jpeg;
  if (b.length > 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    return FileKind.png;
  }
  if (b.length > 4 &&
      b[0] == 0x25 &&
      b[1] == 0x50 &&
      b[2] == 0x44 &&
      b[3] == 0x46) {
    return FileKind.pdf;
  }
  return FileKind.other;
}

/// Metadata lives at the start and end of a file, so big files are only
/// read there. This keeps memory use low on phones.
String _headTail(Uint8List bytes) {
  const limit = 1024 * 1024;
  if (bytes.length <= limit * 2) return latin1.decode(bytes);
  return latin1.decode(bytes.sublist(0, limit)) +
      latin1.decode(bytes.sublist(bytes.length - limit));
}

/// Entry point. Safe to run inside an isolate, uses pure Dart only.
Future<List<Signal>> runMetadataChecks(Uint8List bytes) async {
  final kind = detectKind(bytes);
  final raw = _headTail(bytes);
  final lower = raw.toLowerCase();

  final signals = <Signal>[];

  // Page text in a PDF can mention AI tools for good reasons, so PDFs are only
  // searched in their creator fields. Images are searched in full.
  final aiSearchText = kind == FileKind.pdf
      ? _pdfToolFields(raw).join(' ').toLowerCase()
      : lower;
  signals.add(_aiTraceSignal(aiSearchText));

  final credentials = _credentialsSignal(lower);
  if (credentials != null) signals.add(credentials);

  if (lower.contains('removed by sachlens')) {
    signals.add(const Signal(
      name: 'Privacy cleaned',
      suspicion: 0.3,
      weight: 1,
      reason:
      'This file was cleaned for privacy by SachLens, so its original source details are gone. Treat its origin as unknown.',
    ));
  }

  switch (kind) {
    case FileKind.jpeg:
      signals.addAll(await _jpegSignals(bytes));
      break;
    case FileKind.png:
      signals.add(const Signal(
        name: 'Metadata',
        suspicion: 0.3,
        weight: 0.5,
        reason:
        'PNG files usually carry no camera data, so metadata can say little here.',
      ));
      break;
    case FileKind.pdf:
      signals.addAll(_pdfSignals(raw));
      break;
    case FileKind.other:
      signals.add(const Signal(
        name: 'File type',
        suspicion: 0.3,
        weight: 1,
        reason:
        'This file type is not fully supported yet, so only basic checks ran.',
      ));
      break;
  }
  return signals;
}

Signal _aiTraceSignal(String lower) {
  final hits = _aiMarkers.where(lower.contains).toList();
  if (hits.isNotEmpty) {
    return Signal(
      name: 'AI tool traces',
      suspicion: 0.95,
      weight: 4,
      reason:
      'The file contains markers typical of AI image tools (${hits.take(3).join(', ')}). '
          'Treat this as a strong hint, not proof.',
    );
  }
  return const Signal(
    name: 'AI tool traces',
    suspicion: 0.1,
    weight: 1,
    reason:
    'No known AI tool traces were found. This does not rule out AI, because traces are easy to remove and many AI images carry none.',
  );
}

Signal? _credentialsSignal(String lower) {
  if (lower.contains('c2pa') || lower.contains('jumbf')) {
    return const Signal(
      name: 'Content Credentials',
      suspicion: 0.3,
      weight: 0.5,
      reason:
      'Content Credentials data was found. Full signature checking comes in a later version.',
    );
  }
  return null;
}

Future<List<Signal>> _jpegSignals(Uint8List bytes) async {
  final out = <Signal>[];

  Map<String, IfdTag> data;
  try {
    data = await readExifFromBytes(bytes);
  } catch (_) {
    data = {};
  }

  if (data.isEmpty) {
    out.add(const Signal(
      name: 'Metadata',
      suspicion: 0.3,
      weight: 1,
      reason:
      'No camera data found. Sharing apps and screenshots remove it, so this alone proves nothing.',
    ));
    return out;
  }

  final software = data['Image Software']?.printable ?? '';
  final make = data['Image Make']?.printable ?? '';
  final model = data['Image Model']?.printable ?? '';

  if (software.isNotEmpty) {
    final lowerSoftware = software.toLowerCase();
    final editor = _editorTools.firstWhere(
          (e) => lowerSoftware.contains(e),
      orElse: () => '',
    );
    if (editor.isNotEmpty) {
      out.add(Signal(
        name: 'Editing software',
        suspicion: 0.85,
        weight: 3,
        reason: 'The file was last saved by "$software", an editing tool.',
      ));
    } else {
      out.add(Signal(
        name: 'Software tag',
        suspicion: 0.2,
        weight: 1,
        reason:
        'Software tag: "$software". Often just the phone or camera firmware.',
      ));
    }
  }

  if (make.isNotEmpty || model.isNotEmpty) {
    out.add(Signal(
      name: 'Camera data',
      suspicion: 0.05,
      weight: 2,
      reason:
      'Camera details are present (${('$make $model').trim()}). This describes the photo only, not the paper or subject, and it can be copied from another photo.',
    ));
  }

  final taken = _parseExifDate(data['EXIF DateTimeOriginal']?.printable);
  final saved = _parseExifDate(data['Image DateTime']?.printable);
  if (taken != null && saved != null) {
    final days = saved.difference(taken).inDays;
    if (days >= 1) {
      out.add(Signal(
        name: 'Dates',
        suspicion: 0.55,
        weight: 1.5,
        reason: 'The file was changed $days day(s) after it was taken.',
      ));
    } else {
      out.add(const Signal(
        name: 'Dates',
        suspicion: 0.05,
        weight: 1,
        reason: 'Capture date and save date agree.',
      ));
    }
  }

  return out;
}

DateTime? _parseExifDate(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})')
      .firstMatch(s.trim());
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
    int.parse(m.group(6)!),
  );
}

/// Names of the programs that made the PDF. Best effort: some PDFs store this
/// in compressed or encoded sections that cannot be read here.
Set<String> _pdfToolFields(String raw) {
  final out = <String>{};
  for (final m in RegExp(r'/(Producer|Creator)\s*\(([^)]{0,120})\)')
      .allMatches(raw)) {
    final v = m.group(2)!.trim();
    if (v.isNotEmpty) out.add(v);
  }
  for (final m in RegExp(r'<(?:xmp:CreatorTool|pdf:Producer)>([^<]{1,120})<')
      .allMatches(raw)) {
    final v = m.group(1)!.trim();
    if (v.isNotEmpty) out.add(v);
  }
  return out;
}

List<Signal> _pdfSignals(String raw) {
  final out = <Signal>[];
  final tools = _pdfToolFields(raw);

  if (tools.isEmpty) {
    out.add(const Signal(
      name: 'PDF creator',
      suspicion: 0.3,
      weight: 1,
      reason:
      'No creator information could be read from this PDF. It may be hidden or removed.',
    ));
  } else {
    final joined = tools.join(', ');
    final lowerJoined = joined.toLowerCase();
    final editor = _editorTools.firstWhere(
          (e) => lowerJoined.contains(e),
      orElse: () => '',
    );
    if (editor.isNotEmpty) {
      out.add(Signal(
        name: 'PDF editing tool',
        suspicion: 0.8,
        weight: 3,
        reason:
        'This PDF was made or changed with: $joined. Check that this fits where the document claims to come from. '
            'Official letters are rarely made with design or online editing tools.',
      ));
    } else {
      out.add(Signal(
        name: 'PDF creator',
        suspicion: 0.15,
        weight: 1,
        reason:
        'This PDF was created by: $joined. Word processors are used for genuine and fake letters alike, so this proves nothing.',
      ));
    }
  }

  final created = _parsePdfDate(
      RegExp(r'/CreationDate\s*\(D:(\d{14})').firstMatch(raw)?.group(1));
  final modified = _parsePdfDate(
      RegExp(r'/ModDate\s*\(D:(\d{14})').firstMatch(raw)?.group(1));
  if (created != null && modified != null) {
    final days = modified.difference(created).inDays;
    if (days >= 1) {
      out.add(Signal(
        name: 'PDF dates',
        suspicion: 0.5,
        weight: 1.5,
        reason: 'This PDF was changed $days day(s) after it was created.',
      ));
    } else {
      out.add(const Signal(
        name: 'PDF dates',
        suspicion: 0.05,
        weight: 1,
        reason: 'Creation date and change date agree.',
      ));
    }
  }

  return out;
}

DateTime? _parsePdfDate(String? s) {
  if (s == null || s.length < 14) return null;
  return DateTime.tryParse(
    '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)} '
        '${s.substring(8, 10)}:${s.substring(10, 12)}:${s.substring(12, 14)}',
  );
}