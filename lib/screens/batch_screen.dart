import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/analyzer.dart';
import '../core/scoring.dart';
import '../core/signal.dart';
import '../core/verdict_style.dart';

const int _maxFiles = 20;
const int _maxBytes = 25 * 1024 * 1024;

class _BatchItem {
  final String name;
  final Verdict? verdict; // null when the file could not be checked
  final double score;
  final List<Signal> signals;
  final String? error;

  const _BatchItem({
    required this.name,
    required this.verdict,
    required this.score,
    required this.signals,
    this.error,
  });

  factory _BatchItem.fromResult(ScanResult r) => _BatchItem(
    name: r.fileName,
    verdict: r.verdict,
    score: r.score,
    signals: r.signals,
  );

  factory _BatchItem.failed(String name, String message) => _BatchItem(
    name: name,
    verdict: null,
    score: 0,
    signals: const [],
    error: message,
  );

  int get rank {
    switch (verdict) {
      case Verdict.suspicious:
        return 0;
      case Verdict.cannotDetermine:
        return 1;
      case Verdict.noWarningSigns:
        return 2;
      case Verdict.likelyAuthentic:
        return 3;
      case null:
        return 4;
    }
  }
}

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  List<_BatchItem> _items = [];
  bool _busy = false;
  bool _cancel = false;
  int _done = 0;
  int _total = 0;
  String _status = '';

  Future<void> _pickAndScan() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (files == null || files.isEmpty) return;

    final chosen = files.take(_maxFiles).toList();

    setState(() {
      _busy = true;
      _cancel = false;
      _done = 0;
      _total = chosen.length;
      _items = [];
    });

    final results = <_BatchItem>[];

    for (final f in chosen) {
      if (_cancel) break;
      if (mounted) {
        setState(() => _status = 'Checking ${_done + 1} of $_total: ${f.name}');
      }

      try {
        final bytes = await f.readAsBytes();
        if (bytes.length > _maxBytes) {
          results.add(_BatchItem.failed(f.name, 'Larger than 25 MB, skipped.'));
        } else {
          final r = await analyzeBytes(f.name, bytes);
          results.add(_BatchItem.fromResult(r)); // the file itself is dropped
        }
      } catch (_) {
        results.add(_BatchItem.failed(f.name, 'Could not be checked.'));
      }

      if (mounted) setState(() => _done++);
    }

    results.sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      return byRank != 0 ? byRank : b.score.compareTo(a.score);
    });

    if (!mounted) return;
    setState(() {
      _items = results;
      _busy = false;
    });
  }

  int _count(Verdict v) => _items.where((i) => i.verdict == v).length;

  Future<void> _shareSummary() async {
    final b = StringBuffer('SachLens batch summary\n\n');
    for (final i in _items) {
      final label = i.verdict == null ? 'Not checked' : verdictLabel(i.verdict!);
      b.writeln('$label: ${i.name}');
    }
    b.writeln('\nChecked on the device. A decision aid, not proof.');
    try {
      await SharePlus.instance.share(ShareParams(text: b.toString()));
    } catch (_) {}
  }

  Widget _itemTile(_BatchItem i) {
    final color = i.verdict == null ? Colors.grey : verdictColor(i.verdict!);
    final label = i.verdict == null ? 'Not checked' : verdictLabel(i.verdict!);

    return Card(
      child: ExpansionTile(
        leading: Icon(
          i.verdict == null ? Icons.block : verdictIcon(i.verdict!),
          color: color,
        ),
        title: Text(i.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          i.error ?? label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        children: i.signals
            .map((s) => ListTile(
          dense: true,
          title: Text(s.name),
          subtitle: Text(s.reason),
        ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch scan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Check up to 20 files at once, such as certificates or invoices. '
                'The most suspicious files are listed first. Everything stays on this phone.',
          ),
          const SizedBox(height: 16),
          if (_busy) ...[
            LinearProgressIndicator(value: _total == 0 ? null : _done / _total),
            const SizedBox(height: 8),
            Text(_status),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() => _cancel = true),
              child: const Text('Stop after this file'),
            ),
          ] else
            FilledButton.icon(
              onPressed: _pickAndScan,
              icon: const Icon(Icons.library_add_check),
              label: const Text('Choose files'),
            ),
          if (!_busy && _items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('Suspicious: ${_count(Verdict.suspicious)}')),
                Chip(
                    label: Text(
                        'Cannot determine: ${_count(Verdict.cannotDetermine)}')),
                Chip(
                    label: Text(
                        'No Warning Signs Found! : ${_count(Verdict.likelyAuthentic)}')),
              ],
            ),
            const SizedBox(height: 8),
            ..._items.map(_itemTile),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _shareSummary,
              icon: const Icon(Icons.share),
              label: const Text('Share summary'),
            ),
          ],
        ],
      ),
    );
  }
}