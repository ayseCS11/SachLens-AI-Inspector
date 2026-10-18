import 'dart:io';
import 'dart:typed_data';
import 'ocr_lines.dart' show linesFrom, mergeRows;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import 'metadata_check.dart' show FileKind, detectKind;

const int _maxPdfPages = 3; // keeps reading fast on phones
/// Used by the QR reader to look at PDF pages as images.
Future<List<Uint8List>> renderPdfPages(Uint8List pdfBytes) =>
    _renderPdfPages(pdfBytes);

/// Renders the first pages of a PDF to images. Returns an empty list on failure.
Future<List<Uint8List>> _renderPdfPages(Uint8List pdfBytes) async {
  final pages = <Uint8List>[];
  PdfDocument? doc;
  try {
    doc = await PdfDocument.openData(pdfBytes);
    final count = doc.pagesCount < _maxPdfPages ? doc.pagesCount : _maxPdfPages;
    for (var i = 1; i <= count; i++) {
      final page = await doc.getPage(i);
      try {
        final image = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: 90,
        );
        if (image != null) pages.add(image.bytes);
      } finally {
        await page.close();
      }
    }
  } catch (_) {
    // Fall through with whatever we managed to render.
  } finally {
    await doc?.close();
  }
  return pages;
}

/// Reads text from one image. The temporary file is always deleted.
Future<String> _ocrImage(Uint8List imageBytes, String extension) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/sachlens_scan.$extension');
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    await file.writeAsBytes(imageBytes, flush: true);
    final result =
    await recognizer.processImage(InputImage.fromFilePath(file.path));
    final rows = mergeRows(linesFrom(result));
    return rows.map((r) => r.text).join('\n');
  } finally {
    await recognizer.close();
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Extracts text from a JPEG, PNG or PDF. Returns an empty string if nothing
/// could be read. Everything runs on the device.
Future<String> extractText(Uint8List bytes) async {
  final kind = detectKind(bytes);

  switch (kind) {
    case FileKind.jpeg:
      return _ocrImage(bytes, 'jpg');
    case FileKind.png:
      return _ocrImage(bytes, 'png');
    case FileKind.pdf:
      final pages = await _renderPdfPages(bytes);
      final buffer = StringBuffer();
      for (final page in pages) {
        buffer.writeln(await _ocrImage(page, 'jpg'));
      }
      return buffer.toString();
    case FileKind.other:
      return '';
  }
}