import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../checks/country_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../checks/ocr_lines.dart';
import '../checks/poster_image.dart';
import '../checks/poster_rules.dart';
import '../checks/qr_service.dart';

Color _severityColor(double s) {
  if (s >= 0.7) return Colors.red.shade700;
  if (s >= 0.45) return Colors.deepOrange.shade600;
  return Colors.amber.shade800;
}

class PosterScreen extends StatefulWidget {
  const PosterScreen({super.key});

  @override
  State<PosterScreen> createState() => _PosterScreenState();
}

class _PosterScreenState extends State<PosterScreen> {
  final ImagePicker _picker = ImagePicker();

  PosterImage? _image;
  List<OcrLine> _lines = [];
  PosterAnalysis? _analysis;
  bool _busy = false;
  String _status = '';
  String? _error;
  int? _selected;
  bool _showHighlights = true;
  Widget _readingCard(PosterAnalysis a) {
    final notes = <String>[];
    final pct = (a.quality * 100).round();
    if (a.quality < 0.5) {
      notes.add(
          'The text could not be read well ($pct percent looked like real words). It may be in an unsupported script, or the photo may be blurry.');
    } else if (a.quality < 0.75) {
      notes.add(
          'The text was only partly clear ($pct percent). Some words may be missing, so some red flags may be missing too. Try a sharper, straighter photo.');
    }
    if (a.awareness) {
      notes.add(
          'This poster contains scam warning wording. The flags below may be examples it warns about, or the poster may use these words to look trustworthy. Read each flag and judge.');
    }
    if (notes.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: notes
              .map(
                (n) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(n, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Widget _countryCard() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    final help = helpFor(code);

    Widget lineList(List<String> lines) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('• $l', style: const TextStyle(fontSize: 12)),
      ))
          .toList(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Official help for ${help.name}',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text(
              'SachLens never opens these. Type the address yourself, and check it, because websites change.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            lineList(help.lines),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Help for other countries',
                  style: TextStyle(fontSize: 13)),
              children: allCountryHelp
                  .where((c) => c.code != help.code)
                  .map(
                    (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      lineList(c.lines),
                    ],
                  ),
                ),
              )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _pick(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final Uint8List raw = await picked.readAsBytes();
    try {
      await File(picked.path).delete(); // remove the picker's temporary copy
    } catch (_) {}

    await _analyze(raw);
  }

  Future<void> _analyze(Uint8List raw) async {
    setState(() {
      _busy = true;
      _status = 'Preparing the photo...';
      _analysis = null;
      _image = null;
      _lines = [];
      _selected = null;
      _error = null;
    });

    var stage = 'preparing the photo';
    try {
      final prepared = await Isolate.run(() => preparePosterImage(raw));
      if (prepared == null) {
        if (!mounted) return;
        setState(() => _error =
        'That photo could not be opened. Please try a JPEG or PNG photo.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _image = prepared;
        _status = 'Reading the text...';
      });

      stage = 'reading the text';
      final lines = await extractLines(prepared.bytes);

      if (!mounted) return;
      setState(() => _status = 'Looking for QR codes...');

      stage = 'looking for QR codes';
      List<String> qr = [];
      try {
        qr = await readQrCodes(prepared.bytes);
      } catch (_) {
        // A failed QR read never stops the other checks.
      }

      if (!mounted) return;
      setState(() => _status = 'Looking for red flags...');

      stage = 'checking for red flags';
      final analysis = analyzePoster(lines, qrCodes: qr);

      if (!mounted) return;
      setState(() {
        _lines = lines;
        _analysis = analysis;
      });
    } catch (e, st) {
      debugPrint('SachLens poster error while $stage: $e\n$st');
      if (mounted) {
        setState(() => _error =
        'Something went wrong while $stage.\n\nDetails:\n$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _levelColor(PosterLevel l) {
    switch (l) {
      case PosterLevel.high:
        return Colors.red.shade700;
      case PosterLevel.careful:
        return Colors.deepOrange.shade600;
      case PosterLevel.none:
        return Colors.green.shade700;
      case PosterLevel.unreadable:
        return Colors.blueGrey;
    }
  }

  String _levelTitle(PosterLevel l) {
    switch (l) {
      case PosterLevel.high:
        return 'High risk: many red flags';
      case PosterLevel.careful:
        return 'Be careful: some red flags';
      case PosterLevel.none:
        return 'No obvious red flags found';
      case PosterLevel.unreadable:
        return 'Could not read this poster well';
    }
  }

  String _levelSubtitle(PosterLevel l) {
    switch (l) {
      case PosterLevel.high:
        return 'Do not pay or share documents. Confirm the offer yourself with the organisation first.';
      case PosterLevel.careful:
        return 'Check each flag below before you trust this poster.';
      case PosterLevel.none:
        return 'This is not proof that the poster is genuine. Always confirm with the organisation yourself.';
      case PosterLevel.unreadable:
        return 'Try a straight on, sharp photo with the whole poster in view. Text in Urdu, Arabic and some other scripts cannot be read yet, and SachLens will not guess about text it cannot read.';
    }
  }

  IconData _levelIcon(PosterLevel l) {
    switch (l) {
      case PosterLevel.high:
        return Icons.dangerous;
      case PosterLevel.careful:
        return Icons.warning_amber_rounded;
      case PosterLevel.none:
        return Icons.help_outline;
      case PosterLevel.unreadable:
        return Icons.text_fields;
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied')),
    );
  }

  Future<void> _share(PosterAnalysis a) async {
    final b = StringBuffer('SachLens poster check\n');
    b.writeln(_levelTitle(a.level));
    b.writeln('Risk level: ${a.riskPercent} of 100\n');
    for (var i = 0; i < a.flags.length; i++) {
      b.writeln('${i + 1}. ${a.flags[i].title}');
    }
    b.writeln(
        '\nChecked on the phone. A decision aid, not proof. Confirm with the organisation yourself.');
    try {
      await SharePlus.instance.share(ShareParams(text: b.toString()));
    } catch (_) {}
  }

  Widget _tipsCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For a good result',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Stand straight in front of the poster and fit all of it in the photo.',
                style: TextStyle(fontSize: 13)),
            Text('• Use good light and avoid glare or shadows.',
                style: TextStyle(fontSize: 13)),
            Text('• Hold the phone steady so the small print is sharp.',
                style: TextStyle(fontSize: 13)),
            Text('• English and Roman Urdu text can be read. Urdu script cannot yet.',
                style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _posterView(PosterImage img, PosterAnalysis? a) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: img.width / img.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(img.bytes, fit: BoxFit.fill),
            if (a != null && _showHighlights)
              CustomPaint(
                painter: _FlagPainter(img, _lines, a.flags, _selected),
              ),
          ],
        ),
      ),
    );
  }

  Widget _riskMeter(PosterAnalysis a) {
    final color = _levelColor(a.level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Risk level: ${a.riskPercent} of 100',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: a.riskPercent / 100,
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'A rough guide built from the red flags below. It is not a probability.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _flagCard(int i, PosterFlag f) {
    final color = _severityColor(f.severity);
    final selected = _selected == i;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selected = selected ? null : i),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: Text('${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(f.detail, style: const TextStyle(fontSize: 13)),
                    if (f.lines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Not marked on the photo',
                            style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: SelectableText(value, style: const TextStyle(fontSize: 13)),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () => _copy(value),
      ),
    );
  }

  Widget _contactsCard(PosterAnalysis a) {
    if (a.phones.isEmpty && a.emails.isEmpty && a.links.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact details on the poster',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text(
              'Search each one online together with the word scam and see what people say. SachLens never opens or calls them.',
              style: TextStyle(fontSize: 12),
            ),
            ...a.phones.map((p) => _contactRow(Icons.phone, p)),
            ...a.emails.map((e) => _contactRow(Icons.email, e)),
            ...a.links.map((l) => _contactRow(Icons.link, l)),
          ],
        ),
      ),
    );
  }

  Widget _goodSignsCard(PosterAnalysis a) {
    if (a.goodSigns.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good signs, still to be checked',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...a.goodSigns.map(
                  (g) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                        size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(g, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifyCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to check this poster yourself',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '1. Find the organisation official website yourself. Do not use the link or number on the poster. Check that the same offer is listed there.\n'
                  '2. Call the organisation using a number from its official website.\n'
                  '3. Search the company name and phone number together with the word scam, and read independent reviews.\n'
                  '4. For jobs abroad, check that the agent holds a valid licence with your government overseas employment office.\n'
                  '5. For companies, look in your national company register.\n'
                  '6. Never pay before you have confirmed the offer and the payment details on the official website. Pay only into an account in the organisation own name.\n'
                  '7. If you can, visit the office in person with someone you trust.\n'
                  '8. If you were scammed, report it to your national cybercrime service at once.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _analysis;
    final img = _image;

    return Scaffold(
      appBar: AppBar(title: const Text('Check a poster')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_busy) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Take a photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 12),
          ],
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(_error!),
              ),
            ),
          if (img == null && !_busy && _error == null) _tipsCard(),
          if (img != null) ...[
            _posterView(img, a),
            if (a != null && a.flags.any((f) => f.lines.isNotEmpty))
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show red flags on the poster'),
                subtitle: const Text(
                    'The numbers match the list below. Tap a flag to highlight it.'),
                value: _showHighlights,
                onChanged: (v) => setState(() => _showHighlights = v),
              ),
          ],
          if (a != null) ...[
            const SizedBox(height: 8),
            Card(
              color: _levelColor(a.level).withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(_levelIcon(a.level),
                        size: 44, color: _levelColor(a.level)),
                    const SizedBox(height: 8),
                    Text(
                      _levelTitle(a.level),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _levelColor(a.level),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_levelSubtitle(a.level), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            if (a.level != PosterLevel.unreadable) ...[
              const SizedBox(height: 12),
              _riskMeter(a),
            ],
            const SizedBox(height: 12),
            _readingCard(a),
            if (a.flags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Red flags (${a.flags.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...List.generate(a.flags.length, (i) => _flagCard(i, a.flags[i])),
            ],
            const SizedBox(height: 8),
            _goodSignsCard(a),
            _contactsCard(a),
            if (a.level != PosterLevel.unreadable) _verifyCard(),
            if (a.level != PosterLevel.unreadable) _countryCard(),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => _share(a),
              icon: const Icon(Icons.share),
              label: const Text('Share summary'),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'SachLens finds warning signs in the words, links and codes on a poster. It cannot prove that a poster is genuine, '
                      'and some honest posters use words that look like red flags. Always confirm with the organisation yourself.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final PosterImage image;
  final List<OcrLine> lines;
  final List<PosterFlag> flags;
  final int? selected;

  _FlagPainter(this.image, this.lines, this.flags, this.selected);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / image.width;

    for (var f = 0; f < flags.length; f++) {
      final flag = flags[f];
      final color = _severityColor(flag.severity);
      final isSelected = selected == f;

      final fill = Paint()..color = color.withValues(alpha: isSelected ? 0.35 : 0.18);
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 4 : 2;

      Rect? first;
      for (final i in flag.lines) {
        if (i < 0 || i >= lines.length) continue;
        final b = lines[i].box;
        final r = Rect.fromLTRB(
          b.left * scale,
          b.top * scale,
          b.right * scale,
          b.bottom * scale,
        ).inflate(3);
        canvas.drawRect(r, fill);
        canvas.drawRect(r, stroke);
        first ??= r;
      }

      if (first != null) {
        final center = Offset(
          first.left < 12 ? 12 : first.left,
          first.top < 12 ? 12 : first.top,
        );
        canvas.drawCircle(center, 11, Paint()..color = color);
        final tp = TextPainter(
          text: TextSpan(
            text: '${f + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) => true;
}