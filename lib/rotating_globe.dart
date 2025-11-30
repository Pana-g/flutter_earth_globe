import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_earth_globe/background_shader_painter.dart';
import 'package:flutter_earth_globe/gpu_foreground_painter.dart';
import 'package:flutter_earth_globe/misc.dart';
import 'package:flutter_earth_globe/sphere_shader_painter.dart';
import 'package:flutter_earth_globe/visible_connection.dart';
import 'package:flutter_earth_globe/visible_point.dart';
import 'package:vector_math/vector_math_64.dart';

import 'globe_coordinates.dart';
import 'math_helper.dart';
import 'point_connection.dart';
import 'flutter_earth_globe_controller.dart';
import 'sphere_image.dart';
import 'sphere_painter.dart';
import 'package:flutter/material.dart';

import 'starry_background_painter.dart';

/// The [RotatingGlobe] widget represents a sphere in a rotating globe.
///
/// It takes a [controller], [radius], and [alignment] as required parameters.
/// The [controller] is used to control the rotation and other actions of the sphere.
/// The [radius] specifies the radius of the sphere.
/// The [alignment] determines the alignment of the sphere within its container.
/// The [onZoomChanged] callback is called when the zoom level of the sphere changes.
/// The [onHover] callback is called when the sphere is hovered over.
/// The [onTap] callback is called when the sphere is tapped.
class RotatingGlobe extends StatefulWidget {
  const RotatingGlobe({
    Key? key,
    required this.controller,
    required this.radius,
    required this.alignment,
    this.onZoomChanged,
    this.onHover,
    this.onTap,
  }) : super(key: key);

  final FlutterEarthGlobeController controller;
  final double radius;
  final Alignment alignment;
  final void Function(double zoom)? onZoomChanged;
  final void Function(GlobeCoordinates? coordinates)? onHover;
  final void Function(GlobeCoordinates? coordinates)? onTap;

  @override
  RotatingGlobeState createState() => RotatingGlobeState();
}

/// The state class for the [RotatingGlobe] widget.
/// It extends [State] and uses [TickerProviderStateMixin] for animation purposes.
class RotatingGlobeState extends State<RotatingGlobe>
    with TickerProviderStateMixin {
  AnimationController? genericAnimationController;
  late double rotationX =
      0; // The rotation angle around the X-axis of the sphere.
  late double rotationZ =
      0; // The rotation angle around the Z-axis of the sphere.
  late double
      _lastRotationX; // The previous rotation angle around the X-axis of the sphere.
  late double
      _lastRotationZ; // The previous rotation angle around the Z-axis of the sphere.
  late double rotationY =
      0; // The rotation angle around the Y-axis of the sphere.
  late double
      _lastRotationY; // The previous rotation angle around the Y-axis of the sphere.
  final GlobalKey _futureBuilderKey =
      GlobalKey(); // The key for the FutureBuilder widget.

  late Offset _lastFocalPoint; // The previous focal point of the interaction.
  late AnimationController
      _lineMovingController; // The animation controller for line movement.

  double _angularVelocityX = 0.0; // The angular velocity around the X-axis.
  double _angularVelocityY = 0.0; // The angular velocity around the Y-axis.
  double _angularVelocityZ = 0.0; // The angular velocity around the Z-axis.
  late AnimationController
      _decelerationController; // The animation controller for deceleration.

  // Globe.GL-style smooth zoom
  AnimationController? _zoomAnimationController;
  double _targetZoom = 0.0;
  double _initialZoom = 0.0;
  double _lastScale = 1.0; // Track the last scale for incremental zoom

  AnimationController?
      _dayNightCycleController; // The animation controller for day/night cycle.

  double _targetRotationX = 0.0;
  double _targetRotationY = 0.0;
  double _targetRotationZ = 0.0;

  double _initialRotationX = 0.0;
  double _initialRotationY = 0.0;
  double _initialRotationZ = 0.0;

  // Cached sphere image and parameters for performance
  SphereImage? _cachedSphereImage;
  double _cachedRotationX = double.nan;
  double _cachedRotationZ = double.nan;
  double _cachedZoom = double.nan;
  double _cachedSunLongitude = double.nan;
  double _cachedSunLatitude = double.nan;
  Size _cachedSize = Size.zero;
  bool _isBuildingSphere = false;
  // Cached surface references to detect texture changes (CPU rendering)
  ui.Image? _cachedCpuSurface;
  ui.Image? _cachedCpuNightSurface;

  // GPU shader rendering support
  final SphereShaderManager _shaderManager = SphereShaderManager();
  final BackgroundShaderManager _backgroundShaderManager =
      BackgroundShaderManager();
  bool _useGpuRendering = true; // Whether to use GPU shader rendering
  bool _useGpuBackground = true; // Whether to use GPU shader for background
  bool _shadersInitialized = false; // Track if shaders have been initialized

  // Error tracking for automatic fallback to CPU rendering on web
  int _sphereShaderErrorCount = 0;
  int _backgroundShaderErrorCount = 0;
  static const int _maxShaderErrors =
      3; // Fall back to CPU after this many errors

  // Cached GPU shader to avoid recreation on every build
  ui.FragmentShader? _cachedShader;
  ui.Image? _cachedDaySurface;
  ui.Image? _cachedNightSurface;
  bool _sphereShaderNeedsRecreation = false;

  // Cached background shader
  ui.FragmentShader? _cachedBackgroundShader;
  ui.Image? _cachedBackgroundTexture;
  bool _backgroundShaderNeedsRecreation = false;

  // Use ValueNotifier for hover/click to avoid full rebuilds
  final ValueNotifier<Offset?> _hoverNotifier = ValueNotifier<Offset?>(null);
  final ValueNotifier<Offset?> _clickNotifier = ValueNotifier<Offset?>(null);

  // Use ValueNotifier for animation to trigger foreground repaints
  final ValueNotifier<int> _animationNotifier = ValueNotifier<int>(0);

  // Globe.GL-style foreground renderer for calculating positions
  final GlobeForegroundRenderer _foregroundRenderer = GlobeForegroundRenderer();

  // Cached render data for current frame
  List<PointRenderData> _pointRenderData = [];
  List<ArcRenderData> _arcRenderData = [];
  List<SatelliteRenderData> _satelliteRenderData = [];

  // Track currently hovered elements to avoid redundant callbacks
  String? _currentHoveredPointId;
  String? _currentHoveredConnectionId;
  // TODO: Add satellite hover support in future
  // String? _currentHoveredSatelliteId;

  /// Calculate the converted radius based on zoom level
  /// Includes safeguards against extreme values that could cause rendering issues
  double convertedRadius() {
    final zoom = widget.controller.zoom;
    // Ensure zoom is within valid bounds
    if (!zoom.isFinite) return widget.radius;

    final radius = widget.radius * math.pow(2, zoom);

    // Ensure radius is positive and finite
    if (radius <= 0 || !radius.isFinite) return widget.radius;

    return radius;
  }

  Offset? hoveringPoint; // The current hovering point on the sphere.
  Offset? clickPoint; // The current click point on the sphere.

  Map<String, VisiblePoint> visiblePoints =
      {}; // The map of visible points on the sphere.
  Map<String, VisibleConnection> visibleConnections =
      {}; // The map of visible connections on the sphere.

  Offset center = const Offset(0, 0); // The center of the sphere.

  @override
  void initState() {
    widget.controller.addListener(_update);
    widget.controller.rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (mounted) {
          setState(() {
            rotationZ = (rotationZ -
                    (widget.controller.rotationSpeed *
                        ((math.pow((2 * math.pi), 2) / 360)))) %
                (2 * math.pi);
          });

          // Update hover coordinates during rotation if mouse is over the globe
          _updateHoverCoordinatesDuringRotation();

          if (widget.controller.rotationController.isCompleted) {
            if (widget.controller.isRotating) {
              widget.controller.rotationController.repeat();
            }
          }
        }
      });

    widget.controller.onPointConnectionAdded = _addConnection;

    widget.controller.onResetGlobeRotation = resetRotation;

    widget.controller.onStartDayNightCycleAnimation =
        startDayNightCycleAnimation;
    widget.controller.onStopDayNightCycleAnimation = stopDayNightCycleAnimation;

    // Globe.GL-style continuous animation controller
    // Uses a simple repeating animation to drive frame updates
    _lineMovingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )
      ..addListener(() {
        if (mounted) {
          // Check if there are any moving connections or connections with dashAnimateTime
          bool hasAnimatingConnections = false;
          for (var connection in widget.controller.connections) {
            if (connection.isMoving || connection.style.dashAnimateTime > 0) {
              hasAnimatingConnections = true;
              break;
            }
          }

          // Check if there are any orbiting satellites
          bool hasOrbitingSatellites = false;
          for (var satellite in widget.controller.satellites) {
            if (satellite.orbit != null) {
              hasOrbitingSatellites = true;
              break;
            }
          }

          // Trigger foreground repaint for animations
          // Use modulo to prevent integer overflow after long runtime
          if (hasAnimatingConnections || hasOrbitingSatellites) {
            _animationNotifier.value = (_animationNotifier.value + 1) % 1000000;
          }
        }
      })
      ..repeat();

    rotationX = 0;
    rotationY = 0; // Initialize rotationY
    rotationZ = 0;

    _decelerationController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 1200), // Longer for smoother deceleration
    )..addListener(() {
        if (mounted) {
          // Use easeOutQuint for smoother, more natural deceleration like globe.gl
          final t =
              Curves.easeOutQuint.transform(_decelerationController.value);

          rotationX =
              _initialRotationX + (_targetRotationX - _initialRotationX) * t;
          rotationY =
              _initialRotationY + (_targetRotationY - _initialRotationY) * t;
          rotationZ =
              _initialRotationZ + (_targetRotationZ - _initialRotationZ) * t;

          setState(() {});
        }
      });

    // Initialize zoom animation controller for smooth zoom transitions
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (mounted) {
          final t =
              Curves.easeOutCubic.transform(_zoomAnimationController!.value);
          widget.controller.zoom =
              _initialZoom + (_targetZoom - _initialZoom) * t;
          widget.onZoomChanged?.call(widget.controller.zoom);
          setState(() {});
        }
      });

    // Initialize day/night cycle animation controller
    _initDayNightCycleController();

    // Initialize GPU shader rendering
    _initShaderRendering();

    Future.delayed(Duration.zero, () {
      widget.controller.load();
    });

    super.initState();
  }

  /// Initialize GPU shader rendering
  Future<void> _initShaderRendering() async {
    if (_shadersInitialized) return;

    try {
      // Load sphere shader
      final sphereSuccess = await _shaderManager.loadShader();
      if (!mounted) return;

      setState(() {
        _useGpuRendering = sphereSuccess;
        _sphereShaderNeedsRecreation = sphereSuccess;
      });
      if (!sphereSuccess) {
        debugPrint(
            'GPU shader rendering not available, falling back to CPU rendering');
        if (_shaderManager.loadError != null) {
          debugPrint('Shader load error: ${_shaderManager.loadError}');
        }
      }

      // Load background shader
      final backgroundSuccess = await _backgroundShaderManager.loadShader();
      if (!mounted) return;

      setState(() {
        _useGpuBackground = backgroundSuccess;
        _backgroundShaderNeedsRecreation = backgroundSuccess;
        _shadersInitialized = true;
      });
      if (!backgroundSuccess) {
        debugPrint(
            'GPU background shader not available, falling back to CPU rendering');
        if (_backgroundShaderManager.loadError != null) {
          debugPrint(
              'Background shader load error: ${_backgroundShaderManager.loadError}');
        }
      }
    } catch (e) {
      debugPrint('Error during shader initialization: $e');
      if (mounted) {
        setState(() {
          _useGpuRendering = false;
          _useGpuBackground = false;
          _shadersInitialized = true;
        });
      }
    }
  }

  /// Initialize the day/night cycle animation controller
  void _initDayNightCycleController() {
    if (widget.controller.useRealTimeSunPosition) {
      _dayNightCycleController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 60), // Update every minute
      )..addListener(() {
          if (mounted && widget.controller.useRealTimeSunPosition) {
            widget.controller.updateSunPositionFromRealTime();
          }
        });
      _dayNightCycleController!.repeat();
    }
  }

  Duration _dayNightCycleDuration = const Duration(minutes: 1);
  DayNightCycleDirection _dayNightCycleDirection =
      DayNightCycleDirection.leftToRight;

  /// Start the day/night cycle animation with custom speed and direction
  void startDayNightCycleAnimation({
    Duration cycleDuration = const Duration(minutes: 1),
    DayNightCycleDirection direction = DayNightCycleDirection.leftToRight,
  }) {
    _dayNightCycleDirection = direction;

    // If controller exists and duration hasn't changed, just resume
    if (_dayNightCycleController != null &&
        _dayNightCycleDuration == cycleDuration &&
        !_dayNightCycleController!.isAnimating) {
      // Calculate where we should be based on current sun longitude
      final currentValue = _calculateAnimationValueFromSunLongitude();
      _dayNightCycleController!.value = currentValue.clamp(0.0, 1.0);
      _dayNightCycleController!.repeat();
      return;
    }

    // Otherwise, create new controller
    _dayNightCycleController?.dispose();
    _dayNightCycleDuration = cycleDuration;

    // Calculate starting value based on current sun position
    final startValue = _calculateAnimationValueFromSunLongitude();

    _dayNightCycleController = AnimationController(
      vsync: this,
      duration: cycleDuration,
      value: startValue.clamp(0.0, 1.0),
    )..addListener(() {
        if (mounted) {
          // Animate sun longitude based on direction
          widget.controller.sunLongitude =
              _calculateSunLongitudeFromAnimationValue(
            _dayNightCycleController!.value,
          );
          setState(() {});
        }
      });
    _dayNightCycleController!.repeat();
  }

  /// Calculate animation value from current sun longitude
  double _calculateAnimationValueFromSunLongitude() {
    if (_dayNightCycleDirection == DayNightCycleDirection.leftToRight) {
      // Left to right: sunLongitude goes from 180 to -180
      return (180 - widget.controller.sunLongitude) / 360;
    } else {
      // Right to left: sunLongitude goes from -180 to 180
      return (widget.controller.sunLongitude + 180) / 360;
    }
  }

  /// Calculate sun longitude from animation value based on direction
  double _calculateSunLongitudeFromAnimationValue(double value) {
    if (_dayNightCycleDirection == DayNightCycleDirection.leftToRight) {
      // Left to right: sun moves from east (180) to west (-180)
      return 180 - (value * 360);
    } else {
      // Right to left: sun moves from west (-180) to east (180)
      return -180 + (value * 360);
    }
  }

  /// Stop the day/night cycle animation
  void stopDayNightCycleAnimation() {
    _dayNightCycleController?.stop();
  }

  /// Focus on the specified coordinates on the sphere.
  void focusOnCoordinates(GlobeCoordinates coordinates,
      {required bool animate, required Duration? duration}) {
    double latRad = radians(coordinates.latitude);
    double lonRad = radians(-coordinates.longitude);
    final targetRotationZ = -lonRad;
    final targetRotationY = -latRad;
    final targetRotationX = latRad;
    if (animate) {
      final initialRotationZ = rotationZ;
      final initialRotationX = rotationX;
      final initialRotationY = rotationY;

      final rZ = targetRotationZ - initialRotationZ;
      final rX = targetRotationX - initialRotationX;
      final rY = targetRotationY - initialRotationY;

      genericAnimationController = AnimationController(
        vsync: this,
        duration: duration,
      )
        ..addListener(() {
          double animationFactor = genericAnimationController?.value ?? 1;
          rotationX = initialRotationX + rX * animationFactor;
          rotationY = initialRotationY + rY * animationFactor;
          rotationZ = initialRotationZ + rZ * animationFactor;

          setState(() {});
        })
        ..forward();
    } else {
      rotationX = targetRotationX;
      rotationY = targetRotationY;
      rotationZ = targetRotationZ;
      setState(() {});
    }
  }

  /// Reset the rotation of the sphere
  void resetRotation() {
    rotationX = 0;
    rotationY = 0; // Reset rotationY
    rotationZ = 0;
    setState(() {});
  }

  /// Add a connection to the sphere
  _addConnection(AnimatedPointConnection connection,
      {required bool animateDraw, required Duration animateDrawDuration}) {
    if (animateDraw) {
      final animation = AnimationController(
        vsync: this,
        duration: animateDrawDuration,
      )..forward();

      Tween<double>(begin: 0.0, end: 1.0).animate(animation).addListener(() {
        setState(() {
          connection.animationProgress = animation.value;
        });
      });
    } else {
      connection.animationProgress = 1.0;
    }
  }

  /// Update the state of the sphere
  _update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    widget.controller.rotationController.dispose();
    _lineMovingController.stop();
    _lineMovingController.dispose();
    _decelerationController.dispose();
    _zoomAnimationController?.dispose();
    _dayNightCycleController?.dispose();
    _hoverNotifier.dispose();
    _clickNotifier.dispose();
    super.dispose();
  }

  /// Calculate the day/night blend factor for a given latitude and longitude
  /// Returns a value between 0 (full night) and 1 (full day)
  double _calculateDayNightFactor(double lat, double lon) {
    // Convert sun position to radians
    final sunLatRad = widget.controller.sunLatitude * math.pi / 180;
    final sunLonRad = widget.controller.sunLongitude * math.pi / 180;

    // Calculate the angle between the point and the sun
    // Using spherical law of cosines
    final cosAngle = math.sin(lat) * math.sin(sunLatRad) +
        math.cos(lat) * math.cos(sunLatRad) * math.cos(lon - sunLonRad);

    // Convert to a 0-1 factor with smooth transition
    // Using the blend factor to control the sharpness of the transition
    final blendFactor = widget.controller.dayNightBlendFactor;

    // Map the cosine angle to a smooth transition
    // cosAngle of 0 is the terminator (90 degrees from sun)
    // Positive values are day, negative values are night
    final factor = (cosAngle / blendFactor + 0.5).clamp(0.0, 1.0);

    return factor;
  }

  /// Check if cached sphere image is still valid
  bool _isCacheValid(double maxWidth, double maxHeight) {
    if (_cachedSphereImage == null || _isBuildingSphere) return false;

    // Check if surface textures have changed
    if (_cachedCpuSurface != widget.controller.surface) return false;
    if (_cachedCpuNightSurface != widget.controller.nightSurface) return false;

    final hasDayNightCycle = widget.controller.isDayNightCycleEnabled &&
        widget.controller.nightSurface != null;

    // If day/night cycle is enabled, check sun position
    if (hasDayNightCycle) {
      if (_cachedSunLongitude != widget.controller.sunLongitude ||
          _cachedSunLatitude != widget.controller.sunLatitude) {
        return false;
      }
    }

    return _cachedRotationX == rotationX &&
        _cachedRotationZ == rotationZ &&
        _cachedZoom == widget.controller.zoom &&
        _cachedSize == Size(maxWidth, maxHeight);
  }

  /// Update cache parameters after building sphere
  void _updateCacheParams(double maxWidth, double maxHeight) {
    _cachedRotationX = rotationX;
    _cachedRotationZ = rotationZ;
    _cachedZoom = widget.controller.zoom;
    _cachedSunLongitude = widget.controller.sunLongitude;
    _cachedSunLatitude = widget.controller.sunLatitude;
    _cachedSize = Size(maxWidth, maxHeight);
    _cachedCpuSurface = widget.controller.surface;
    _cachedCpuNightSurface = widget.controller.nightSurface;
  }

  Future<SphereImage?> buildSphere(double maxWidth, double maxHeight) async {
    // Return cached image if still valid
    if (_isCacheValid(maxWidth, maxHeight)) {
      return _cachedSphereImage;
    }

    // Prevent concurrent builds
    if (_isBuildingSphere) {
      return _cachedSphereImage;
    }
    _isBuildingSphere = true;

    if (widget.controller.surface == null ||
        widget.controller.surfaceProcessed == null) {
      _isBuildingSphere = false;
      return Future.value(null);
    }

    // Check if day/night cycle is enabled and we have night surface
    final hasDayNightCycle = widget.controller.isDayNightCycleEnabled &&
        widget.controller.nightSurface != null &&
        widget.controller.nightSurfaceProcessed != null;

    final sphereRadius = convertedRadius().roundToDouble();
    final sphereRadiusSquared = sphereRadius * sphereRadius;
    final minX = math.max(-sphereRadius, -maxWidth / 2);
    final minY = math.max(-sphereRadius, -maxHeight / 2);
    final maxX = math.min(sphereRadius, maxWidth / 2);
    final maxY = math.min(sphereRadius, maxHeight / 2);
    final width = maxX - minX;
    final height = maxY - minY;
    final widthInt = width.toInt();

    final surfaceWidth = widget.controller.surface?.width.toDouble();
    final surfaceHeight = widget.controller.surface?.height.toDouble();
    final surfaceWidthInt = surfaceWidth!.toInt();
    final surfaceHeightInt = surfaceHeight!.toInt();

    final spherePixels = Uint32List(widthInt * height.toInt());

    // Prepare rotation matrices - combine for efficiency
    final rotationMatrixX = Matrix3.rotationX(math.pi / 2 - rotationX);
    final rotationMatrixZ = Matrix3.rotationZ(rotationZ + math.pi / 2);
    final combinedRotationMatrix = rotationMatrixZ.multiplied(rotationMatrixX);

    final surfaceXRate = (surfaceWidth - 1) / (2.0 * math.pi);
    final surfaceYRate = (surfaceHeight - 1) / math.pi;
    final invSphereRadius = 1.0 / sphereRadius;

    // Pre-compute surface data reference for faster access
    final surfaceData = widget.controller.surfaceProcessed!;

    // Anti-aliasing parameters
    const aaWidth = 1.5; // Width of anti-aliasing band in pixels

    for (var y = minY; y < maxY; y++) {
      final sphereY = (height - y + minY - 1).toInt() * widthInt;
      final ySquared = y * y;
      for (var x = minX; x < maxX; x++) {
        final distSquared = x * x + ySquared;
        final dist = math.sqrt(distSquared);

        // Calculate edge alpha for anti-aliasing
        // Smooth transition from full opacity inside to transparent outside
        double edgeAlpha = 1.0;
        if (dist > sphereRadius - aaWidth) {
          if (dist > sphereRadius + aaWidth * 0.5) {
            continue; // Completely outside, skip this pixel
          }
          // Smooth interpolation at the edge
          edgeAlpha = (sphereRadius + aaWidth * 0.5 - dist) / (aaWidth * 1.5);
          edgeAlpha = edgeAlpha.clamp(0.0, 1.0);
          // Apply smoothstep for better visual quality
          edgeAlpha = edgeAlpha * edgeAlpha * (3.0 - 2.0 * edgeAlpha);
        }

        final zSquared = sphereRadiusSquared - distSquared;
        if (zSquared > 0 || edgeAlpha > 0) {
          // For edge pixels, use a safe z calculation
          final safeZSquared = math.max(
              0.0,
              sphereRadiusSquared -
                  math.min(distSquared, sphereRadiusSquared * 0.999));
          final z = math.sqrt(safeZSquared);

          // For edge pixels, scale position to stay on sphere surface
          double effectiveX = x;
          double effectiveY = y;
          if (dist > sphereRadius * 0.99) {
            final scale = sphereRadius * 0.99 / dist;
            effectiveX = x * scale;
            effectiveY = y * scale;
          }

          var vector = Vector3(effectiveX, effectiveY, z);

          // Apply combined rotation in one step
          vector = combinedRotationMatrix.transform(vector);

          final lat = math.asin(vector.z * invSphereRadius);
          final lon = math.atan2(vector.y, vector.x);

          final x0 = (lon + math.pi) * surfaceXRate;
          final y0 = (math.pi / 2 - lat) * surfaceYRate;

          // Bilinear interpolation for smoother texture mapping
          final x0Floor = x0.floor();
          final y0Floor = y0.floor();
          final x0Ceil = (x0Floor + 1).clamp(0, surfaceWidthInt - 1);
          final y0Ceil = (y0Floor + 1).clamp(0, surfaceHeightInt - 1);
          final x0ClampedFloor = x0Floor.clamp(0, surfaceWidthInt - 1);
          final y0ClampedFloor = y0Floor.clamp(0, surfaceHeightInt - 1);

          final fx = x0 - x0Floor;
          final fy = y0 - y0Floor;

          // Get day surface colors with pre-computed indices
          final idx00 = y0ClampedFloor * surfaceWidthInt + x0ClampedFloor;
          final idx10 = y0ClampedFloor * surfaceWidthInt + x0Ceil;
          final idx01 = y0Ceil * surfaceWidthInt + x0ClampedFloor;
          final idx11 = y0Ceil * surfaceWidthInt + x0Ceil;

          final c00 = surfaceData[idx00];
          final c10 = surfaceData[idx10];
          final c01 = surfaceData[idx01];
          final c11 = surfaceData[idx11];

          // Extract RGBA components for day surface
          final r00 = (c00 >> 0) & 0xFF;
          final g00 = (c00 >> 8) & 0xFF;
          final b00 = (c00 >> 16) & 0xFF;
          final a00 = (c00 >> 24) & 0xFF;

          final r10 = (c10 >> 0) & 0xFF;
          final g10 = (c10 >> 8) & 0xFF;
          final b10 = (c10 >> 16) & 0xFF;
          final a10 = (c10 >> 24) & 0xFF;

          final r01 = (c01 >> 0) & 0xFF;
          final g01 = (c01 >> 8) & 0xFF;
          final b01 = (c01 >> 16) & 0xFF;
          final a01 = (c01 >> 24) & 0xFF;

          final r11 = (c11 >> 0) & 0xFF;
          final g11 = (c11 >> 8) & 0xFF;
          final b11 = (c11 >> 16) & 0xFF;
          final a11 = (c11 >> 24) & 0xFF;

          // Bilinear interpolation for day surface
          var r = ((r00 * (1 - fx) + r10 * fx) * (1 - fy) +
                  (r01 * (1 - fx) + r11 * fx) * fy)
              .round()
              .clamp(0, 255);
          var g = ((g00 * (1 - fx) + g10 * fx) * (1 - fy) +
                  (g01 * (1 - fx) + g11 * fx) * fy)
              .round()
              .clamp(0, 255);
          var b = ((b00 * (1 - fx) + b10 * fx) * (1 - fy) +
                  (b01 * (1 - fx) + b11 * fx) * fy)
              .round()
              .clamp(0, 255);
          var a = ((a00 * (1 - fx) + a10 * fx) * (1 - fy) +
                  (a01 * (1 - fx) + a11 * fx) * fy)
              .round()
              .clamp(0, 255);

          // Apply day/night blending if enabled
          if (hasDayNightCycle) {
            final dayFactor = _calculateDayNightFactor(lat, lon);

            // Get night surface colors
            final nightWidth = widget.controller.nightSurface!.width.toDouble();
            final nightHeight =
                widget.controller.nightSurface!.height.toDouble();
            final nightXRate = (nightWidth - 1) / (2.0 * math.pi);
            final nightYRate = (nightHeight - 1) / math.pi;

            final nx0 = (lon + math.pi) * nightXRate;
            final ny0 = (math.pi / 2 - lat) * nightYRate;

            final nx0Floor = nx0.floor();
            final ny0Floor = ny0.floor();
            final nx0Ceil = (nx0Floor + 1).clamp(0, nightWidth.toInt() - 1);
            final ny0Ceil = (ny0Floor + 1).clamp(0, nightHeight.toInt() - 1);
            final nx0ClampedFloor = nx0Floor.clamp(0, nightWidth.toInt() - 1);
            final ny0ClampedFloor = ny0Floor.clamp(0, nightHeight.toInt() - 1);

            final nfx = nx0 - nx0Floor;
            final nfy = ny0 - ny0Floor;

            final nc00 = widget.controller.nightSurfaceProcessed![
                (ny0ClampedFloor * nightWidth + nx0ClampedFloor).toInt()];
            final nc10 = widget.controller.nightSurfaceProcessed![
                (ny0ClampedFloor * nightWidth + nx0Ceil).toInt()];
            final nc01 = widget.controller.nightSurfaceProcessed![
                (ny0Ceil * nightWidth + nx0ClampedFloor).toInt()];
            final nc11 = widget.controller.nightSurfaceProcessed![
                (ny0Ceil * nightWidth + nx0Ceil).toInt()];

            // Extract RGBA components for night surface
            final nr00 = (nc00 >> 0) & 0xFF;
            final ng00 = (nc00 >> 8) & 0xFF;
            final nb00 = (nc00 >> 16) & 0xFF;
            final na00 = (nc00 >> 24) & 0xFF;

            final nr10 = (nc10 >> 0) & 0xFF;
            final ng10 = (nc10 >> 8) & 0xFF;
            final nb10 = (nc10 >> 16) & 0xFF;
            final na10 = (nc10 >> 24) & 0xFF;

            final nr01 = (nc01 >> 0) & 0xFF;
            final ng01 = (nc01 >> 8) & 0xFF;
            final nb01 = (nc01 >> 16) & 0xFF;
            final na01 = (nc01 >> 24) & 0xFF;

            final nr11 = (nc11 >> 0) & 0xFF;
            final ng11 = (nc11 >> 8) & 0xFF;
            final nb11 = (nc11 >> 16) & 0xFF;
            final na11 = (nc11 >> 24) & 0xFF;

            // Bilinear interpolation for night surface
            final nr = ((nr00 * (1 - nfx) + nr10 * nfx) * (1 - nfy) +
                    (nr01 * (1 - nfx) + nr11 * nfx) * nfy)
                .round()
                .clamp(0, 255);
            final ng = ((ng00 * (1 - nfx) + ng10 * nfx) * (1 - nfy) +
                    (ng01 * (1 - nfx) + ng11 * nfx) * nfy)
                .round()
                .clamp(0, 255);
            final nb = ((nb00 * (1 - nfx) + nb10 * nfx) * (1 - nfy) +
                    (nb01 * (1 - nfx) + nb11 * nfx) * nfy)
                .round()
                .clamp(0, 255);
            final na = ((na00 * (1 - nfx) + na10 * nfx) * (1 - nfy) +
                    (na01 * (1 - nfx) + na11 * nfx) * nfy)
                .round()
                .clamp(0, 255);

            // Blend day and night colors based on dayFactor
            r = (r * dayFactor + nr * (1 - dayFactor)).round().clamp(0, 255);
            g = (g * dayFactor + ng * (1 - dayFactor)).round().clamp(0, 255);
            b = (b * dayFactor + nb * (1 - dayFactor)).round().clamp(0, 255);
            a = (a * dayFactor + na * (1 - dayFactor)).round().clamp(0, 255);
          }

          // Apply edge anti-aliasing alpha
          a = (a * edgeAlpha).round().clamp(0, 255);

          // Premultiply RGB by alpha for correct blending
          r = (r * edgeAlpha).round().clamp(0, 255);
          g = (g * edgeAlpha).round().clamp(0, 255);
          b = (b * edgeAlpha).round().clamp(0, 255);

          final color = (a << 24) | (b << 16) | (g << 8) | r;
          spherePixels[(sphereY + x - minX).toInt()] = color;
        }
      }
    }

    final completer = Completer<SphereImage>();
    ui.decodeImageFromPixels(spherePixels.buffer.asUint8List(), width.toInt(),
        height.toInt(), ui.PixelFormat.rgba8888, (image) {
      final sphereImage = SphereImage(
        image: image,
        radius: sphereRadius,
        origin: Offset(-minX, -minY),
        offset: Offset(maxWidth / 2, maxHeight / 2),
      );
      // Cache the result
      _cachedSphereImage = sphereImage;
      _updateCacheParams(maxWidth, maxHeight);
      _isBuildingSphere = false;
      completer.complete(sphereImage);
    });
    return completer.future;
  }

  /// Handle tap event
  onTapEvent(TapDownDetails details) {
    clickPoint = details.localPosition;
    _clickNotifier.value = details.localPosition;
    // Don't call setState - the ValueNotifier will trigger foreground repaint
    widget.onTap?.call(
      convert2DPointToSphereCoordinates(
        details.localPosition,
        center,
        convertedRadius(),
        rotationY,
        rotationZ,
      ),
    );
  }

  /// Update hover coordinates during rotation (when mouse doesn't move but globe rotates)
  void _updateHoverCoordinatesDuringRotation() {
    final currentHover = hoveringPoint;
    if (currentHover != null && widget.onHover != null) {
      widget.onHover?.call(
        convert2DPointToSphereCoordinates(
          currentHover,
          center,
          convertedRadius(),
          rotationY,
          rotationZ,
        ),
      );
    }
  }

  /// Handle hover event
  onHover(PointerEvent event) {
    hoveringPoint = event.localPosition;
    _hoverNotifier.value = event.localPosition;
    // Don't call setState - the ValueNotifier will trigger foreground repaint
    widget.onHover?.call(
      convert2DPointToSphereCoordinates(
        event.localPosition,
        center,
        convertedRadius(),
        rotationY,
        rotationZ,
      ),
    );
  }

  /// Apply smooth animated zoom like globe.gl
  /// Uses logarithmic scaling for more natural zoom feel
  void _animateZoomTo(double targetZoom) {
    final clampedTarget =
        targetZoom.clamp(widget.controller.minZoom, widget.controller.maxZoom);
    if ((clampedTarget - widget.controller.zoom).abs() < 0.001) return;

    _initialZoom = widget.controller.zoom;
    _targetZoom = clampedTarget;
    _zoomAnimationController?.forward(from: 0.0);
  }

  /// Update zoom immediately without animation (for continuous gestures)
  _onZoomUpdated(double scale) {
    // Ignore invalid scale values
    if (!scale.isFinite) return;

    // Use logarithmic scaling for smoother zoom feel like globe.gl
    // This makes zooming feel more natural at different zoom levels
    final zoomFactor = scale * widget.controller.zoomSensitivity;
    final tempZoom = widget.controller.zoom + zoomFactor;

    // Ensure the zoom value is valid before applying
    if (!tempZoom.isFinite) return;

    widget.controller.zoom =
        tempZoom.clamp(widget.controller.minZoom, widget.controller.maxZoom);
    widget.onZoomChanged?.call(widget.controller.zoom);
    setState(() {});
  }

  /// Handle scroll wheel zoom with smooth animation
  void _onScrollZoom(double delta) {
    // Ignore invalid delta values
    if (!delta.isFinite) return;

    // Logarithmic zoom: zoom change is proportional to current zoom level
    // This provides consistent zoom speed at all zoom levels like globe.gl
    final zoomDelta = -delta * 0.001 * (1.0 + widget.controller.zoom * 0.5);

    // Ensure the zoom delta is valid
    if (!zoomDelta.isFinite) return;

    final targetZoom = widget.controller.zoom + zoomDelta;
    _animateZoomTo(targetZoom);
  }

  /// Get pan sensitivity adjusted for current zoom level
  /// When zoomed in, pan should be slower; when zoomed out, faster
  double get _panSensitivity {
    // Inverse relationship: higher zoom = lower sensitivity
    final zoom = widget.controller.zoom;
    final baseSensitivity = widget.controller.panSensitivity;
    if (!zoom.isFinite) return baseSensitivity;
    return baseSensitivity / (1.0 + zoom * 0.5);
  }

  /// Build the sphere widget using GPU shader rendering
  Widget? _buildGpuSphere(BoxConstraints constraints) {
    // Check if we can use GPU rendering (also check error count for web stability)
    if (!_useGpuRendering) return null;

    // If shader manager needs reloading (after forceReload), trigger async reload
    // but DON'T return null - keep using cached shader if available
    if (!_shaderManager.isReady && !_shaderManager.loadFailed) {
      // Trigger async shader reload
      _shaderManager.loadShader().then((success) {
        if (mounted && success) {
          setState(() {
            _sphereShaderNeedsRecreation = true;
          });
        }
      });
      // If we have a cached shader, continue using it
      // Only return null if we have no shader at all
      if (_cachedShader == null) return null;
    }

    if (!_shaderManager.isReady && _cachedShader == null) return null;
    if (_sphereShaderErrorCount >= _maxShaderErrors) {
      // Too many shader errors, fall back to CPU permanently
      _useGpuRendering = false;
      return null;
    }
    if (widget.controller.surface == null) return null;

    final hasDayNightCycle = widget.controller.isDayNightCycleEnabled &&
        widget.controller.nightSurface != null;

    // Check if we need to recreate the shader (textures changed or shader needs recreation)
    final daySurface = widget.controller.surface!;
    final nightSurface =
        hasDayNightCycle ? widget.controller.nightSurface : null;

    final needsRecreation = _cachedShader == null ||
        _sphereShaderNeedsRecreation ||
        _cachedDaySurface != daySurface ||
        _cachedNightSurface != nightSurface;

    if (needsRecreation) {
      try {
        // Create new shader with bound textures
        final newShader = _shaderManager.createShaderWithTextures(
          daySurface: daySurface,
          nightSurface: nightSurface,
        );
        // Only update if we successfully got a new shader
        if (newShader != null) {
          _cachedShader = newShader;
          _cachedDaySurface = daySurface;
          _cachedNightSurface = nightSurface;
          _sphereShaderNeedsRecreation = false;
          // Reset error count on successful creation
          _sphereShaderErrorCount = 0;
        } else {
          // Shader creation returned null - mark for retry but keep old shader
          _sphereShaderNeedsRecreation = true;
        }
      } catch (e) {
        debugPrint('Error creating sphere shader: $e');
        // Keep the old cached shader if we have one - don't set to null!
        _sphereShaderErrorCount++;
        _sphereShaderNeedsRecreation = true;
        if (_sphereShaderErrorCount >= _maxShaderErrors) {
          _useGpuRendering = false;
          _cachedShader = null; // Only clear on permanent fallback
        }
        // If we still have an old shader, don't return null
        if (_cachedShader == null) return null;
      }
    }

    if (_cachedShader == null) {
      // Mark for recreation on next frame
      _sphereShaderNeedsRecreation = true;
      _sphereShaderErrorCount++;
      return null;
    }

    final sphereRadius = convertedRadius();

    // Guard against invalid radius values that could cause rendering issues
    if (sphereRadius <= 0 || !sphereRadius.isFinite) {
      return null;
    }

    final sphereCenter =
        Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

    return CustomPaint(
      painter: SphereShaderPainter(
        shader: _cachedShader!,
        radius: sphereRadius,
        center: sphereCenter,
        rotationX: rotationX,
        rotationZ: rotationZ,
        sunLongitude: widget.controller.sunLongitude,
        sunLatitude: widget.controller.sunLatitude,
        blendFactor: widget.controller.dayNightBlendFactor,
        isDayNightEnabled: hasDayNightCycle,
        onPaintError: _handleSphereShaderPaintError,
      ),
      size: Size(constraints.maxWidth, constraints.maxHeight),
    );
  }

  /// Handle sphere shader paint errors by incrementing error count and potentially falling back to CPU
  void _handleSphereShaderPaintError() {
    _sphereShaderErrorCount++;

    // On web, mark shader for recreation but DON'T clear it
    // This allows us to keep showing the old shader while we try to create a new one
    if (kIsWeb && _sphereShaderErrorCount < _maxShaderErrors) {
      // Mark for recreation on next frame - don't clear the cached shader!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _sphereShaderNeedsRecreation = true;
          });
        }
      });
      return;
    }

    if (_sphereShaderErrorCount >= _maxShaderErrors && mounted) {
      // Schedule a rebuild to fall back to CPU rendering
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _useGpuRendering = false;
            _cachedShader = null;
          });
        }
      });
    }
  }

  /// Handle background shader paint errors
  void _handleBackgroundShaderPaintError() {
    _backgroundShaderErrorCount++;

    // On web, mark shader for recreation but DON'T clear it
    if (kIsWeb && _backgroundShaderErrorCount < _maxShaderErrors) {
      // Mark for recreation on next frame - don't clear the cached shader!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _backgroundShaderNeedsRecreation = true;
          });
        }
      });
      return;
    }

    if (_backgroundShaderErrorCount >= _maxShaderErrors && mounted) {
      // Schedule a rebuild to fall back to CPU rendering
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _useGpuBackground = false;
            _cachedBackgroundShader = null;
          });
        }
      });
    }
  }

  /// Calculate all point and arc positions using Globe.GL-style renderer
  /// This should be called at the start of build to update positions before rendering
  void _calculateForegroundPositions(BoxConstraints constraints) {
    final now = DateTime.now();
    final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

    // Calculate point positions
    _pointRenderData = _foregroundRenderer.calculatePointPositions(
      points: widget.controller.points,
      radius: convertedRadius(),
      rotationY: rotationY,
      rotationZ: rotationZ,
      canvasSize: canvasSize,
      now: now,
    );

    // Calculate arc positions
    _arcRenderData = _foregroundRenderer.calculateConnectionPositions(
      connections: widget.controller.connections,
      radius: convertedRadius(),
      rotationY: rotationY,
      rotationZ: rotationZ,
      canvasSize: canvasSize,
      now: now,
    );

    // Calculate satellite positions
    _satelliteRenderData = _foregroundRenderer.calculateSatellitePositions(
      satellites: widget.controller.satellites,
      radius: convertedRadius(),
      rotationY: rotationY,
      rotationZ: rotationZ,
      canvasSize: canvasSize,
      now: now,
    );

    // Update visiblePoints map for label positioning
    for (final pointData in _pointRenderData) {
      if (pointData.isVisible) {
        if (!visiblePoints.containsKey(pointData.id)) {
          visiblePoints.putIfAbsent(
            pointData.id,
            () => VisiblePoint(
              key: GlobalKey(),
              id: pointData.id,
              position: pointData.position2D,
              isVisible: true,
              isHovering: false,
            ),
          );
        } else {
          visiblePoints.update(
            pointData.id,
            (value) => value.copyWith(
              position: pointData.position2D,
              isVisible: true,
            ),
          );
        }
      } else {
        visiblePoints.remove(pointData.id);
      }
    }

    // Update visibleConnections map for label positioning
    for (final arcData in _arcRenderData) {
      final isVisible = arcData.isStartVisible ||
          arcData.isEndVisible ||
          arcData.isMidVisible;
      if (isVisible) {
        if (!visibleConnections.containsKey(arcData.id)) {
          visibleConnections.putIfAbsent(
            arcData.id,
            () => VisibleConnection(
              key: GlobalKey(),
              id: arcData.id,
              position: arcData.midPoint2D,
              isVisible: true,
              isHovering: false,
            ),
          );
        } else {
          visibleConnections.update(
            arcData.id,
            (value) => value.copyWith(
              position: arcData.midPoint2D,
              isVisible: true,
            ),
          );
        }
      } else {
        visibleConnections.remove(arcData.id);
      }
    }

    // Clean up transitions for removed elements
    _foregroundRenderer.cleanupRemovedElements(
      widget.controller.points,
      widget.controller.connections,
    );
  }

  /// Build the Globe.GL-style foreground painter
  GpuForegroundPainter _buildGpuForegroundPainter(
      {bool skipSatelliteShapes = false}) {
    return GpuForegroundPainter(
      points: _pointRenderData,
      arcs: _arcRenderData,
      satellites: _satelliteRenderData,
      radius: convertedRadius(),
      center: center,
      hoverPoint: _hoverNotifier.value,
      clickPoint: _clickNotifier.value,
      skipSatelliteShapes: skipSatelliteShapes,
      previousHoveredPointId: _currentHoveredPointId,
      previousHoveredConnectionId: _currentHoveredConnectionId,
      onPointHover: (pointId, position, isHovering, isVisible) {
        if (!mounted) return;

        // Track currently hovered point
        if (isHovering && _currentHoveredPointId != pointId) {
          _currentHoveredPointId = pointId;
        } else if (!isHovering && _currentHoveredPointId == pointId) {
          _currentHoveredPointId = null;
        }

        // Update visible point hover state
        if (visiblePoints.containsKey(pointId)) {
          visiblePoints.update(
            pointId,
            (value) => value.copyWith(isHovering: isHovering),
          );
        }
      },
      onConnectionHover: (connectionId, position, isHovering, isVisible) {
        if (!mounted) return;

        // Track currently hovered connection
        if (isHovering && _currentHoveredConnectionId != connectionId) {
          _currentHoveredConnectionId = connectionId;
        } else if (!isHovering && _currentHoveredConnectionId == connectionId) {
          _currentHoveredConnectionId = null;
        }

        // Update visible connection hover state
        if (visibleConnections.containsKey(connectionId)) {
          visibleConnections.update(
            connectionId,
            (value) => value.copyWith(isHovering: isHovering),
          );
        }
      },
      onPointClicked: () {
        // Defer the state change to after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _clickNotifier.value = null;
          }
        });
      },
    );
  }

  /// Build the background widget (GPU or CPU rendering)
  Widget _buildBackground(BoxConstraints constraints) {
    final background = widget.controller.background;
    if (background == null) return const SizedBox.shrink();

    final offsetX = widget.controller.isBackgroundFollowingSphereRotation
        ? rotationZ *
            radiansToDegrees(widget.radius * math.pow((2 * math.pi), 2) / 360)
        : 0.0;
    final offsetY = widget.controller.isBackgroundFollowingSphereRotation
        ? rotationY *
            radiansToDegrees(widget.radius * math.pow((2 * math.pi), 2) / 360)
        : 0.0;

    // If shader manager needs reloading (after forceReload), trigger async reload
    // but DON'T wait - keep using cached shader if available
    if (_useGpuBackground &&
        !_backgroundShaderManager.isReady &&
        !_backgroundShaderManager.loadFailed) {
      // Trigger async shader reload
      _backgroundShaderManager.loadShader().then((success) {
        if (mounted && success) {
          setState(() {
            _backgroundShaderNeedsRecreation = true;
          });
        }
      });
      // Continue with cached shader if available
    }

    // Try GPU rendering for background (also check error count for web stability)
    // Also try if we have a cached shader even if manager isn't ready
    if (_useGpuBackground &&
        (_backgroundShaderManager.isReady || _cachedBackgroundShader != null) &&
        _backgroundShaderErrorCount < _maxShaderErrors) {
      // Check if we need to recreate the shader (texture changed or shader needs recreation)
      final needsRecreation = _cachedBackgroundShader == null ||
          _backgroundShaderNeedsRecreation ||
          _cachedBackgroundTexture != background;

      if (needsRecreation && _backgroundShaderManager.isReady) {
        try {
          final newShader = _backgroundShaderManager.createShaderWithTexture(
            starTexture: background,
          );
          // Only update if we successfully got a new shader
          if (newShader != null) {
            _cachedBackgroundShader = newShader;
            _cachedBackgroundTexture = background;
            _backgroundShaderNeedsRecreation = false;
            // Reset error count on successful creation
            _backgroundShaderErrorCount = 0;
          } else {
            // Shader creation returned null - mark for retry but keep old shader
            _backgroundShaderNeedsRecreation = true;
          }
        } catch (e) {
          debugPrint('Error creating background shader: $e');
          // Keep the old cached shader if we have one
          _backgroundShaderErrorCount++;
          _backgroundShaderNeedsRecreation = true;
          if (_backgroundShaderErrorCount >= _maxShaderErrors) {
            _useGpuBackground = false;
            _cachedBackgroundShader = null;
          }
        }
      }

      if (_cachedBackgroundShader != null) {
        return CustomPaint(
          painter: BackgroundShaderPainter(
            shader: _cachedBackgroundShader!,
            offsetX: offsetX,
            offsetY: offsetY,
            texWidth: background.width.toDouble(),
            texHeight: background.height.toDouble(),
            onPaintError: _handleBackgroundShaderPaintError,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      }
    }

    // Fall back to CPU rendering
    return CustomPaint(
      painter: StarryBackgroundPainter(
        starTexture: background,
        rotationZ: offsetX,
        rotationY: offsetY,
      ),
      size: Size(constraints.maxWidth, constraints.maxHeight),
    );
  }

  /// Build the atmospheric glow widget that wraps around the globe
  Widget _buildAtmosphericGlow(BoxConstraints constraints, Widget child) {
    if (!widget.controller.showAtmosphere) {
      return child;
    }

    final glowColor = widget.controller.atmosphereColor;
    final glowBlur = widget.controller.atmosphereBlur;
    final glowOpacity = widget.controller.atmosphereOpacity;
    final glowThickness = widget.controller.atmosphereThickness;
    final radius = convertedRadius();

    // Safety check for invalid values
    if (!radius.isFinite || radius <= 0) {
      return child;
    }

    // Calculate spread based on thickness relative to globe radius
    final glowSpread = radius * glowThickness;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Atmospheric glow layer (behind the globe)
        Container(
          width: radius * 2 + glowSpread * 2,
          height: radius * 2 + glowSpread * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: glowOpacity),
                blurRadius: glowBlur,
                spreadRadius: glowSpread,
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: glowOpacity * 0.5),
                blurRadius: glowBlur * 2,
                spreadRadius: glowSpread * 0.5,
              ),
            ],
          ),
        ),
        // The globe itself
        child,
      ],
    );
  }

  /// Build the sphere content widget (GPU or CPU rendering)
  Widget _buildSphereContent(BoxConstraints constraints) {
    // Always calculate foreground positions at start of build
    // This ensures points are visible immediately and positions stay in sync
    _calculateForegroundPositions(constraints);

    // Try GPU rendering first
    final gpuWidget = _buildGpuSphere(constraints);
    if (gpuWidget != null) {
      // Use Stack to separate sphere and foreground into different RepaintBoundaries
      // This prevents hover events from triggering sphere repaints
      return Stack(
        children: [
          // Sphere layer - only repaints when rotation/zoom changes
          RepaintBoundary(child: gpuWidget),
          // Foreground layer - repaints on hover/click/animation via ValueListenableBuilder
          ValueListenableBuilder<int>(
            valueListenable: _animationNotifier,
            builder: (context, animValue, child) {
              // Recalculate foreground positions on each animation frame
              // This updates dash offsets for continuous dash animation
              _calculateForegroundPositions(constraints);

              return ValueListenableBuilder<Offset?>(
                valueListenable: _hoverNotifier,
                builder: (context, hoverValue, child) {
                  return ValueListenableBuilder<Offset?>(
                    valueListenable: _clickNotifier,
                    builder: (context, clickValue, child) {
                      return RepaintBoundary(
                        child: CustomPaint(
                          // Use Canvas for all foreground elements including satellites
                          painter: _buildGpuForegroundPainter(
                              skipSatelliteShapes: false),
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      );
    }

    // Fall back to CPU rendering
    return FutureBuilder(
      key: _futureBuilderKey,
      future: buildSphere(constraints.maxWidth, constraints.maxHeight),
      builder: (BuildContext context, AsyncSnapshot<SphereImage?> snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          // Use Stack to separate sphere and foreground for CPU rendering too
          return Stack(
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: SpherePainter(
                    style: widget.controller.sphereStyle,
                    sphereImage: data,
                  ),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _animationNotifier,
                builder: (context, animValue, child) {
                  // Recalculate foreground positions on each animation frame
                  // This updates dash offsets for continuous dash animation
                  _calculateForegroundPositions(constraints);

                  return ValueListenableBuilder<Offset?>(
                    valueListenable: _hoverNotifier,
                    builder: (context, hoverValue, child) {
                      return ValueListenableBuilder<Offset?>(
                        valueListenable: _clickNotifier,
                        builder: (context, clickValue, child) {
                          return RepaintBoundary(
                            child: CustomPaint(
                              // Use Canvas-based rendering for all foreground elements
                              painter: _buildGpuForegroundPainter(
                                  skipSatelliteShapes: false),
                              size: Size(
                                  constraints.maxWidth, constraints.maxHeight),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double maxWidth = screenWidth;
    double maxHeight = screenHeight;
    if (convertedRadius() * 2 > maxWidth) {
      maxWidth = convertedRadius() * 2 + 50;
    }
    if (convertedRadius() * 2 > maxHeight) {
      maxHeight = convertedRadius() * 2 + 50;
    }

    double left = 0;
    if (screenWidth < maxWidth) {
      left = (maxWidth - screenWidth) / 2;
    }
    double top = 0;
    if (screenHeight < maxHeight) {
      top = (maxHeight - screenHeight) / 2;
    }
    return Stack(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          return widget.controller.background == null
              ? const SizedBox.shrink()
              : RepaintBoundary(
                  child: _buildBackground(constraints),
                );
        }),
        Positioned(
          left: -left,
          top: -top,
          width: maxWidth,
          height: maxHeight,
          child: Listener(
            onPointerSignal: (PointerSignalEvent event) {
              // Handle scroll wheel zoom with smooth animation
              if (event is PointerScrollEvent &&
                  widget.controller.isZoomEnabled) {
                _onScrollZoom(event.scrollDelta.dy);
              }
            },
            child: InteractiveViewer(
              // Disable InteractiveViewer's scale to use our custom zoom handling
              scaleEnabled: false,
              panEnabled: false,
              trackpadScrollCausesScale: false, // We handle this ourselves now
              onInteractionStart: (ScaleStartDetails details) {
                _lastRotationX = rotationX;
                _lastRotationZ = rotationZ;
                _lastRotationY = rotationY;
                _lastFocalPoint = details.focalPoint;
                _lastScale = 1.0; // Reset scale tracking

                if (_decelerationController.isAnimating) {
                  _decelerationController.stop();
                  _decelerationController.reset();
                }

                // Stop zoom animation when starting new gesture
                if (_zoomAnimationController?.isAnimating == true) {
                  _zoomAnimationController?.stop();
                }

                if (widget.controller.isRotating) {
                  widget.controller.rotationController.stop();
                }
                setState(() {});
              },
              onInteractionUpdate: (ScaleUpdateDetails details) {
                if (widget.controller.isZoomEnabled && details.scale != 1.0) {
                  // Use incremental scale changes for smoother pinch zoom
                  final scaleDelta = details.scale - _lastScale;
                  _lastScale = details.scale;
                  // Logarithmic zoom: change is proportional to current zoom
                  final zoomDelta = scaleDelta *
                      widget.controller.zoomSensitivity *
                      (1.0 + widget.controller.zoom * 0.3);
                  _onZoomUpdated(zoomDelta);
                }
                final offset = details.focalPoint - _lastFocalPoint;
                // Apply pan sensitivity that adjusts with zoom level for consistent feel
                final panFactor = _panSensitivity;
                rotationX = adjustModRotation(_lastRotationX +
                    (offset.dy / convertedRadius()) * panFactor);
                rotationZ = adjustModRotation(_lastRotationZ -
                    (offset.dx / convertedRadius()) * panFactor);
                rotationY = adjustModRotation(_lastRotationY -
                    (offset.dy / convertedRadius()) * panFactor);
                setState(() {});
              },
              onInteractionEnd: (ScaleEndDetails details) {
                _lastScale = 1.0; // Reset scale tracking
                final velocity = details.velocity.pixelsPerSecond;
                final velocityMagnitude = velocity.distance;

                // Lower threshold for smoother start of deceleration
                if (velocityMagnitude > 30) {
                  // Adjust velocity factor based on zoom for consistent feel
                  // Higher zoom = less momentum, lower zoom = more momentum
                  final zoomFactor = 1.0 / (1.0 + widget.controller.zoom * 0.3);
                  final velocityFactor =
                      (velocityMagnitude / 4000.0) * zoomFactor;

                  final panFactor = _panSensitivity;
                  _angularVelocityX =
                      (velocity.dy / convertedRadius()) * panFactor;
                  _angularVelocityY =
                      (-velocity.dy / convertedRadius()) * panFactor;
                  _angularVelocityZ =
                      (-velocity.dx / convertedRadius()) * panFactor;

                  _initialRotationX = rotationX;
                  _initialRotationY = rotationY;
                  _initialRotationZ = rotationZ;

                  _targetRotationX =
                      rotationX + _angularVelocityX * velocityFactor;
                  _targetRotationY =
                      rotationY + _angularVelocityY * velocityFactor;
                  _targetRotationZ =
                      rotationZ + _angularVelocityZ * velocityFactor;

                  _decelerationController.forward(from: 0.0);
                }

                if (widget.controller.isRotating) {
                  widget.controller.rotationController.forward(
                      from: widget.controller.rotationController.value);
                }
              },
              child: GestureDetector(
                onTapDown: onTapEvent,
                child: Listener(
                  onPointerHover: onHover,
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      final updatedCenter = Offset(
                          constraints.maxWidth / 2, constraints.maxHeight / 2);
                      if (updatedCenter != center) {
                        Future.delayed(Duration.zero, () {
                          setState(() {
                            center = updatedCenter;
                          });
                        });
                      }
                      return Stack(
                        children: [
                          Positioned(
                            top: widget.alignment.y * constraints.maxHeight / 2,
                            left: widget.alignment.x * constraints.maxWidth / 2,
                            child: _buildAtmosphericGlow(
                              constraints,
                              _buildSphereContent(constraints),
                            ),
                          ),
                          if (visiblePoints.isNotEmpty)
                            ...visiblePoints.entries
                                .map(
                                  (e) {
                                    final point = widget.controller.points
                                        .where(
                                          (element) => element.id == e.key,
                                        )
                                        .firstOrNull;
                                    final pos = e.value.position;
                                    if (point == null ||
                                        point.labelBuilder == null ||
                                        pos == null) {
                                      return null;
                                    }

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      final box = e.value.key.currentContext
                                          ?.findRenderObject() as RenderBox?;
                                      if ((e.value.size?.height !=
                                                  box?.size.height ||
                                              e.value.size?.width !=
                                                  box?.size.width) &&
                                          box?.size != null) {
                                        if (visiblePoints.containsKey(e.key)) {
                                          visiblePoints.update(
                                              e.key,
                                              (value) => value.copyWith(
                                                    size: box?.size,
                                                  ));
                                          setState(() {});
                                        }
                                      }
                                    });

                                    double width = e.value.size?.width ?? 0;
                                    double height = e.value.size?.height ?? 0;
                                    return Positioned(
                                        key: e.value.key,
                                        left: pos.dx -
                                            point.labelOffset.dx -
                                            (width / 2),
                                        top: pos.dy -
                                            point.labelOffset.dy -
                                            height,
                                        child: point.labelBuilder!(
                                                context,
                                                point,
                                                e.value.isHovering,
                                                e.value.isVisible) ??
                                            Container());
                                  },
                                )
                                .whereType<Widget>()
                                .toList(),
                          if (visibleConnections.isNotEmpty)
                            ...visibleConnections.entries
                                .map(
                                  (e) {
                                    final connection =
                                        widget.controller.connections
                                            .where(
                                              (element) => element.id == e.key,
                                            )
                                            .firstOrNull;
                                    final pos = e.value.position;
                                    if (connection == null ||
                                        connection.labelBuilder == null ||
                                        pos == null) {
                                      return null;
                                    }

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      final box = e.value.key.currentContext
                                          ?.findRenderObject() as RenderBox?;
                                      if ((e.value.size?.height !=
                                                  box?.size.height ||
                                              e.value.size?.width !=
                                                  box?.size.width) &&
                                          box?.size != null) {
                                        if (visibleConnections
                                            .containsKey(e.key)) {
                                          visibleConnections.update(
                                            e.key,
                                            (value) => value.copyWith(
                                              size: box?.size,
                                            ),
                                          );
                                          setState(() {});
                                        }
                                      }
                                    });

                                    double width = e.value.size?.width ?? 0;
                                    double height = e.value.size?.height ?? 0;
                                    return Positioned(
                                        key: e.value.key,
                                        left: pos.dx -
                                            connection.labelOffset.dx -
                                            (width / 2),
                                        top: pos.dy -
                                            connection.labelOffset.dy -
                                            height,
                                        child: connection.labelBuilder!(
                                                context,
                                                connection,
                                                e.value.isHovering,
                                                e.value.isVisible) ??
                                            Container());
                                  },
                                )
                                .whereType<Widget>()
                                .toList(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
