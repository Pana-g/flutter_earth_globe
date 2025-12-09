import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' as material;

/// Enum to define the direction of the day/night cycle rotation
enum DayNightCycleDirection {
  /// Sun moves from east to west (left to right when viewing the globe)
  leftToRight,

  /// Sun moves from west to east (right to left when viewing the globe)
  rightToLeft,
}

/// Enum to define how the day/night cycle renders the night side
enum DayNightMode {
  /// Use a separate night texture (e.g., Earth with city lights)
  /// Requires a night surface texture to be loaded
  textureSwap,

  /// Simulate night by darkening the day texture
  /// Does not require a separate night texture
  simulated,
}

/// Paints the specified [title] on the [canvas] at the given [cartesian2D] position.
///
/// The [textStyle] parameter is optional and can be used to customize the text style.
/// The [size] parameter represents the size of the canvas.
void paintText(String title, material.TextStyle? textStyle, Offset cartesian2D,
    Size size, Canvas canvas) {
  final defaultTextPaint = Paint()
    ..color = material.Colors.blue.withAlpha(179)
    ..strokeWidth = 25
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  final defaultTextStyle = material.TextStyle(
    background: defaultTextPaint,
    color: material.Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  final textSpan = material.TextSpan(
    text: title,
    style: textStyle ?? defaultTextStyle,
  );

  final textPainter = material.TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  );

  textPainter.layout(
    minWidth: 0,
    maxWidth: size.width,
  );

  final offset = Offset(
      cartesian2D.dx - textPainter.width / 2,
      cartesian2D.dy -
          20 -
          textPainter.height / 2); // Position where the text will start
  textPainter.paint(canvas, offset);
}

/// Checks if the given [point] lies on the specified [path].
/// Returns true if the point is on the path, otherwise returns false.
bool isPointOnPath(Offset point, Path path, double pathWidth) {
  // Early exit: check if point is within the path's bounding box (expanded by stroke width)
  final bounds = path.getBounds();
  final strokeWidth = pathWidth.clamp(4, 100);

  if (point.dx < bounds.left - strokeWidth ||
      point.dx > bounds.right + strokeWidth ||
      point.dy < bounds.top - strokeWidth ||
      point.dy > bounds.bottom + strokeWidth) {
    return false;
  }

  PathMetric? pathMetric = path.computeMetrics().firstOrNull;
  if (pathMetric == null) return false;
  double totalLength = pathMetric.length;

  // Use distance squared for faster comparison (avoid sqrt)
  final strokeWidthSquared = strokeWidth * strokeWidth;

  // Use larger step for better performance
  final step = totalLength > 100 ? totalLength / 50 : 2.0;
  for (double d = 0.0; d <= totalLength; d += step) {
    Tangent? tangent = pathMetric.getTangentForOffset(d);
    if (tangent == null) continue;

    // Check if the point is within stroke the width of the path
    // Using distance squared instead of distance for performance
    final dx = tangent.position.dx - point.dx;
    final dy = tangent.position.dy - point.dy;
    if (dx * dx + dy * dy <= strokeWidthSquared) {
      return true;
    }
  }

  return false;
}

/// Converts the given [image] to a Uint32List.
///
/// Returns a Future that resolves to a Uint32List representing the image.
Future<Uint32List> convertImageToUint32List(Image image) async {
  final ByteData? byteData =
      await image.toByteData(format: ImageByteFormat.rawRgba);
  if (byteData == null) return Uint32List(0); // Handle this case as needed.

  Uint8List imgBytes = byteData.buffer.asUint8List();
  Uint32List uint32list = imgBytes.buffer.asUint32List();
  return uint32list;
}
