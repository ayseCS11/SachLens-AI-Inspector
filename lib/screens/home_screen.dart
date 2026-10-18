import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'poster_screen.dart';
import '../core/analyzer.dart';
import 'batch_screen.dart';
import 'cleaner_screen.dart';
import 'compare_screen.dart';
import 'link_screen.dart';
import 'privacy_screen.dart';
import 'result_screen.dart';

const int _maxBytes = 25 * 1024 * 1024; // 25 MB keeps phones responsive

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  String _status = '';

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fromImagePicker(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    final String name = picked.name;

    // Remove the temporary copy the picker made, so nothing stays on disk.
    try {
      await File(picked.path).delete();
    } catch (_) {}

    await _analyze(name, bytes);
  }

  Future<void> _fromFilePicker() async {
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (file == null) return;

    Uint8List bytes;
    try {
      bytes = await file.readAsBytes(); // read straight into memory
    } catch (_) {
      _toast('Could not read that file. Please try another one.');
      return;
    }

    await _analyze(file.name, bytes);
  }

  Future<void> _analyze(String name, Uint8List bytes) async {
    if (bytes.length > _maxBytes) {
      _toast('That file is larger than 25 MB. Please pick a smaller one.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Reading file details...';
    });

    try {
      final scan = await analyzeBytes(
        name,
        bytes,
        onStatus: (s) {
          if (mounted) setState(() => _status = s);
        },
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultScreen(result: scan)),
      );
    } catch (e) {
      _toast('Something went wrong while checking this file.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 96,
                    height: 96,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SachLens',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Fake Document & AI Image Checker',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Chip(
                  avatar: Icon(Icons.lock, size: 18),
                  label: Text('Nothing leaves your phone'),
                ),
              ),
              const Spacer(),
              if (_busy) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                Text(_status, textAlign: TextAlign.center),
              ] else ...[
                FilledButton.icon(
                  onPressed: () => _open(const PosterScreen()),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Check a poster'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _fromImagePicker(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Scan with camera'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _fromImagePicker(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick an image'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _fromFilePicker,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Pick a PDF or file'),
                ),
                const SizedBox(height: 20),
                Text(
                  'More tools',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.library_add_check, size: 18),
                      label: const Text('Batch scan'),
                      onPressed: () => _open(const BatchScreen()),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.compare, size: 18),
                      label: const Text('Compare with original'),
                      onPressed: () => _open(const CompareScreen()),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.link, size: 18),
                      label: const Text('Link checker'),
                      onPressed: () => _open(const LinkScreen()),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.cleaning_services, size: 18),
                      label: const Text('Privacy Cleaner'),
                      onPressed: () => _open(const CleanerScreen()),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.shield, size: 18),
                      label: const Text('Your privacy'),
                      onPressed: () => _open(const PrivacyScreen()),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Files are checked in memory and never saved or uploaded.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}