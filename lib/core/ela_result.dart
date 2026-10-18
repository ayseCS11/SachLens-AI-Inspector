/// Result of the edit analysis: a grid of "heat" values over the image.
class ElaResult {
  final int cols;
  final int rows;
  final int imageWidth;
  final int imageHeight;

  /// One value per grid cell, row by row, from 0.0 (normal) to 1.0 (stands out).
  final List<double> heat;

  /// Share of cells that clearly stand out, from 0.0 to 1.0.
  final double strongShare;

  const ElaResult({
    required this.cols,
    required this.rows,
    required this.imageWidth,
    required this.imageHeight,
    required this.heat,
    required this.strongShare,
  });
}