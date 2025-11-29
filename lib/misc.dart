import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' as material;

/// Paints the specified [title] on the [canvas] at the given [cartesian2D] position.
///
/// The [textStyle] parameter is optional and can be used to customize the text style.
/// The [size] parameter represents the size of the canvas.
void paintText(String title, material.TextStyle? textStyle, Offset cartesian2D,
    Size size, Canvas canvas) {
  final defaultTextPaint = Paint()
    ..color = material.Colors.blue.withOpacity(0.7)
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
  PathMetric? pathMetric = path.computeMetrics().firstOrNull;
  if (pathMetric == null) return false;
  double totalLength = pathMetric.length;
  double strokeWidth = pathWidth.clamp(4, 100);

  // Use larger step for better performance
  final step = totalLength > 100 ? totalLength / 50 : 2.0;
  for (double d = 0.0; d <= totalLength; d += step) {
    Tangent? tangent = pathMetric.getTangentForOffset(d);
    if (tangent == null) continue;

    // Check if the point is within stroke the width of the path
    if ((tangent.position - point).distance <= strokeWidth) {
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
