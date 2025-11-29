import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter_earth_globe/sphere_shader_painter.dart';
import 'package:flutter_earth_globe/visible_connection.dart';
import 'package:flutter_earth_globe/visible_point.dart';
import 'package:vector_math/vector_math_64.dart';

import 'foreground_painter.dart';
import 'globe_coordinates.dart';
import 'math_helper.dart';
import 'point_connection.dart';
import 'flutter_earth_globe_controller.dart';
import 'sphere_image.dart';
import 'sphere_painter.dart';
import 'package:flutter/material.dart';

import 'point_connection_style.dart';
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

  // GPU shader rendering support
  final SphereShaderManager _shaderManager = SphereShaderManager();
  bool _useGpuRendering = true; // Whether to use GPU shader rendering

  double convertedRadius() =>
      widget.radius *
      math.pow(2, widget.controller.zoom); // The radius of the sphere.

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

    _lineMovingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..addListener(() {
        if (mounted) {
          for (var connection in widget.controller.connections) {
            if (connection.isMoving &&
                connection.style.type != PointConnectionType.solid) {
              double size = connection.style.type == PointConnectionType.dashed
                  ? connection.style.dashSize
                  : connection.style.dotSize;
              setState(() {
                connection.animationOffset = (_lineMovingController.value *
                        (size + connection.style.spacing)) %
                    (size + connection.style.spacing);
              });
            }
          }
        }
      })
      ..repeat();

    rotationX = 0;
    rotationY = 0; // Initialize rotationY
    rotationZ = 0;

    _decelerationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        if (mounted) {
          final t =
              Curves.easeOutCubic.transform(_decelerationController.value);

          rotationX =
              _initialRotationX + (_targetRotationX - _initialRotationX) * t;
          rotationY =
              _initialRotationY + (_targetRotationY - _initialRotationY) * t;
          rotationZ =
              _initialRotationZ + (_targetRotationZ - _initialRotationZ) * t;

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
  void _initShaderRendering() async {
    final success = await _shaderManager.loadShader();
    if (mounted) {
      setState(() {
        _useGpuRendering = success;
      });
      if (!success) {
        debugPrint(
            'GPU shader rendering not available, falling back to CPU rendering');
        if (_shaderManager.loadError != null) {
          debugPrint('Shader load error: ${_shaderManager.loadError}');
        }
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

  /// Start the day/night cycle animation with custom speed
  void startDayNightCycleAnimation(
      {Duration cycleDuration = const Duration(minutes: 1)}) {
    // If controller exists and duration hasn't changed, just resume
    if (_dayNightCycleController != null &&
        _dayNightCycleDuration == cycleDuration &&
        !_dayNightCycleController!.isAnimating) {
      // Calculate where we should be based on current sun longitude
      // sunLongitude = 180 - (value * 360), so value = (180 - sunLongitude) / 360
      final currentValue = (180 - widget.controller.sunLongitude) / 360;
      _dayNightCycleController!.value = currentValue.clamp(0.0, 1.0);
      _dayNightCycleController!.repeat();
      return;
    }

    // Otherwise, create new controller
    _dayNightCycleController?.dispose();
    _dayNightCycleDuration = cycleDuration;

    // Calculate starting value based on current sun position
    final startValue = (180 - widget.controller.sunLongitude) / 360;

    _dayNightCycleController = AnimationController(
      vsync: this,
      duration: cycleDuration,
      value: startValue.clamp(0.0, 1.0),
    )..addListener(() {
        if (mounted) {
          // Animate sun longitude from 180 to -180 degrees
          widget.controller.sunLongitude =
              180 - (_dayNightCycleController!.value * 360);
          setState(() {});
        }
      });
    _dayNightCycleController!.repeat();
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
    _dayNightCycleController?.dispose();
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

    for (var y = minY; y < maxY; y++) {
      final sphereY = (height - y + minY - 1).toInt() * widthInt;
      final ySquared = y * y;
      for (var x = minX; x < maxX; x++) {
        final zSquared = sphereRadiusSquared - x * x - ySquared;
        if (zSquared > 0) {
          final z = math.sqrt(zSquared);
          var vector = Vector3(x, y, z);

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
    setState(() {
      clickPoint = details.localPosition;
    });
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

  /// Handle hover event
  onHover(PointerEvent event) {
    setState(() {
      hoveringPoint = event.localPosition;
    });
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

  _onZoomUpdated(double scale) {
    final tempZoom = widget.controller.zoom + scale;
    widget.controller.zoom =
        tempZoom.clamp(widget.controller.minZoom, widget.controller.maxZoom);
    widget.onZoomChanged?.call(widget.controller.zoom);
    setState(() {});
  }

  /// Build the sphere widget using GPU shader rendering
  Widget? _buildGpuSphere(BoxConstraints constraints) {
    // Check if we can use GPU rendering
    if (!_useGpuRendering || !_shaderManager.isReady) return null;
    if (widget.controller.surface == null) return null;

    final hasDayNightCycle = widget.controller.isDayNightCycleEnabled &&
        widget.controller.nightSurface != null;

    // Create shader with bound textures
    final shader = _shaderManager.createShaderWithTextures(
      daySurface: widget.controller.surface!,
      nightSurface: hasDayNightCycle ? widget.controller.nightSurface : null,
    );

    if (shader == null) return null;

    final sphereRadius = convertedRadius();
    final sphereCenter =
        Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

    return CustomPaint(
      painter: SphereShaderPainter(
        shader: shader,
        radius: sphereRadius,
        center: sphereCenter,
        rotationX: rotationX,
        rotationZ: rotationZ,
        sunLongitude: widget.controller.sunLongitude,
        sunLatitude: widget.controller.sunLatitude,
        blendFactor: widget.controller.dayNightBlendFactor,
        isDayNightEnabled: hasDayNightCycle,
      ),
      size: Size(constraints.maxWidth, constraints.maxHeight),
    );
  }

  /// Build the ForegroundPainter with all the connection/point handling
  ForegroundPainter _buildForegroundPainter() {
    return ForegroundPainter(
      hoverOverConnection: (connectionId, cartesian2D, isHovering, isVisible) {
        if (!mounted) return;
        bool changed = false;
        if (isVisible) {
          if (!visibleConnections.containsKey(connectionId)) {
            visibleConnections.putIfAbsent(
                connectionId,
                () => VisibleConnection(
                    key: GlobalKey(),
                    id: connectionId,
                    position: cartesian2D,
                    isVisible: isVisible,
                    isHovering: isHovering));
            changed = true;
          } else {
            visibleConnections.update(
                connectionId,
                (value) => value.copyWith(
                    position: cartesian2D,
                    isVisible: isVisible,
                    isHovering: isHovering));
            changed = true;
          }
        } else {
          if (visibleConnections.containsKey(connectionId)) {
            visibleConnections.remove(connectionId);
            changed = true;
          }
        }
        if (changed) {
          Future.delayed(Duration.zero, () {
            setState(() {});
          });
        }
      },
      hoverOverPoint: (pointId, cartesian2D, isHovering, isVisisble) {
        if (!mounted) return;
        bool changed = false;
        if (isVisisble) {
          if (!visiblePoints.containsKey(pointId)) {
            visiblePoints.putIfAbsent(
                pointId,
                () => VisiblePoint(
                    key: GlobalKey(),
                    id: pointId,
                    position: cartesian2D,
                    isVisible: isVisisble,
                    isHovering: isHovering));
            changed = true;
          } else {
            visiblePoints.update(
                pointId,
                (value) => value.copyWith(
                    position: cartesian2D,
                    isVisible: isVisisble,
                    isHovering: isHovering));
            changed = true;
          }
        } else {
          if (visiblePoints.containsKey(pointId)) {
            visiblePoints.remove(pointId);
            changed = true;
          }
        }
        if (changed) {
          Future.delayed(Duration.zero, () {
            setState(() {});
          });
        }
      },
      connections: widget.controller.connections,
      radius: convertedRadius(),
      hoverPoint: hoveringPoint,
      clickPoint: clickPoint,
      onPointClicked: () {
        setState(() {
          clickPoint = null;
        });
      },
      rotationZ: rotationZ,
      rotationY: rotationY,
      rotationX: rotationX,
      zoomFactor: widget.controller.zoom,
      points: widget.controller.points,
    );
  }

  /// Build the sphere content widget (GPU or CPU rendering)
  Widget _buildSphereContent(BoxConstraints constraints) {
    // Try GPU rendering first
    final gpuWidget = _buildGpuSphere(constraints);
    if (gpuWidget != null) {
      return RepaintBoundary(
        child: CustomPaint(
          willChange: true,
          isComplex: true,
          foregroundPainter: _buildForegroundPainter(),
          child: gpuWidget,
        ),
      );
    }

    // Fall back to CPU rendering
    return FutureBuilder(
      key: _futureBuilderKey,
      future: buildSphere(constraints.maxWidth, constraints.maxHeight),
      builder: (BuildContext context, AsyncSnapshot<SphereImage?> snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          return RepaintBoundary(
            child: CustomPaint(
              willChange: true,
              isComplex: true,
              foregroundPainter: _buildForegroundPainter(),
              painter: SpherePainter(
                style: widget.controller.sphereStyle,
                sphereImage: data,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
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
                  child: CustomPaint(
                    painter: StarryBackgroundPainter(
                      starTexture: widget.controller.background!,
                      rotationZ:
                          widget.controller.isBackgroundFollowingSphereRotation
                              ? rotationZ *
                                  radiansToDegrees(widget.radius *
                                      math.pow((2 * math.pi), 2) /
                                      360)
                              : 0,
                      rotationY:
                          widget.controller.isBackgroundFollowingSphereRotation
                              ? rotationY *
                                  radiansToDegrees(widget.radius *
                                      math.pow((2 * math.pi), 2) /
                                      360)
                              : 0,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                );
        }),
        Positioned(
          left: -left,
          top: -top,
          width: maxWidth,
          height: maxHeight,
          child: InteractiveViewer(
            // scaleFactor: 100000000,
            scaleEnabled: false,
            panEnabled: false,
            trackpadScrollCausesScale: true,
            onInteractionStart: (ScaleStartDetails details) {
              _lastRotationX = rotationX;
              _lastRotationZ = rotationZ;
              _lastRotationY = rotationY;
              _lastFocalPoint = details.focalPoint;

              if (_decelerationController.isAnimating) {
                _decelerationController.stop();
                _decelerationController.reset();
              }

              if (widget.controller.isRotating) {
                widget.controller.rotationController.stop();
              }
              setState(() {});
            },
            onInteractionUpdate: (ScaleUpdateDetails details) {
              if (widget.controller.isZoomEnabled && details.scale != 1.0) {
                final scaleFactor = (details.scale - 1) / 5;
                _onZoomUpdated(scaleFactor);
              }
              final offset = details.focalPoint - _lastFocalPoint;
              rotationX = adjustModRotation(
                  _lastRotationX + offset.dy / convertedRadius());
              rotationZ = adjustModRotation(
                  _lastRotationZ - offset.dx / convertedRadius());
              rotationY = adjustModRotation(
                  _lastRotationY - offset.dy / convertedRadius());
              setState(() {});
            },
            onInteractionEnd: (ScaleEndDetails details) {
              final velocity = details.velocity.pixelsPerSecond;
              final velocityMagnitude = velocity.distance;

              if (velocityMagnitude > 50) {
                final velocityFactor = velocityMagnitude / 6000.0;

                _angularVelocityX = velocity.dy / convertedRadius();
                _angularVelocityY = -velocity.dy / convertedRadius();
                _angularVelocityZ = -velocity.dx / convertedRadius();

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
                widget.controller.rotationController
                    .forward(from: widget.controller.rotationController.value);
              }
            },
            child: GestureDetector(
              onTapDown: onTapEvent,
              child: Listener(
                onPointerHover: onHover,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
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
                          child: _buildSphereContent(constraints),
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
        )
      ],
    );
  }
}
