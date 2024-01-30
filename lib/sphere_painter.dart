import 'package:flutter/material.dart';

import 'sphere_image.dart';
import 'sphere_style.dart';

class SpherePainter extends CustomPainter {
  final SphereStyle style;
  SpherePainter({required this.sphereImage, required this.style});

  final SphereImage sphereImage;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect =
        Rect.fromCircle(center: sphereImage.offset, radius: sphereImage.radius);
    final circlePath = Path()..addOval(rect);

    // Blue shadow paint
    if (style.showShadow) {
      final shadowPaint = Paint()
        ..color = style.shadowColor // Shadow color
        ..maskFilter = MaskFilter.blur(
            style.shadowBlurStyle, style.shadowBlurSigma); // Shadow blur

      // Draw the shadow using shadowPaint
      canvas.drawPath(circlePath, shadowPaint);
    }

    // Clipping to the circle area
    final clipPath = Path.combine(
        PathOperation.intersect,
        Path()..addOval(rect),
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.clipPath(clipPath);

    // Your existing image drawing logic
    canvas.drawImage(
        sphereImage.image, sphereImage.offset - sphereImage.origin, paint);

    // Gradient paint logic
    if (style.showGradientOverlay) {
      paint.shader = style.gradientOverlay.createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
