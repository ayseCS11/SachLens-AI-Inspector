import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/scoring.dart';
import '../core/signal.dart';

String _verdictLabel(Verdict v) {
  switch (v) {
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

PdfColor _verdictColor(Verdict v) {
  switch (v) {
    case Verdict.suspicious:
      return PdfColors.red800;
    case Verdict.likelyAuthentic:
      return PdfColors.green800;
    case Verdict.noWarningSigns:
      return PdfColors.lightGreen800;
    case Verdict.cannotDetermine:
      return PdfColors.amber800;
  }
}
String _two(int n) => n.toString().padLeft(2, '0');

/// Builds the report on the device. Nothing is uploaded.
Future<Uint8List> buildReportPdf(ScanResult r) async {
  final doc = pw.Document();

  pw.MemoryImage? preview;
  try {
    preview = pw.MemoryImage(r.bytes);
  } catch (_) {
    preview = null; // PDFs and unsupported formats have no preview
  }

  final hash = sha256.convert(r.bytes).toString();
  final now = DateTime.now();
  final stamp =
      '${now.year}/${_two(now.month)}/${_two(now.day)} ${_two(now.hour)}:${_two(now.minute)}';

  pw.Widget signalRow(Signal s) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            s.name,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.Text(s.reason, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text(
          'SachLens Authenticity Report',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Created on $stamp', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 16),
        pw.Text('File: ${r.fileName}', style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(
          'SHA 256 fingerprint: $hash',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 12),
        if (preview != null)
          pw.Center(
            child: pw.Image(preview, height: 200, fit: pw.BoxFit.contain),
          ),
        pw.SizedBox(height: 16),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _verdictColor(r.verdict), width: 2),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'Verdict: ${_verdictLabel(r.verdict)}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _verdictColor(r.verdict),
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Evidence',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...r.signals.map(signalRow),
        pw.SizedBox(height: 12),
        pw.Text(
          'SachLens is a decision aid. A clean result does not prove a file is genuine, '
              'and a warning does not prove it is fake. When in doubt, confirm with the issuer. '
              'This report was created on the device and the file was never uploaded.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ),
  );

  return doc.save();
}

Future<void> shareReport(ScanResult r) async {
  final bytes = await buildReportPdf(r);
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: 'SachLens_report.pdf',
        ),
      ],
      text: 'SachLens authenticity report',
    ),
  );
}