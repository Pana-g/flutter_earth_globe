import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A CustomPainter that uses a fragment shader for GPU-accelerated sphere rendering.
///
/// This provides significantly better performance compared to CPU-based pixel
/// manipulation, especially when zoomed in or with day/night cycle enabled.
class SphereShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double radius;
  final Offset center;
  final double rotationX;
  final double rotationZ;
  final double sunLongitude;
  final double sunLatitude;
  final double blendFactor;
  final bool isDayNightEnabled;

  SphereShaderPainter({
    required this.shader,
    required this.radius,
    required this.center,
    required this.rotationX,
    required this.rotationZ,
    this.sunLongitude = 0.0,
    this.sunLatitude = 0.0,
    this.blendFactor = 0.3,
    this.isDayNightEnabled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set shader uniforms - must match the order in the shader
    int idx = 0;

    // uResolutionX, uResolutionY
    shader.setFloat(idx++, size.width);
    shader.setFloat(idx++, size.height);

    // uCenterX, uCenterY
    shader.setFloat(idx++, center.dx);
    shader.setFloat(idx++, center.dy);

    // uRadius
    shader.setFloat(idx++, radius);

    // uRotationX
    shader.setFloat(idx++, rotationX);

    // uRotationZ
    shader.setFloat(idx++, rotationZ);

    // uSunLongitude (convert from degrees to radians)
    shader.setFloat(idx++, sunLongitude * 3.14159265359 / 180.0);

    // uSunLatitude (convert from degrees to radians)
    shader.setFloat(idx++, sunLatitude * 3.14159265359 / 180.0);

    // uBlendFactor
    shader.setFloat(idx++, blendFactor);

    // uDayNightEnabled
    shader.setFloat(idx++, isDayNightEnabled ? 1.0 : 0.0);

    // Draw using the shader
    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(SphereShaderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.center != center ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationZ != rotationZ ||
        oldDelegate.sunLongitude != sunLongitude ||
        oldDelegate.sunLatitude != sunLatitude ||
        oldDelegate.blendFactor != blendFactor ||
        oldDelegate.isDayNightEnabled != isDayNightEnabled;
  }
}

/// Helper class to manage shader loading and texture binding
class SphereShaderManager {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  bool _isLoading = false;
  bool _loadFailed = false;
  String? _loadError;

  /// Whether the shader is ready to use
  bool get isReady => _shader != null;

  /// Whether shader loading failed
  bool get loadFailed => _loadFailed;

  /// Error message if loading failed
  String? get loadError => _loadError;

  /// Load the shader program from assets
  Future<bool> loadShader() async {
    if (_shader != null) return true;
    if (_isLoading) return false;
    if (_loadFailed) return false;

    _isLoading = true;
    try {
      // Try loading from package path first (for when library is used as dependency)
      try {
        _program = await ui.FragmentProgram.fromAsset(
            'packages/flutter_earth_globe/shaders/sphere.frag');
      } catch (e) {
        // Fall back to direct path (for when running within the library itself)
        _program = await ui.FragmentProgram.fromAsset('shaders/sphere.frag');
      }
      _shader = _program!.fragmentShader();
      _isLoading = false;
      return true;
    } catch (e) {
      _loadFailed = true;
      _loadError = e.toString();
      _isLoading = false;
      debugPrint('Failed to load sphere shader: $e');
      return false;
    }
  }

  /// Create a shader instance with bound textures
  ui.FragmentShader? createShaderWithTextures({
    required ui.Image daySurface,
    ui.Image? nightSurface,
  }) {
    if (_program == null) return null;

    final shader = _program!.fragmentShader();

    // Bind the day surface texture (sampler index 0)
    shader.setImageSampler(0, daySurface);

    // Bind the night surface texture (sampler index 1)
    // If night surface is not available, use day surface as a fallback
    // (the shader will only use this when day/night cycle is enabled)
    shader.setImageSampler(1, nightSurface ?? daySurface);

    return shader;
  }
}
