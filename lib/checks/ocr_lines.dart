import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// One line of text and where it sits in the picture.
class OcrLine {
  final String text;
  final Rect box;

  const OcrLine(this.text, this.box);
}

/// Several pieces of text that sit on the same row, joined left to right.
/// A label such as "Payment Date:" and its value are often read as two
/// separate pieces, so the checks work on rows, not on single pieces.
class OcrRow {
  final String text;
  final List<int> sources; // indexes into the original line list
  final Rect box;

  const OcrRow(this.text, this.sources, this.box);
}

List<OcrLine> linesFrom(RecognizedText result) {
  final lines = <OcrLine>[];
  for (final block in result.blocks) {
    for (final line in block.lines) {
      final t = line.text.trim();
      if (t.isNotEmpty) lines.add(OcrLine(t, line.boundingBox));
    }
  }
  return lines;
}

/// Joins pieces of text that share a row. Pieces without a usable size are
/// left alone.
List<OcrRow> mergeRows(List<OcrLine> lines) {
  final order = List<int>.generate(lines.length, (i) => i)
    ..sort((a, b) =>
        lines[a].box.center.dy.compareTo(lines[b].box.center.dy));

  final groups = <List<int>>[];
  final tops = <double>[];
  final bottoms = <double>[];

  for (final i in order) {
    final b = lines[i].box;
    final h = b.height;
    var placed = false;

    if (groups.isNotEmpty && h > 0) {
      final last = groups.length - 1;
      final rowH = bottoms[last] - tops[last];
      final overlap =
          math.min(b.bottom, bottoms[last]) - math.max(b.top, tops[last]);
      final minH = math.min(h, rowH);
      final maxH = math.max(h, rowH);

      if (rowH > 0 && minH > 0 && overlap >= 0.5 * minH && maxH <= 2.5 * minH) {
        groups[last].add(i);
        tops[last] = math.min(tops[last], b.top);
        bottoms[last] = math.max(bottoms[last], b.bottom);
        placed = true;
      }
    }

    if (!placed) {
      groups.add([i]);
      tops.add(b.top);
      bottoms.add(b.bottom);
    }
  }

  return groups.map((g) {
    g.sort((a, b) => lines[a].box.left.compareTo(lines[b].box.left));
    var box = lines[g.first].box;
    for (final i in g.skip(1)) {
      box = box.expandToInclude(lines[i].box);
    }
    return OcrRow(g.map((i) => lines[i].text).join(' '), g, box);
  }).toList();
}

/// Reads text lines with their positions from a JPEG.
/// The temporary file is always deleted. Runs on the device.
Future<List<OcrLine>> extractLines(Uint8List jpegBytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/sachlens_poster.jpg');
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    await file.writeAsBytes(jpegBytes, flush: true);
    final result =
    await recognizer.processImage(InputImage.fromFilePath(file.path));
    return linesFrom(result);
  } finally {
    await recognizer.close();
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}