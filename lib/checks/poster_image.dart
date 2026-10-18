import 'dart:typed_data';

import 'package:image/image.dart' as img;

class PosterImage {
  final Uint8List bytes;
  final int width;
  final int height;

  const PosterImage(this.bytes, this.width, this.height);
}

const int _maxSide = 2000;

/// Rotates the photo upright and limits its size. The same bytes are used for
/// text reading and for display, so highlight boxes always line up.
/// Pure Dart, safe to run inside an isolate.
PosterImage? preparePosterImage(Uint8List input) {
  try {
    final decoded = img.decodeImage(input);
    if (decoded == null) return null;

    var image = img.bakeOrientation(decoded);
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > _maxSide) {
      image = image.width >= image.height
          ? img.copyResize(image, width: _maxSide)
          : img.copyResize(image, height: _maxSide);
    }

    final out = Uint8List.fromList(img.encodeJpg(image, quality: 92));
    return PosterImage(out, image.width, image.height);
  } catch (_) {
    return null;
  }
}