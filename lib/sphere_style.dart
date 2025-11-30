import 'package:flutter/material.dart';

/// Represents the style configuration for a sphere.
class SphereStyle {
  final Color shadowColor;
  final BlurStyle shadowBlurStyle;
  final double shadowBlurSigma;
  final bool showShadow;
  final Gradient gradientOverlay;
  final bool showGradientOverlay;

  /// The [SphereStyle] class defines various properties that can be used to customize the appearance of a sphere.
  ///
  /// The [shadowColor] parameter specifies the color of the shadow. The default value is `Color.fromARGB(185, 33, 149, 243)`.
  /// The [shadowBlurStyle] parameter specifies the style of the shadow blur. The default value is `BlurStyle.normal`.
  /// The [shadowBlurSigma] parameter specifies the sigma value of the shadow blur. The default value is `20`.
  /// The [showShadow] parameter specifies whether the shadow should be shown. The default value is `true`.
  /// The [gradientOverlay] parameter specifies the gradient overlay to be applied to the sphere. The default value is a radial gradient with transparent, white, and black colors.
  /// The [showGradientOverlay] parameter specifies whether the gradient overlay should be shown. The default value is `true`.
  ///
  /// Example usage:
  /// ```dart
  /// SphereStyle style = SphereStyle(
  ///   shadowColor: Colors.blue,
  ///   shadowBlurStyle: BlurStyle.inner,
  ///   shadowBlurSigma: 10,
  ///   showShadow: true,
  ///   showGradientOverlay: true,
  ///   gradientOverlay: RadialGradient(
  ///     center: Alignment.center,
  ///     colors: [
  ///       Colors.transparent,
  ///       Colors.white,
  ///       Colors.black,
  ///     ],
  ///     stops: [0.1, 0.5, 1.0],
  ///   ),
  /// );
  /// ```
  const SphereStyle({
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SphereStyle &&
        other.shadowColor == shadowColor &&
        other.shadowBlurStyle == shadowBlurStyle &&
        other.shadowBlurSigma == shadowBlurSigma &&
        other.showShadow == showShadow &&
        other.showGradientOverlay == showGradientOverlay;
  }

  @override
  int get hashCode => Object.hash(
        shadowColor,
        shadowBlurStyle,
        shadowBlurSigma,
        showShadow,
        showGradientOverlay,
      );
}
