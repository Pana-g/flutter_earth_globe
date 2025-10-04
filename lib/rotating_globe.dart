import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
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
      duration: const Duration(
          milliseconds: 1000), // Adjust duration for smoother effect
    )..addListener(() {
        if (mounted) {
          // Decelerate rotation based on animation value
          double decelerationFactor = (1 - _decelerationController.value);
          rotationX += _angularVelocityX * decelerationFactor;
          rotationY += _angularVelocityY * decelerationFactor;
          rotationZ += _angularVelocityZ * decelerationFactor;

          // Reset angular velocity when animation is complete
          if (_decelerationController.isCompleted) {
            _angularVelocityX = 0.0;
            _angularVelocityY = 0.0;
            _angularVelocityZ = 0.0;
          }

          setState(() {});
        }
      });
    Future.delayed(Duration.zero, () {
      widget.controller.load();
    });

    super.initState();
  }

  /// Focus on the specified coordinates on the sphere.
  void focusOnCoordinates(GlobeCoordinates coordinates,
      {required bool animate, required Duration? duration}) {
    double latRad = radians(coordinates.latitude);
    double lonRad = radians(-coordinates.longitude);
    final targetRotationZ = -lonRad;
    final targetRotationY = latRad;
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
    super.dispose();
  }

  Future<SphereImage?> buildSphere(double maxWidth, double maxHeight) async {
    if (widget.controller.surface == null ||
        widget.controller.surfaceProcessed == null) {
      return Future.value(null);
    }

    final r = convertedRadius().roundToDouble();
    final minX = math.max(-r, -maxWidth / 2);
    final minY = math.max(-r, -maxHeight / 2);
    final maxX = math.min(r, maxWidth / 2);
    final maxY = math.min(r, maxHeight / 2);
    final width = maxX - minX;
    final height = maxY - minY;

    final surfaceWidth = widget.controller.surface?.width.toDouble();
    final surfaceHeight = widget.controller.surface?.height.toDouble();

    final spherePixels = Uint32List(width.toInt() * height.toInt());

    // Prepare rotation matrices
    final rotationMatrixX = Matrix3.rotationX(math.pi / 2 - rotationX);
    // final rotationMatrixY = Matrix3.rotationY(math.pi / 2 - rotationY);
    final rotationMatrixZ = Matrix3.rotationZ(rotationZ + math.pi / 2);

    final surfaceXRate = (surfaceWidth! - 1) / (2.0 * math.pi);
    final surfaceYRate = (surfaceHeight! - 1) / math.pi;

    for (var y = minY; y < maxY; y++) {
      final sphereY = (height - y + minY - 1).toInt() * width;
      for (var x = minX; x < maxX; x++) {
        var zSquared = r * r - x * x - y * y;
        if (zSquared > 0) {
          var z = math.sqrt(zSquared);
          var vector = Vector3(x, y, z);

          // Apply rotations
          vector = rotationMatrixX.transform(vector);
          // vector = rotationMatrixY.transform(vector);
          vector = rotationMatrixZ.transform(vector);

          final lat = math.asin(vector.z / r);
          final lon = math.atan2(vector.y, vector.x);

          final x0 = (lon + math.pi) * surfaceXRate;
          final y0 = (math.pi / 2 - lat) * surfaceYRate;

          final color = widget.controller.surfaceProcessed![
              (y0.toInt() * surfaceWidth + x0.toInt()).toInt()];
          spherePixels[(sphereY + x - minX).toInt()] = color;
        }
      }
    }

    final completer = Completer<SphereImage>();
    ui.decodeImageFromPixels(spherePixels.buffer.asUint8List(), width.toInt(),
        height.toInt(), ui.PixelFormat.rgba8888, (image) {
      final sphereImage = SphereImage(
        image: image,
        radius: r,
        origin: Offset(-minX, -minY),
        offset: Offset(maxWidth / 2, maxHeight / 2),
      );
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double maxWidth = screenWidth;
    double maxHeight = screenHeight * 0.4;
    if (convertedRadius() * 2 > maxWidth) {
      maxWidth = convertedRadius() * 2 + 50;
    }
    // if (convertedRadius() * 2 > maxHeight) {
    //   maxHeight = convertedRadius() * 2 + 50;
    // }

    if (convertedRadius() * 2 > maxHeight) {
      maxWidth = maxHeight / 2; // Keep it inside half height
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
              ? Container()
              : CustomPaint(
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
                  size: Size(constraints.maxWidth, constraints.maxHeight));
        }),
        Positioned(
          left: left,
          top: top,
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

              if (widget.controller.isRotating) {
                widget.controller.rotationController.stop();
              }
              setState(() {});
              // _rotationController.stop();
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
                  _lastRotationY + offset.dy / convertedRadius());
              setState(() {});
            },
            onInteractionEnd: (ScaleEndDetails details) {
              final offset = details.velocity.pixelsPerSecond / 50;
              _angularVelocityX = offset.dy / convertedRadius();
              _angularVelocityY = offset.dy / convertedRadius();
              _angularVelocityZ = -offset.dx / convertedRadius();
              _decelerationController.forward(from: 0.0);

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
                          child: FutureBuilder(
                            key: _futureBuilderKey,
                            future: buildSphere(
                                constraints.maxWidth, constraints.maxHeight),
                            builder: (BuildContext context,
                                AsyncSnapshot<SphereImage?> snapshot) {
                              if (snapshot.hasData) {
                                final data = snapshot.data!;
                                return CustomPaint(
                                  willChange: true,
                                  isComplex: true,
                                  foregroundPainter: ForegroundPainter(
                                    hoverOverConnection: (connectionId,
                                        cartesian2D, isHovering, isVisible) {
                                      if (!mounted) return;
                                      bool changed = false;
                                      if (isVisible) {
                                        if (!visibleConnections
                                            .containsKey(connectionId)) {
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
                                        if (visibleConnections
                                            .containsKey(connectionId)) {
                                          visibleConnections
                                              .remove(connectionId);
                                          changed = true;
                                        }
                                      }
                                      if (changed) {
                                        Future.delayed(Duration.zero, () {
                                          setState(() {});
                                        });
                                      }
                                    },
                                    hoverOverPoint: (pointId, cartesian2D,
                                        isHovering, isVisisble) {
                                      if (!mounted) return;
                                      bool changed = false;
                                      if (isVisisble) {
                                        if (!visiblePoints
                                            .containsKey(pointId)) {
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
                                        if (visiblePoints
                                            .containsKey(pointId)) {
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
                                  ),
                                  painter: SpherePainter(
                                    style: widget.controller.sphereStyle,
                                    sphereImage: data,
                                  ),
                                  size: Size(constraints.maxWidth,
                                      constraints.maxHeight),
                                );
                              } else {
                                return Container();
                              }
                            },
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
        )
      ],
    );
  }
}
