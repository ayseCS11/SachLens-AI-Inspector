import 'dart:isolate';
import 'dart:typed_data';

import '../checks/ai_heuristics.dart';
import '../checks/document_rules.dart';
import '../checks/forensics_check.dart';
import '../checks/metadata_check.dart';
import '../checks/ocr_service.dart';
import '../checks/qr_check.dart';
import '../checks/qr_service.dart';
import '../checks/scam_rules.dart';
import 'ela_result.dart';
import 'scoring.dart';
import 'signal.dart';

typedef StatusCallback = void Function(String status);

/// The full checking pipeline, shared by the single scan and the batch scan.
/// Everything runs on the device.
Future<ScanResult> analyzeBytes(
    String name,
    Uint8List bytes, {
      StatusCallback? onStatus,
    }) async {
  onStatus?.call('Reading file details...');
  final metadataSignals = await Isolate.run(() => runMetadataChecks(bytes));
  final hasCameraData = metadataSignals.any((s) => s.name == 'Camera data');

  // Edit analysis only makes sense for JPEG photos and scans.
  ElaResult? ela;
  if (detectKind(bytes) == FileKind.jpeg) {
    onStatus?.call('Looking for edited areas...');
    try {
      ela = await Isolate.run(() => computeEla(bytes));
    } catch (_) {
      ela = null;
    }
  }
  final elaSig = elaSignal(ela);
  final aiHints = aiHeuristicSignals(bytes, hasCameraData: hasCameraData);

  onStatus?.call('Reading the text...');
  String text = '';
  try {
    text = await extractText(bytes);
  } catch (_) {
    // If reading fails, the other checks still give a result.
  }

  onStatus?.call('Looking for QR codes...');
  List<String> qrCodes = [];
  try {
    qrCodes = await readQrCodes(bytes);
  } catch (_) {
    // A failed QR read never stops the other checks.
  }

  onStatus?.call('Checking numbers, dates and wording...');
  final contentSignals = analyzeDocumentText(text);
  final scamSignals = analyzeScamLanguage(text);
  final qrSignals = analyzeQrCodes(qrCodes, text);

  final paperPhoto = hasCameraData && text.trim().length >= 40;

  return buildResult(
    fileName: name,
    bytes: bytes,
    signals: [
      ...metadataSignals,
      ...aiHints,
      if (elaSig != null) elaSig,
      ...contentSignals,
      ...scamSignals,
      ...qrSignals,
      if (paperPhoto)
        const Signal(
          name: 'Photo of paper',
          suspicion: 0.2,
          weight: 0.5,
          reason:
          'This looks like a camera photo of a paper document. SachLens can check that the contents are consistent, '
              'but it cannot judge the paper itself: seals, signatures, stamps, or print quality.',
        ),
    ],
    extractedText: text,
    ela: ela,
    qrCodes: qrCodes,
  );
}