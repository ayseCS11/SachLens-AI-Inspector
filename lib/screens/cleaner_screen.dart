import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../checks/privacy_cleaner.dart';

class CleanerScreen extends StatefulWidget {
  const CleanerScreen({super.key});

  @override
  State<CleanerScreen> createState() => _CleanerScreenState();
}

class _CleanerScreenState extends State<CleanerScreen> {
  final ImagePicker _picker = ImagePicker();
  CleanResult? _clean;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    try {
      await File(picked.path).delete(); // remove the picker's temporary copy
    } catch (_) {}

    final result = cleanFile(bytes);
    if (result == null) {
      _toast('Only JPEG and PNG images can be cleaned.');
      return;
    }
    setState(() => _clean = result);
  }

  Future<void> _share() async {
    final c = _clean;
    if (c == null) return;
    final ext = c.isPng ? 'png' : 'jpg';
    final mime = c.isPng ? 'image/png' : 'image/jpeg';
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(c.bytes, mimeType: mime, name: 'sachlens_clean.$ext'),
          ],
        ),
      );
    } catch (_) {
      _toast('Could not open the share menu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _clean;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Cleaner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Remove location, device details, editing info and comments from a photo before you share it. '
                'The picture itself is not changed or re compressed.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose a photo'),
          ),
          if (c != null) ...[
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(c.bytes, height: 200, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.removed.isEmpty
                          ? 'No personal data was found in this file.'
                          : 'Removed from this copy:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...c.removed.map(
                          (r) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle,
                            color: Colors.green),
                        title: Text(r),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kept: the picture, its rotation, and any AI disclosure tags or Content Credentials. '
                          'A small note says the file was cleaned for privacy.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _share,
              icon: const Icon(Icons.share),
              label: const Text('Share cleaned copy'),
            ),
          ],
        ],
      ),
    );
  }
}