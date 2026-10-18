import 'dart:typed_data';

import 'ela_result.dart';
import 'signal.dart';

enum Verdict { likelyAuthentic, suspicious, cannotDetermine, noWarningSigns }

class ScanResult {
  final Verdict verdict;
  final double score;
  final double risk; // 0.0 to 1.0, a rough guide for the risk meter
  final List<Signal> signals; // sorted, most important first
  final String fileName;
  final Uint8List bytes;
  final String extractedText;
  final ElaResult? ela;
  final List<String> qrCodes;

  const ScanResult({
    required this.verdict,
    required this.score,
    required this.risk,
    required this.signals,
    required this.fileName,
    required this.bytes,
    this.extractedText = '',
    this.ela,
    this.qrCodes = const [],
  });

  int get riskPercent => (risk * 100).round().clamp(0, 100);
  /// True when the text looks like a social media post.
  bool get isSocialPost =>
      signals.any((s) => s.role == SignalRole.socialMedia);
}

/// Combines all signals into one honest verdict.
///
/// 1. One strong, heavy signal is enough for "Suspicious".
/// 2. Several medium signals together are also "Suspicious", because they
///    support each other.
/// 3. The good verdict needs several signals AND at least one positive
///    piece of evidence, never just the absence of problems.
/// 4. Camera details count as positive evidence only for plain photos.
/// 5. Everything else is "Cannot determine".
ScanResult buildResult({
  required String fileName,
  required Uint8List bytes,
  required List<Signal> signals,
  String extractedText = '',
  ElaResult? ela,
  List<String> qrCodes = const [],
}) {
  double totalWeight = 0;
  double weighted = 0;
  for (final s in signals) {
    totalWeight += s.weight;
    weighted += s.suspicion * s.weight;
  }
  final score = totalWeight == 0 ? 0.0 : weighted / totalWeight;

  // Evidence that adds up: every worrying signal reduces the chance that the
  // file is fine.
  var safe = 1.0;
  for (final s in signals) {
    if (s.suspicion >= 0.4 && s.weight >= 1.0) {
      final w = s.weight >= 3 ? 1.0 : s.weight / 3;
      safe *= (1 - s.suspicion * w * 0.9);
    }
  }
  final combined = 1 - safe;
  final risk = score > combined ? score : combined;

  final isPlainPhoto = extractedText.trim().length < 40;

  final hasStrongSignal =
  signals.any((s) => s.suspicion >= 0.8 && s.weight >= 3);

  final hasPositiveEvidence = signals.any((s) =>
  s.suspicion <= 0.1 &&
      s.weight >= 2 &&
      (s.name != 'Camera data' || isPlainPhoto));

  Verdict verdict;
  if (hasStrongSignal || score > 0.6 || combined >= 0.65) {
    verdict = Verdict.suspicious;
  } else if (score < 0.2 && signals.length >= 3 && hasPositiveEvidence) {
    verdict = Verdict.likelyAuthentic;
  } else {
    verdict = Verdict.cannotDetermine;
  }

  final sorted = List<Signal>.from(signals)
    ..sort((a, b) =>
        (b.suspicion * b.weight).compareTo(a.suspicion * a.weight));

  return ScanResult(
    verdict: verdict,
    score: score,
    risk: risk,
    signals: sorted,
    fileName: fileName,
    bytes: bytes,
    extractedText: extractedText,
    ela: ela,
    qrCodes: qrCodes,
  );
}