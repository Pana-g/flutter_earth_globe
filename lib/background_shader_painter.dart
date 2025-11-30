import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A CustomPainter that uses a fragment shader for GPU-accelerated starry background rendering.
///
/// This provides better performance compared to CPU-based tiling, especially
/// when the background is following sphere rotation.
class BackgroundShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double offsetX;
  final double offsetY;
  final double texWidth;
  final double texHeight;
  final void Function()? onPaintError;

  BackgroundShaderPainter({
    required this.shader,
    required this.offsetX,
    required this.offsetY,
    required this.texWidth,
    required this.texHeight,
    this.onPaintError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // Guard against invalid values that could cause shader issues
      if (!size.width.isFinite || !size.height.isFinite) {
        onPaintError?.call();
        return;
      }
      if (size.width <= 0 || size.height <= 0) {
        onPaintError?.call();
        return;
      }
      if (texWidth <= 0 || texHeight <= 0) {
        onPaintError?.call();
        return;
      }

      // Set shader uniforms - must match the order in the shader
      int idx = 0;

      // uResolutionX, uResolutionY
      shader.setFloat(idx++, size.width);
      shader.setFloat(idx++, size.height);

      // uOffsetX, uOffsetY
      shader.setFloat(idx++, offsetX.isFinite ? offsetX : 0.0);
      shader.setFloat(idx++, offsetY.isFinite ? offsetY : 0.0);

      // uTexWidth, uTexHeight
      shader.setFloat(idx++, texWidth);
      shader.setFloat(idx++, texHeight);

      // Draw using the shader
      final paint = Paint()..shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } catch (e) {
      // On WebGL, shaders can fail during paint - log and notify
      debugPrint('BackgroundShaderPainter.paint error: $e');
      onPaintError?.call();
    }
  }

  @override
  bool shouldRepaint(BackgroundShaderPainter oldDelegate) {
    // Always repaint if any values changed - don't compare shader instances
    // as they may be recreated frequently on web
    return oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY ||
        oldDelegate.texWidth != texWidth ||
        oldDelegate.texHeight != texHeight;
  }
}

/// Helper class to manage background shader loading and texture binding
class BackgroundShaderManager {
  ui.FragmentProgram? _program;
  bool _isLoading = false;
  bool _loadFailed = false;
  String? _loadError;
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  /// Whether the shader program is loaded (ready to create shader instances)
  bool get isReady => _program != null;

  /// Whether shader loading failed permanently (after max retries)
  bool get loadFailed => _loadFailed && _loadAttempts >= _maxLoadAttempts;

  /// Error message if loading failed
  String? get loadError => _loadError;

  /// Reset the failure state to allow retrying
  void resetLoadState() {
    if (_loadAttempts < _maxLoadAttempts) {
      _loadFailed = false;
      _loadError = null;
    }
  }

  /// Force a complete reload of the shader program
  /// This is useful for web platform where WebGL context can be lost
  void forceReload() {
    _program = null;
    _isLoading = false;
    _loadFailed = false;
    _loadError = null;
    _loadAttempts = 0;
  }

  /// Load the background shader
  Future<bool> loadShader() async {
    if (_program != null) return true;
    if (_isLoading) return false;
    if (_loadFailed && _loadAttempts >= _maxLoadAttempts) return false;

    _isLoading = true;
    _loadAttempts++;

    try {
      // Try loading from package path first (for when library is used as dependency)
      try {
        _program = await ui.FragmentProgram.fromAsset(
            'packages/flutter_earth_globe/shaders/background.frag');
      } catch (e) {
        // Fall back to direct path (for when running within the library itself)
        _program =
            await ui.FragmentProgram.fromAsset('shaders/background.frag');
      }
      // Verify we can create a shader instance
      final testShader = _program!.fragmentShader();
      // ignore: unnecessary_null_comparison
      if (testShader == null) throw Exception('Failed to create test shader');
      _isLoading = false;
      _loadFailed = false;
      return true;
    } catch (e) {
      _loadFailed = true;
      _loadError = e.toString();
      _isLoading = false;
      _program = null;
      debugPrint(
          'Failed to load background shader (attempt $_loadAttempts/$_maxLoadAttempts): $e');
      return false;
    }
  }

  /// Create a shader with the star texture bound
  /// Returns a new shader instance each time to ensure fresh state
  ui.FragmentShader? createShaderWithTexture({required ui.Image starTexture}) {
    if (_program == null) return null;

    try {
      final shader = _program!.fragmentShader();

      // Bind the star texture sampler (index 0 after float uniforms)
      shader.setImageSampler(0, starTexture);

      return shader;
    } catch (e) {
      debugPrint('Failed to create background shader with texture: $e');
      return null;
    }
  }
}
