import 'dart:typed_data';

import '../core/signal.dart';

class _Size {
  final int w;
  final int h;
  const _Size(this.w, this.h);
}

/// Reads the pixel size straight from the file header. No decoding needed.
_Size? _readImageSize(Uint8List b) {
  // PNG: width and height sit at bytes 16 to 23.
  if (b.length > 24 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    final w = (b[16] << 24) | (b[17] << 16) | (b[18] << 8) | b[19];
    final h = (b[20] << 24) | (b[21] << 16) | (b[22] << 8) | b[23];
    return _Size(w, h);
  }

  // JPEG: find the start of frame marker.
  if (b.length > 4 && b[0] == 0xFF && b[1] == 0xD8) {
    var i = 2;
    while (i + 9 < b.length) {
      if (b[i] != 0xFF) {
        i++;
        continue;
      }
      final marker = b[i + 1];
      if (marker == 0xFF) {
        i++;
        continue;
      }
      if (marker == 0xD8 ||
          marker == 0x01 ||
          (marker >= 0xD0 && marker <= 0xD7)) {
        i += 2;
        continue;
      }
      final len = (b[i + 2] << 8) | b[i + 3];
      final isStartOfFrame = marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isStartOfFrame) {
        final h = (b[i + 5] << 8) | b[i + 6];
        final w = (b[i + 7] << 8) | b[i + 8];
        return _Size(w, h);
      }
      i += 2 + len;
    }
  }
  return null;
}

/// Exact sizes that popular AI image tools often produce.
/// Both orientations are checked.
const Set<String> _aiSizes = {
  '512x512',
  '768x768',
  '1024x1024',
  '1536x1536',
  '2048x2048',
  '1024x1792',
  '1536x1024',
  '1152x896',
  '1216x832',
  '1344x768',
  '1536x640',
  '1456x816',
};

/// Weak hints about AI images. They never decide anything alone.
List<Signal> aiHeuristicSignals(
    Uint8List bytes, {
      required bool hasCameraData,
    }) {
  if (hasCameraData) return const [];

  final size = _readImageSize(bytes);
  if (size == null) return const [];

  final key = '${size.w}x${size.h}';
  final flipped = '${size.h}x${size.w}';
  if (_aiSizes.contains(key) || _aiSizes.contains(flipped)) {
    return [
      Signal(
        name: 'Typical AI image size',
        suspicion: 0.55,
        weight: 1.5,
        reason:
        'The picture is exactly ${size.w} by ${size.h} pixels and has no camera data. Many AI image tools produce this exact size. '
            'Screenshots and downloaded pictures can have it too, so this is only a weak hint.',
      ),
    ];
  }
  return const [];
}