import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class StarryBackgroundPainter extends CustomPainter {
  final ui.Image starTexture;
  final double rotationX, rotationY;

  StarryBackgroundPainter(
      {required this.starTexture,
      required this.rotationX,
      required this.rotationY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    double offsetX = rotationX % starTexture.width;
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
      rotationX != oldDelegate.rotationX || rotationY != oldDelegate.rotationY;
}
