import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A custom painter that draws a starry background using a star texture image.
class StarryBackgroundPainter extends CustomPainter {
  final ui.Image starTexture;
  final double rotationZ, rotationY;

  /// The [StarryBackgroundPainter] takes in a star texture image, along with rotation
  /// values for the X and Y axes. It then paints the star texture repeatedly across
  /// the canvas, creating a starry background effect.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final starTexture = await loadImage('assets/star_texture.png');
  ///
  /// final painter = StarryBackgroundPainter(
  ///   starTexture: starTexture,
  ///   rotationX: 0.0,
  ///   rotationY: 0.0,
  /// );
  ///
  /// final customPaint = CustomPaint(
  ///   painter: painter,
  /// );
  /// ```
  StarryBackgroundPainter({
    required this.starTexture,
    required this.rotationZ,
    required this.rotationY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    double offsetX = rotationZ % starTexture.width;
    double offsetY = rotationY % starTexture.height;

    for (double i = offsetX - starTexture.width;
        i < size.width;
        i += starTexture.width - 1) {
      for (double j = offsetY - starTexture.height;
          j < size.height;
          j += starTexture.height - 1) {
        canvas.drawImage(starTexture, Offset(i, j), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarryBackgroundPainter oldDelegate) =>
      rotationZ != oldDelegate.rotationZ || rotationY != oldDelegate.rotationY;
}
