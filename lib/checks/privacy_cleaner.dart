import 'dart:convert';
import 'dart:typed_data';

import 'metadata_check.dart' show FileKind, detectKind;

/// A small honest receipt written into every cleaned file.
const String cleanedNote = 'Personal data removed by SachLens';

/// Tags that disclose AI origin or provenance. The cleaner never removes these.
const List<String> _disclosureHints = [
  'c2pa',
  'jumbf',
  'digitalsourcetype',
  'trainedalgorithmicmedia',
  'midjourney',
  'stable diffusion',
  'dall-e',
  'dalle',
  'openai',
  'firefly',
  'comfyui',
  'automatic1111',
  'novelai',
  'cfg scale',
  'sampler:',
];

bool _hasDisclosure(String lowerText) =>
    _disclosureHints.any(lowerText.contains);

class CleanResult {
  final Uint8List bytes;
  final bool isPng;
  final List<String> removed;

  const CleanResult({
    required this.bytes,
    required this.isPng,
    required this.removed,
  });
}

/// Returns null for file types that are not supported.
CleanResult? cleanFile(Uint8List input) {
  switch (detectKind(input)) {
    case FileKind.jpeg:
      return _cleanJpeg(input);
    case FileKind.png:
      return _cleanPng(input);
    case FileKind.pdf:
    case FileKind.other:
      return null;
  }
}

bool _startsWithAscii(Uint8List p, String s) {
  if (p.length < s.length) return false;
  for (var i = 0; i < s.length; i++) {
    if (p[i] != s.codeUnitAt(i)) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// JPEG
// ---------------------------------------------------------------------------

CleanResult? _cleanJpeg(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;

  final kept = BytesBuilder();
  final removed = <String>{};
  int? orientation;

  var i = 2;
  while (i + 4 <= b.length) {
    if (b[i] != 0xFF) break;
    final marker = b[i + 1];

    if (marker == 0xDA) break; // start of image data, copy the rest as it is
    if (marker == 0xFF) {
      i++; // padding byte
      continue;
    }
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD8)) {
      kept.add(b.sublist(i, i + 2)); // markers without a length
      i += 2;
      continue;
    }

    final len = (b[i + 2] << 8) | b[i + 3];
    if (len < 2 || i + 2 + len > b.length) break;

    final segment = b.sublist(i, i + 2 + len);
    final payload = segment.sublist(4);
    var keep = true;

    if (marker == 0xE1) {
      if (_startsWithAscii(payload, 'Exif\u0000')) {
        orientation ??= _exifOrientation(payload);
        keep = false;
        removed.add('Camera, device and location data (EXIF)');
      } else if (!_hasDisclosure(latin1.decode(payload).toLowerCase())) {
        keep = false;
        removed.add('Extended metadata (XMP)');
      }
    } else if (marker == 0xED) {
      keep = false;
      removed.add('Editing software info');
    } else if (marker == 0xFE) {
      keep = false;
      removed.add('Embedded comments');
    }

    if (keep) kept.add(segment);
    i += 2 + len;
  }

  final out = BytesBuilder();
  out.add(const [0xFF, 0xD8]);
  out.add(kept.takeBytes());
  if (orientation != null && orientation > 1 && orientation <= 8) {
    out.add(_orientationExif(orientation));
  }
  out.add(_jpegComment(cleanedNote));
  out.add(b.sublist(i));

  return CleanResult(
    bytes: out.takeBytes(),
    isPng: false,
    removed: removed.toList(),
  );
}

/// Reads the rotation value from an EXIF block, so photos stay upright.
int? _exifOrientation(Uint8List payload) {
  if (payload.length < 6 + 8) return null;
  final t = payload.sublist(6);
  final little = t[0] == 0x49 && t[1] == 0x49;

  int u16(int o) =>
      little ? (t[o] | (t[o + 1] << 8)) : ((t[o] << 8) | t[o + 1]);
  int u32(int o) => little
      ? (t[o] | (t[o + 1] << 8) | (t[o + 2] << 16) | (t[o + 3] << 24))
      : ((t[o] << 24) | (t[o + 1] << 16) | (t[o + 2] << 8) | t[o + 3]);

  final ifd = u32(4);
  if (ifd + 2 > t.length) return null;
  final count = u16(ifd);
  for (var k = 0; k < count; k++) {
    final e = ifd + 2 + k * 12;
    if (e + 12 > t.length) return null;
    if (u16(e) == 0x0112) return u16(e + 8);
  }
  return null;
}

/// A tiny EXIF block that holds only the rotation value.
Uint8List _orientationExif(int orientation) {
  return Uint8List.fromList([
    0xFF, 0xE1, 0x00, 0x22, // marker and length (34)
    0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif" and two zero bytes
    0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // big endian header
    0x00, 0x01, // one entry
    0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, orientation, 0x00,
    0x00, // orientation entry
    0x00, 0x00, 0x00, 0x00, // no next block
  ]);
}

Uint8List _jpegComment(String text) {
  final t = ascii.encode(text);
  final len = t.length + 2;
  return Uint8List.fromList([0xFF, 0xFE, (len >> 8) & 0xFF, len & 0xFF, ...t]);
}

// ---------------------------------------------------------------------------
// PNG
// ---------------------------------------------------------------------------

CleanResult? _cleanPng(Uint8List b) {
  if (b.length < 8 + 12) return null;

  final out = BytesBuilder();
  out.add(b.sublist(0, 8)); // PNG signature
  final removed = <String>{};
  var receiptAdded = false;

  var i = 8;
  while (i + 12 <= b.length) {
    final len = (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
    final type = String.fromCharCodes(b.sublist(i + 4, i + 8));
    final end = i + 12 + len;

    if (len < 0 || end > b.length) {
      out.add(b.sublist(i)); // damaged file: copy the rest unchanged
      break;
    }

    var keep = true;
    if (type == 'eXIf') {
      keep = false;
      removed.add('Camera, device and location data (EXIF)');
    } else if (type == 'tIME') {
      keep = false;
      removed.add('Time stamp');
    } else if (type == 'tEXt' || type == 'zTXt' || type == 'iTXt') {
      final text = latin1.decode(b.sublist(i + 8, i + 8 + len)).toLowerCase();
      if (!_hasDisclosure(text)) {
        keep = false;
        removed.add('Text metadata');
      }
    }

    if (type == 'IDAT' && !receiptAdded) {
      out.add(_pngTextChunk('SachLens', cleanedNote));
      receiptAdded = true;
    }
    if (keep) out.add(b.sublist(i, end));

    i = end;
    if (type == 'IEND') break;
  }

  return CleanResult(
    bytes: out.takeBytes(),
    isPng: true,
    removed: removed.toList(),
  );
}

Uint8List _pngTextChunk(String keyword, String text) {
  final type = ascii.encode('tEXt');
  final data = <int>[...ascii.encode(keyword), 0, ...ascii.encode(text)];
  final crc = _crc32([...type, ...data]);
  return Uint8List.fromList([
    ..._be32(data.length),
    ...type,
    ...data,
    ..._be32(crc),
  ]);
}

List<int> _be32(int v) =>
    [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final byte in bytes) {
    c ^= byte;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}