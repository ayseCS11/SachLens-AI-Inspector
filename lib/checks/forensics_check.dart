
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:sachlens/core/signal.dart';

import '../core/ela_result.dart';

const int _maxSide = 1600; // Keeps the analysis fast on phones
const int _cols = 24;

/// Error level analysis. Re-saves the image as JPEG at a fixed quality and
/// measures how much each area changes. Pasted or edited areas often react
/// differently from the rest. This is a hint, never proof.
///
/// Pure Dart, safe to run inside an isolate.
ElaResult? computeEla(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    var src = img.bakeOrientation(decoded);

    if (src.width > _maxSide) {
      src = img.copyResize(src, width: _maxSide);
    }

    final resaved = img.decodeJpg(img.encodeJpg(src, quality: 90));
    if (resaved == null) return null;

    final w = src.width;
    final h = src.height;
    final cellW = w / _cols;
    final rows = math.max(1, (h / cellW).round());
    final cellH = h / rows;

    final sums = List<double>.filled(_cols * rows, 0);
    final counts = List<int>.filled(_cols * rows, 0);

    // Every second pixel is enough and is four times faster.
    for (var y = 0; y < h; y += 2) {
      final r = math.min(rows - 1, (y / cellH).floor());

      for (var x = 0; x < w; x += 2) {
        final c = math.min(_cols - 1, (x / cellW).floor());

        final a = src.getPixel(x, y);
        final b = resaved.getPixel(x, y);

        final d = (a.r - b.r).abs() +
            (a.g - b.g).abs() +
            (a.b - b.b).abs();

        final idx = r * _cols + c;
        sums[idx] += d.toDouble();
        counts[idx]++;
      }
    }

    final means = List<double>.generate(
      sums.length,
          (i) => counts[i] == 0 ? 0.0 : sums[i] / counts[i],
    );

    final mean = means.reduce((a, b) => a + b) / means.length;

    final variance = means
        .map((m) => (m - mean) * (m - mean))
        .reduce((a, b) => a + b) /
        means.length;

    final std = math.sqrt(variance);

    // Almost flat error levels: nothing meaningful to show.
    if (std < 0.5) {
      return ElaResult(
        cols: _cols,
        rows: rows,
        imageWidth: w,
        imageHeight: h,
        heat: List<double>.filled(means.length, 0.0),
        strongShare: 0,
      );
    }

    var strong = 0;

    final heat = List<double>.generate(means.length, (i) {
      final z = (means[i] - mean) / (std + 0.0001);

      if (z >= 2.5 && means[i] - mean > 1.5) {
        strong++;
      }

      return (z / 4).clamp(0.0, 1.0).toDouble();
    });

    return ElaResult(
      cols: _cols,
      rows: rows,
      imageWidth: w,
      imageHeight: h,
      heat: heat,
      strongShare: strong / means.length,
    );
  } catch (_) {
    return null;
  }
}

Signal? elaSignal(ElaResult? r) {
  if (r == null) return null;

  if (r.strongShare == 0) {
    return const Signal(
      name: 'Edit analysis',
      suspicion: 0.15,
      weight: 1,
      reason:
      'No areas stand out in the edit analysis. This method can miss careful edits.',
    );
  }

  if (r.strongShare <= 0.03) {
    return const Signal(
      name: 'Edit analysis',
      suspicion: 0.25,
      weight: 0.7,
      reason:
      'A few small areas stand out. This is usually normal texture and sharp edges, not editing.',
    );
  }

  if (r.strongShare <= 0.2) {
    final pct = (r.strongShare * 100).toStringAsFixed(1);

    return Signal(
      name: 'Edit analysis',
      suspicion: 0.55,
      weight: 1.5,
      reason:
      '$pct percent of the image reacts differently when re-saved. These areas may be edited or pasted, '
          'or may just be detailed texture. Turn on the heat map to see where.',
    );
  }

  return const Signal(
    name: 'Edit analysis',
    suspicion: 0.3,
    weight: 0.5,
    reason:
    'Many areas differ, which usually comes from heavy compression and not from local editing.',
  );
}
