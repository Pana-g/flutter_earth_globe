import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A custom painter that draws a starry background using a star texture image.
class StarryBackgroundPainter extends CustomPainter {
  final ui.Image starTexture;
  final double rotationZ, rotationY;
  final double zoom;

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
  ///   zoom: 1.0,
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
    this.zoom = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Apply zoom by scaling around the center
    final effectiveZoom = zoom > 0 ? zoom : 1.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Save the canvas state before transformation
    canvas.save();

    // Translate to center, scale, then translate back
    canvas.translate(centerX, centerY);
    canvas.scale(effectiveZoom);
    canvas.translate(-centerX, -centerY);

    // Calculate offset for rotation (scaled to account for zoom)
    double offsetX = (rotationZ / effectiveZoom) % starTexture.width;
    double offsetY = (rotationY / effectiveZoom) % starTexture.height;

    // Calculate visible area after zoom (we need to draw more tiles when zoomed out)
    final visibleWidth = size.width / effectiveZoom;
    final visibleHeight = size.height / effectiveZoom;

    for (double i = offsetX - starTexture.width;
        i < visibleWidth + starTexture.width;
        i += starTexture.width - 1) {
      for (double j = offsetY - starTexture.height;
          j < visibleHeight + starTexture.height;
          j += starTexture.height - 1) {
        canvas.drawImage(starTexture, Offset(i, j), paint);
      }
    }

    // Restore the canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StarryBackgroundPainter oldDelegate) =>
      rotationZ != oldDelegate.rotationZ ||
      rotationY != oldDelegate.rotationY ||
      zoom != oldDelegate.zoom;
}
