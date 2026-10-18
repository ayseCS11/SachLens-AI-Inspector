import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../core/ela_result.dart';

enum CompareLevel { identical, localChanges, majorChanges, different, error }

class CompareResult {
  final CompareLevel level;
  final double similarity; // 0.0 to 1.0, based on a visual fingerprint
  final double changedShare; // share of the page area that differs
  final ElaResult? diff; // heat grid, reused by the heat map overlay
  final String headline;
  final String detail;

  const CompareResult({
    required this.level,
    required this.similarity,
    required this.changedShare,
    required this.diff,
    required this.headline,
    required this.detail,
  });
}

const int _w = 800;
const int _cols = 24;

CompareResult _error(String message) => CompareResult(
  level: CompareLevel.error,
  similarity: 0,
  changedShare: 0,
  diff: null,
  headline: 'Could not compare',
  detail: message,
);

/// A small visual fingerprint (difference hash). Close to 1.0 means the two
/// images show the same picture.
double _fingerprintSimilarity(img.Image a, img.Image b) {
  final sa = img.copyResize(a,
      width: 9, height: 8, interpolation: img.Interpolation.average);
  final sb = img.copyResize(b,
      width: 9, height: 8, interpolation: img.Interpolation.average);
  var same = 0;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final bitA = sa.getPixel(x, y).luminance < sa.getPixel(x + 1, y).luminance;
      final bitB = sb.getPixel(x, y).luminance < sb.getPixel(x + 1, y).luminance;
      if (bitA == bitB) same++;
    }
  }
  return same / 64;
}

/// Compares an original and a suspect image and finds where they differ.
/// Pure Dart, safe to run inside an isolate.
CompareResult compareImages(Uint8List originalBytes, Uint8List suspectBytes) {
  try {
    final a0 = img.decodeImage(originalBytes);
    final b0 = img.decodeImage(suspectBytes);
    if (a0 == null || b0 == null) {
      return _error('One of the files could not be read as an image.');
    }

    final a1 = img.bakeOrientation(a0);
    final b1 = img.bakeOrientation(b0);
    final ratioA = a1.width / a1.height;
    final ratioB = b1.width / b1.height;
    final ratioGap = (ratioA - ratioB).abs() / ratioA;

    final h = math.max(1, (_w / ratioA).round());
    final a = img.gaussianBlur(
      img.grayscale(img.copyResize(a1, width: _w, height: h)),
      radius: 2,
    );
    final b = img.gaussianBlur(
      img.grayscale(img.copyResize(b1, width: _w, height: h)),
      radius: 2,
    );

    final similarity = _fingerprintSimilarity(a, b);

    final cellW = _w / _cols;
    final rows = math.max(1, (h / cellW).round());
    final cellH = h / rows;

    final sums = List<double>.filled(_cols * rows, 0);
    final counts = List<int>.filled(_cols * rows, 0);

    for (var y = 0; y < h; y += 2) {
      final r = math.min(rows - 1, (y / cellH).floor());
      for (var x = 0; x < _w; x += 2) {
        final c = math.min(_cols - 1, (x / cellW).floor());
        final d = (a.getPixel(x, y).luminance - b.getPixel(x, y).luminance).abs();
        final idx = r * _cols + c;
        sums[idx] += d.toDouble();
        counts[idx]++;
      }
    }

    var changed = 0;
    final heat = List<double>.generate(sums.length, (i) {
      final mean = counts[i] == 0 ? 0.0 : sums[i] / counts[i];
      if (mean >= 18) changed++;
      return (mean / 60).clamp(0.0, 1.0).toDouble();
    });

    final share = changed / heat.length;
    final diff = ElaResult(
      cols: _cols,
      rows: rows,
      imageWidth: _w,
      imageHeight: h,
      heat: heat,
      strongShare: share,
    );

    final pct = (share * 100).toStringAsFixed(1);
    final note = ratioGap > 0.08
        ? ' The two images have different proportions, so one may be cropped or resized, which can add extra differences.'
        : '';

    if (similarity < 0.55) {
      return CompareResult(
        level: CompareLevel.different,
        similarity: similarity,
        changedShare: share,
        diff: diff,
        headline: 'These look like different images',
        detail:
        'The two files do not show the same page or picture, so a detailed comparison is not meaningful.$note',
      );
    }

    if (share < 0.005) {
      return CompareResult(
        level: CompareLevel.identical,
        similarity: similarity,
        changedShare: share,
        diff: diff,
        headline: 'No visible differences',
        detail:
        'The two images look the same. Hidden changes, such as metadata, are not visible here.$note',
      );
    }

    if (share <= 0.2) {
      return CompareResult(
        level: CompareLevel.localChanges,
        similarity: similarity,
        changedShare: share,
        diff: diff,
        headline: 'Local differences found',
        detail:
        'About $pct percent of the page differs. Check the red areas on the suspect copy. '
            'Differences can also come from lighting, shadows, or a different photo angle.$note',
      );
    }

    return CompareResult(
      level: CompareLevel.majorChanges,
      similarity: similarity,
      changedShare: share,
      diff: diff,
      headline: 'Large differences found',
      detail:
      'About $pct percent of the page differs. This is either a heavily changed copy or a different photo of the same page.$note',
    );
  } catch (_) {
    return _error('Something went wrong while comparing these images.');
  }
}