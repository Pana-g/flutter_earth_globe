import 'package:flutter/material.dart';

class SphereStyle {
  final Color shadowColor;
  final BlurStyle shadowBlurStyle;
  final double shadowBlurSigma;
  final bool showShadow;
  final Gradient gradientOverlay;
  final bool showGradientOverlay;

  SphereStyle({
    this.shadowColor = const Color.fromARGB(185, 33, 149, 243),
    this.shadowBlurStyle = BlurStyle.normal,
    this.shadowBlurSigma = 20,
    this.showShadow = true,
    this.showGradientOverlay = true,
    this.gradientOverlay = const RadialGradient(
      center: Alignment.center,
      colors: [
        Colors.transparent,
        Color.fromARGB(5, 255, 255, 255),
        Color.fromARGB(21, 255, 255, 255)
      ],
      stops: [0.1, 0.85, 1.0],
    ),
  });
}
