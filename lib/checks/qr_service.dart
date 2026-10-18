import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:path_provider/path_provider.dart';

import 'metadata_check.dart' show FileKind, detectKind;
import 'ocr_service.dart' show renderPdfPages;

/// Reads one image and returns the text of every QR code in it.
/// The temporary file is always deleted.
Future<List<String>> _scanImage(Uint8List imageBytes, String extension) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/sachlens_qr.$extension');
  final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
  try {
    await file.writeAsBytes(imageBytes, flush: true);
    final codes =
    await scanner.processImage(InputImage.fromFilePath(file.path));
    return codes
        .map((c) => c.rawValue ?? '')
        .where((v) => v.trim().isNotEmpty)
        .toList();
  } finally {
    await scanner.close();
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Finds QR codes in a JPEG, PNG or PDF. Runs entirely on the device.
Future<List<String>> readQrCodes(Uint8List bytes) async {
  final found = <String>[];

  switch (detectKind(bytes)) {
    case FileKind.jpeg:
      found.addAll(await _scanImage(bytes, 'jpg'));
      break;
    case FileKind.png:
      found.addAll(await _scanImage(bytes, 'png'));
      break;
    case FileKind.pdf:
      final pages = await renderPdfPages(bytes);
      for (final page in pages) {
        try {
          found.addAll(await _scanImage(page, 'jpg'));
        } catch (_) {}
      }
      break;
    case FileKind.other:
      break;
  }

  return found.toSet().toList(); // remove duplicates
}