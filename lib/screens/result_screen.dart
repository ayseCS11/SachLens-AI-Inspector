import 'package:flutter/material.dart';

import '../core/scoring.dart';
import '../core/signal.dart';
import '../reports/pdf_report.dart';
import '../widgets/heat_map_overlay.dart';
import 'package:flutter/services.dart';

class ResultScreen extends StatefulWidget {
  final ScanResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showHeat = false;
  bool _saving = false;

  ScanResult get result => widget.result;

  String get _title {
    switch (result.verdict) {
      case Verdict.suspicious:
        return 'Suspicious';
      case Verdict.likelyAuthentic:
        return 'Likely authentic';
      case Verdict.noWarningSigns:
        return 'No warning signs found';
      case Verdict.cannotDetermine:
        return 'Cannot determine';
    }
  }

  String get _subtitle {
    switch (result.verdict) {
      case Verdict.suspicious:
        return 'We found signs that this file may be edited, AI made or a scam.';
      case Verdict.likelyAuthentic:
        return 'We found no warning signs and some positive evidence.';
      case Verdict.noWarningSigns:
        return 'We found nothing worrying, but this does not prove it is real. Confirm on the official website.';
      case Verdict.cannotDetermine:
        return 'There is not enough evidence either way.';
    }
  }

  Color get _color {
    switch (result.verdict) {
      case Verdict.suspicious:
        return Colors.red.shade700;
      case Verdict.likelyAuthentic:
        return Colors.green.shade700;
      case Verdict.noWarningSigns:
        return Colors.lightGreen.shade800;
      case Verdict.cannotDetermine:
        return Colors.amber.shade800;
    }
  }

  IconData get _icon {
    switch (result.verdict) {
      case Verdict.suspicious:
        return Icons.warning_amber_rounded;
      case Verdict.likelyAuthentic:
        return Icons.verified;
      case Verdict.noWarningSigns:
        return Icons.fact_check_outlined;
      case Verdict.cannotDetermine:
        return Icons.help_outline;
    }
  }

  Widget _signalTile(Signal s) {
    IconData icon;
    Color color;
    if (s.role == SignalRole.socialMedia || s.role == SignalRole.unreadable) {
      // These carry no suspicion number, so do not show a green tick.
      icon = Icons.info;
      color = Colors.amber.shade800;
    } else if (s.suspicion >= 0.7) {
      icon = Icons.error;
      color = Colors.red.shade700;
    } else if (s.suspicion <= 0.2) {
      icon = Icons.check_circle;
      color = Colors.green.shade700;
    } else {
      icon = Icons.info;
      color = Colors.amber.shade800;
    }
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(s.name),
      subtitle: Text(s.reason),
    );
  }
  Widget _riskMeter() {
    final pct = result.riskPercent;
    final label = pct >= 60 ? 'High' : (pct >= 30 ? 'Medium' : 'Low');
    final color = pct >= 60
        ? Colors.red.shade700
        : (pct >= 30 ? Colors.amber.shade800 : Colors.green.shade700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk level: $label ($pct of 100)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'A rough guide built from all the evidence below. It is not a probability.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _whyUnclear() {
    final names = result.signals.map((s) => s.name).toSet();
    final reasons = <String>[];

    if (names.contains('Metadata')) {
      reasons.add(
          'The file has no camera or creator details. This is normal for screenshots and for pictures that passed through WhatsApp or social media.');
    }
    if (result.extractedText.trim().length < 40) {
      reasons.add(
          'There is almost no readable text, so the number, date and wording checks had nothing to examine.');
    }
    reasons.add(
        'SachLens cannot look at a picture and tell whether AI drew it. It finds labels and traces that AI tools leave in the file. If those were removed, an AI picture looks the same as a real one.');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why there is no clear answer',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...reasons.map(
                  (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $r', style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'What helps: scan the original file instead of a WhatsApp or screenshot copy, compare it with the original if you have one, or confirm with the source.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _saveReport() async {
    setState(() => _saving = true);
    try {
      await shareReport(result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the report.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _preview() {
    final ela = result.ela;
    if (ela != null && _showHeat) {
      return HeatMapOverlay(bytes: result.bytes, ela: ela);
    }
    return Image.memory(
      result.bytes,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.picture_as_pdf, size: 64),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasHeat = result.ela != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 240,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _preview(),
              ),
            ),
          ),
          if (hasHeat)
            SwitchListTile(
              title: const Text('Show edit heat map'),
              subtitle: const Text(
                'Red areas react differently when the image is re saved. A hint, not proof.',
              ),
              value: _showHeat,
              onChanged: (v) => setState(() => _showHeat = v),
            ),
          const SizedBox(height: 4),
          Text(
            result.fileName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Card(
            color: _color.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(_icon, size: 48, color: _color),
                  const SizedBox(height: 8),
                  Text(
                    _title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: _color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_subtitle, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _riskMeter(),
          if (result.isSocialPost) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This looks like a social media post',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Open the organisation\'s own website yourself and look for the same notice on its careers or admissions page.\n'
                          '2. Check that the Facebook page is the official one: it should be linked from the organisation\'s own website.\n'
                          '3. Be careful with apply links that do not end in the organisation\'s own domain, and with Google Forms, WhatsApp or shortened links.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          if (result.verdict == Verdict.cannotDetermine) ...[
            _whyUnclear(),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: _saving ? null : _saveReport,
            icon: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.picture_as_pdf),
            label: const Text('Save or share report (PDF)'),
          ),
          const SizedBox(height: 16),
          if (result.qrCodes.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR codes found',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SachLens never opens these. Read the address before you trust it.',
                      style: TextStyle(fontSize: 12),
                    ),
                    ...result.qrCodes.map(
                          (q) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: SelectableText(
                          q,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: q));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Copied. Paste it into the Link checker.'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (result.extractedText.trim().length >= 40) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to confirm this document',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Find the official website of the issuer yourself. Do not use links or phone numbers from the document.\n'
                          '2. Contact their admissions or records office using the details on that site.\n'
                          '3. Ask for the application or reference number and check it in the official applicant portal.\n'
                          '4. Pay fees only through the official website. Never to an agent, a personal account, or a money transfer service.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...result.signals.map(_signalTile),
          if (result.extractedText.trim().isNotEmpty)
            ExpansionTile(
              title: const Text('Text we read from the file'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    result.extractedText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'SachLens is a decision aid. A clean result does not prove a file '
                    'is genuine, and a warning does not prove it is fake. '
                    'When in doubt, confirm with the issuer.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}