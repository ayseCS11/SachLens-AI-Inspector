import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../checks/compare_check.dart';
import '../widgets/heat_map_overlay.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _original;
  Uint8List? _suspect;
  CompareResult? _result;
  bool _busy = false;

  Future<Uint8List?> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    try {
      await File(picked.path).delete(); // remove the picker's temporary copy
    } catch (_) {}
    return bytes;
  }

  Future<void> _pickOriginal() async {
    final b = await _pickImage();
    if (b == null) return;
    setState(() {
      _original = b;
      _result = null;
    });
  }

  Future<void> _pickSuspect() async {
    final b = await _pickImage();
    if (b == null) return;
    setState(() {
      _suspect = b;
      _result = null;
    });
  }

  Future<void> _compare() async {
    final a = _original;
    final b = _suspect;
    if (a == null || b == null) return;

    setState(() => _busy = true);
    final result = await Isolate.run(() => compareImages(a, b));
    if (!mounted) return;
    setState(() {
      _result = result;
      _busy = false;
    });
  }

  Color _levelColor(CompareLevel l) {
    switch (l) {
      case CompareLevel.identical:
        return Colors.green.shade700;
      case CompareLevel.localChanges:
        return Colors.amber.shade800;
      case CompareLevel.majorChanges:
        return Colors.red.shade700;
      case CompareLevel.different:
        return Colors.blueGrey;
      case CompareLevel.error:
        return Colors.red.shade700;
    }
  }

  Widget _thumb(String label, Uint8List? bytes, VoidCallback onTap) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: bytes == null
                  ? const Center(child: Icon(Icons.add_photo_alternate, size: 40))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Compare with original')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose the original document and the copy you doubt. '
                'SachLens highlights where they differ. It works best with scans or screenshots of the same page.',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumb('Original', _original, _pickOriginal),
              const SizedBox(width: 12),
              _thumb('Suspect copy', _suspect, _pickSuspect),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_original == null || _suspect == null || _busy)
                ? null
                : _compare,
            icon: _busy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.compare),
            label: const Text('Compare'),
          ),
          if (r != null) ...[
            const SizedBox(height: 16),
            Card(
              color: _levelColor(r.level).withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.headline,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _levelColor(r.level),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(r.detail),
                  ],
                ),
              ),
            ),
            if (r.diff != null && _suspect != null) ...[
              const SizedBox(height: 16),
              Text('Differences on the suspect copy',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              HeatMapOverlay(bytes: _suspect!, ela: r.diff!),
              const SizedBox(height: 8),
              const Text(
                'Red areas differ from the original. A decision aid, not proof.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }
}