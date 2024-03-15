import 'package:flutter/material.dart';

import 'sphere_image.dart';
import 'sphere_style.dart';

/// A custom painter for drawing a sphere with various styles.
///
/// The [SpherePainter] class extends the [CustomPainter] class and provides
/// methods for painting a sphere on a canvas. It supports features such as
/// shadow, clipping, image drawing, and gradient overlay.
class SpherePainter extends CustomPainter {
  final SphereStyle style;
  final SphereImage sphereImage;

  /// Creates a [SpherePainter] with the specified [sphereImage] and [style].
  ///
  /// The [sphereImage] represents the image of the sphere to be drawn, along
  /// with its position and size.
  /// The [style] defines the appearance of the sphere, including shadow and gradient overlay settings.
  ///
  /// Example usage:
  /// ```dart
  /// final painter = SpherePainter(
  ///   sphereImage: SphereImage(
  ///     image: myImage,
  ///     offset: Offset(100, 100),
  ///     radius: 50,
  ///     origin: Offset(25, 25),
  ///   ),
  ///   style: SphereStyle(
  ///     showShadow: true,
  ///     shadowColor: Colors.blue,
  ///     shadowBlurStyle: BlurStyle.normal,
  ///     shadowBlurSigma: 5.0,
  ///     showGradientOverlay: true,
  ///     gradientOverlay: LinearGradient(
  ///       colors: [Colors.red, Colors.yellow],
  ///       begin: Alignment.topLeft,
  ///       end: Alignment.bottomRight,
  ///     ),
  ///   ),
  /// );
  ///
  /// final customPaint = CustomPaint(
  ///   painter: painter,
  ///   size: Size(200, 200),
  /// );
  /// ```
  SpherePainter({required this.sphereImage, required this.style});

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
    // sphereImage.image.dispose();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
