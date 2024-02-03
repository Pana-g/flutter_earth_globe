import 'dart:ui';

import 'package:flutter/material.dart';

/// Paints the specified [title] on the [canvas] at the given [cartesian2D] position.
///
/// The [textStyle] parameter is optional and can be used to customize the text style.
/// The [size] parameter represents the size of the canvas.
void paintText(String title, TextStyle? textStyle, Offset cartesian2D,
    Size size, Canvas canvas) {
  final defaultTextPaint = Paint()
    ..color = Colors.blue.withOpacity(0.7)
    ..strokeWidth = 25
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  final defaultTextStyle = TextStyle(
    background: defaultTextPaint,
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  final textSpan = TextSpan(
    text: title,
    style: textStyle ?? defaultTextStyle,
  );

  final textPainter = TextPainter(
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
bool isPointOnPath(Path path, Offset point) {
  PathMetric? pathMetric = path.computeMetrics().firstOrNull;
  if (pathMetric == null) return false;
  double totalLength = pathMetric.length;

  for (double d = 0.0; d <= totalLength; d += 1) {
    Tangent? tangent = pathMetric.getTangentForOffset(d);
    if (tangent == null) continue;
    if ((tangent.position - point).distance < 1) {
      return true;
    }
  }

  return false;
}
