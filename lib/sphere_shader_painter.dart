import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// A CustomPainter that uses a fragment shader for GPU-accelerated sphere rendering.
///
/// This provides significantly better performance compared to CPU-based pixel
/// manipulation, especially when zoomed in or with day/night cycle enabled.
class SphereShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;

  /// Texture bound to sampler 0. Rebound on every paint, see [paint].
  final ui.Image daySurface;

  /// Texture bound to sampler 1; the day surface is used when null.
  final ui.Image? nightSurface;
  final double radius;
  final Offset center;
  final double rotationX;
  final double rotationZ;
  final double sunLongitude;
  final double sunLatitude;
  final double blendFactor;
  final bool isDayNightEnabled;
  final bool isSimulatedMode;
  final Color nightColor;
  final double nightIntensity;
  final bool lightingEnabled;
  final double lightAngle;
  final double lightIntensity;
  final double ambientLight;
  final void Function()? onPaintError;

  SphereShaderPainter({
    required this.shader,
    required this.daySurface,
    this.nightSurface,
    required this.radius,
    required this.center,
    required this.rotationX,
    required this.rotationZ,
    this.sunLongitude = 0.0,
    this.sunLatitude = 0.0,
    this.blendFactor = 0.3,
    this.isDayNightEnabled = false,
    this.isSimulatedMode = false,
    this.nightColor = const Color.fromARGB(255, 25, 38, 64),
    this.nightIntensity = 0.15,
    this.lightingEnabled = true,
    this.lightAngle = -0.785,
    this.lightIntensity = 0.3,
    this.ambientLight = 0.7,
    this.onPaintError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // Guard against invalid values that could cause shader issues
      if (radius <= 0 || !radius.isFinite) {
        onPaintError?.call();
        return;
      }
      if (!size.width.isFinite || !size.height.isFinite) {
        onPaintError?.call();
        return;
      }
      if (size.width <= 0 || size.height <= 0) {
        onPaintError?.call();
        return;
      }

      // Guard against invalid rotation values
      if (!rotationX.isFinite || !rotationZ.isFinite) {
        onPaintError?.call();
        return;
      }

      // Rebind the textures on every paint. With the CanvasKit web renderer,
      // FragmentShader.setImageSampler keeps only the raw child shader, while
      // the ImageShader that owns it is garbage-collected and deletes it.
      // Once that happens, any repaint with new uniforms (e.g. rotation)
      // draws without the texture. Rebinding right before drawing keeps the
      // samplers valid; it is cheap on every renderer.
      bindSphereTextures(shader, daySurface, nightSurface);

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

      // uDayNightMode (0.0 = textureSwap, 1.0 = simulated)
      shader.setFloat(idx++, isSimulatedMode ? 1.0 : 0.0);

      // uNightColorR, uNightColorG, uNightColorB (normalized 0-1)
      shader.setFloat(idx++, nightColor.r);
      shader.setFloat(idx++, nightColor.g);
      shader.setFloat(idx++, nightColor.b);

      // uNightIntensity
      shader.setFloat(idx++, nightIntensity);

      // uLightEnabled
      shader.setFloat(idx++, lightingEnabled ? 1.0 : 0.0);

      // uLightAngle (in radians)
      shader.setFloat(idx++, lightAngle);

      // uLightIntensity
      shader.setFloat(idx++, lightIntensity);

      // uAmbientLight
      shader.setFloat(idx++, ambientLight);

      // Draw using the shader with proper alpha blending for anti-aliased edges
      final paint = Paint()
        ..shader = shader
        ..isAntiAlias = true
        ..blendMode = BlendMode.srcOver;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } catch (e) {
      // On WebGL, shaders can fail during paint - log and notify
      debugPrint('SphereShaderPainter.paint error: $e');
      onPaintError?.call();
    }
  }

  @override
  bool shouldRepaint(SphereShaderPainter oldDelegate) {
    // Always repaint if shader changed (including texture updates)
    // or if any other values changed
    return oldDelegate.shader != shader ||
        oldDelegate.daySurface != daySurface ||
        oldDelegate.nightSurface != nightSurface ||
        oldDelegate.radius != radius ||
        oldDelegate.center != center ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationZ != rotationZ ||
        oldDelegate.sunLongitude != sunLongitude ||
        oldDelegate.sunLatitude != sunLatitude ||
        oldDelegate.blendFactor != blendFactor ||
        oldDelegate.isDayNightEnabled != isDayNightEnabled ||
        oldDelegate.isSimulatedMode != isSimulatedMode ||
        oldDelegate.nightColor != nightColor ||
        oldDelegate.nightIntensity != nightIntensity ||
        oldDelegate.lightingEnabled != lightingEnabled ||
        oldDelegate.lightAngle != lightAngle ||
        oldDelegate.lightIntensity != lightIntensity ||
        oldDelegate.ambientLight != ambientLight;
  }
}

/// Binds the day surface to sampler 0 and the night surface to sampler 1.
///
/// When there is no night surface the day surface is bound to both; the
/// shader only samples the night texture when the day/night cycle is enabled.
void bindSphereTextures(
    ui.FragmentShader shader, ui.Image daySurface, ui.Image? nightSurface) {
  shader.setImageSampler(0, daySurface);
  shader.setImageSampler(1, nightSurface ?? daySurface);
}

/// Helper class to manage shader loading and texture binding
class SphereShaderManager {
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

  /// Load the shader program from assets
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
            'packages/flutter_earth_globe/shaders/sphere.frag');
      } catch (e) {
        // Fall back to direct path (for when running within the library itself)
        _program = await ui.FragmentProgram.fromAsset('shaders/sphere.frag');
      }
      // Verify we can create a shader instance
      final testShader = _program!.fragmentShader();
      // Dispose of test shader by letting it go out of scope
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
          'Failed to load sphere shader (attempt $_loadAttempts/$_maxLoadAttempts): $e');
      return false;
    }
  }

  /// Create a shader instance with bound textures
  /// Returns a new shader instance each time to ensure fresh state
  ui.FragmentShader? createShaderWithTextures({
    required ui.Image daySurface,
    ui.Image? nightSurface,
  }) {
    if (_program == null) return null;

    try {
      final shader = _program!.fragmentShader();
      bindSphereTextures(shader, daySurface, nightSurface);
      return shader;
    } catch (e) {
      debugPrint('Failed to create sphere shader with textures: $e');
      return null;
    }
  }
}
