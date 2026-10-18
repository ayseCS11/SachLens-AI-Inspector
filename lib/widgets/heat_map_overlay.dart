import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/ela_result.dart';

class HeatMapOverlay extends StatelessWidget {
  final Uint8List bytes;
  final ElaResult ela;

  const HeatMapOverlay({super.key, required this.bytes, required this.ela});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: ela.imageWidth / ela.imageHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.fill),
          CustomPaint(painter: _HeatPainter(ela)),
        ],
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  final ElaResult ela;

  _HeatPainter(this.ela);

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / ela.cols;
    final cellH = size.height / ela.rows;
    final paint = Paint();

    for (var r = 0; r < ela.rows; r++) {
      for (var c = 0; c < ela.cols; c++) {
        final v = ela.heat[r * ela.cols + c];
        if (v < 0.3) continue; // only show areas that stand out
        paint.color = Colors.red.withValues(alpha: 0.15 + v * 0.5);
        canvas.drawRect(
          Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatPainter oldDelegate) =>
      oldDelegate.ela != ela;
}