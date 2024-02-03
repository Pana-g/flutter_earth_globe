import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_earth_globe/visible_connection.dart';
import 'package:flutter_earth_globe/visible_point.dart';

import 'foreground_painter.dart';
import 'math_helper.dart';
import 'point_connection.dart';
import 'rotating_globe_controller.dart';
import 'sphere_image.dart';
import 'sphere_painter.dart';
import 'package:flutter/material.dart';

import 'point_connection_style.dart';
import 'starry_background_painter.dart';

/// The [Sphere] widget represents a sphere in a rotating globe.
///
/// It takes a [controller], [radius], and [alignment] as required parameters.
/// The [controller] is used to control the rotation and other actions of the sphere.
/// The [radius] specifies the radius of the sphere.
/// The [alignment] determines the alignment of the sphere within its container.
class Sphere extends StatefulWidget {
  const Sphere({
    Key? key,
    required this.controller,
    required this.radius,
    required this.alignment,
  }) : super(key: key);

  final RotatingGlobeController controller;
  final double radius;
  final Alignment alignment;

  @override
  _SphereState createState() => _SphereState();
}

/// The state class for the [Sphere] widget.
/// It extends [State] and uses [TickerProviderStateMixin] for animation purposes.
class _SphereState extends State<Sphere> with TickerProviderStateMixin {
  late Uint32List
      surface; // The surface of the sphere represented as a list of 32-bit integers.
  ui.Image? backgroundImage; // The background image of the sphere.
  bool backgroundFollowsRotation =
      false; // Indicates whether the background image follows the rotation of the sphere.
  String? surfacePath; // The path to the surface image of the sphere.
  double? surfaceWidth; // The width of the surface image.
  double? surfaceHeight; // The height of the surface image.
  late double zoom = 1; // The zoom level of the sphere.
  late double rotationX =
      0; // The rotation angle around the X-axis of the sphere.
  late double rotationZ =
      0; // The rotation angle around the Z-axis of the sphere.
  late double _lastZoom; // The previous zoom level of the sphere.
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
      _rotationController; // The animation controller for sphere rotation.
  late AnimationController
      _lineMovingController; // The animation controller for line movement.

  double _angularVelocityX = 0.0; // The angular velocity around the X-axis.
  double _angularVelocityY = 0.0; // The angular velocity around the Y-axis.
  double _angularVelocityZ = 0.0; // The angular velocity around the Z-axis.
  late AnimationController
      _decelerationController; // The animation controller for deceleration.

  double get radius =>
      widget.radius * math.pow(2, zoom); // The radius of the sphere.

  Offset? hoveringPoint; // The current hovering point on the sphere.
  Offset? clickPoint; // The current click point on the sphere.

  Map<String, VisiblePoint> visiblePoints =
      {}; // The map of visible points on the sphere.
  Map<String, VisibleConnection> visibleConnections =
      {}; // The map of visible connections on the sphere.

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {
          rotationZ -= 0.01;
        });
        if (_rotationController.isCompleted) {
          if (widget.controller.isRotating) {
            _rotationController.repeat();
          }
        }
      });

    widget.controller.onPointConnectionAdded = _addConnection;

    widget.controller.onPointConnectionRemoved = _update;
    widget.controller.onPointConnectionUpdated = _update;

    widget.controller.onPointAdded = _update;
    widget.controller.onPointRemoved = _update;
    widget.controller.onPointUpdated = _update;

    widget.controller.onSurfaceLoaded = loadSurface;
    widget.controller.onBackgroundLoaded = loadBackground;
    widget.controller.onBackgroundRemoved = removeBackground;

    widget.controller.onStartGlobeRotation = startRotation;
    widget.controller.onStopGlobeRotation = stopRotation;
    widget.controller.onToggleGlobeRotation = toggleRotation;
    widget.controller.onResetGlobeRotation = resetRotation;

    widget.controller.onChangeSphereStyle = _update;

    _lineMovingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..addListener(() {
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
      });
    Future.delayed(Duration.zero, () {
      widget.controller.load();
    });
  }

  /// Start rotating the sphere
  void startRotation() {
    if (!widget.controller.isRotating) {
      widget.controller.isRotating = true;
      _rotationController.forward();
      setState(() {});
    }
  }

  /// Stop rotating the sphere
  void stopRotation() {
    if (widget.controller.isRotating) {
      widget.controller.isRotating = false;
      _rotationController.stop();
      setState(() {});
    }
  }

  /// Toggle the rotation of the sphere
  void toggleRotation() {
    if (widget.controller.isRotating) {
      stopRotation();
    } else {
      startRotation();
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
    _update();
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
    }
  }

  /// Update the state of the sphere
  _update() {
    setState(() {});
  }

  @override
  void dispose() {
    _lineMovingController.stop();
    _lineMovingController.removeListener(() {});
    _lineMovingController.dispose();
    _rotationController.dispose();
    _decelerationController.dispose();
    super.dispose();
  }

  /// Build the sphere image
  Future<SphereImage>? buildSphere(double maxWidth, double maxHeight) {
    final r = radius.roundToDouble();
    final minX = math.max(-r, (-1 - widget.alignment.x) * maxWidth / 2);
    final minY = math.max(-r, (-1 + widget.alignment.y) * maxHeight / 2);
    final maxX = math.min(r, (1 - widget.alignment.x) * maxWidth / 2);
    final maxY = math.min(r, (1 + widget.alignment.y) * maxHeight / 2);
    final width = maxX - minX;
    final height = maxY - minY;

    if (width <= 0 ||
        height <= 0 ||
        surfaceWidth == null ||
        surfaceHeight == null) return null;
    final sphere = Uint32List(width.toInt() * height.toInt());

    // Calculate sine and cosine for rotations
    var angle = math.pi / 2 - rotationX; // X-axis
    final sinx = math.sin(angle);
    final cosx = math.cos(angle);
    angle = rotationZ + math.pi / 2; // Z-axis
    final sinz = math.sin(angle);
    final cosz = math.cos(angle);

    final surfaceXRate = (surfaceWidth! - 1) / (2.0 * math.pi);
    final surfaceYRate = (surfaceHeight! - 1) / (math.pi);

    for (var y = minY; y < maxY; y++) {
      final sphereY = (height - y + minY - 1).toInt() * width;
      for (var x = minX; x < maxX; x++) {
        var z = r * r - x * x - y * y;
        if (z > 0) {
          z = math.sqrt(z);

          var x1 = x, y1 = y, z1 = z;
          double x2, y2, z2;

          // Apply rotations
          // Rotate around the X axis
          y2 = y1 * cosx - z1 * sinx;
          z2 = y1 * sinx + z1 * cosx;
          y1 = y2;
          z1 = z2;

          // Rotate around the Z axis
          x2 = x1 * cosz - y1 * sinz;
          y2 = x1 * sinz + y1 * cosz;
          x1 = x2;
          y1 = y2;

          final lat = math.asin(z1 / r);
          final lon = math.atan2(y1, x1);

          final x0 = (lon + math.pi) * surfaceXRate;
          final y0 = (math.pi / 2 - lat) * surfaceYRate;

          final color = surface[(y0.toInt() * surfaceWidth! + x0).toInt()];
          sphere[(sphereY + x - minX).toInt()] = color;
        }
      }
    }

    final c = Completer<SphereImage>();
    ui.decodeImageFromPixels(sphere.buffer.asUint8List(), width.toInt(),
        height.toInt(), ui.PixelFormat.rgba8888, (image) {
      final sphereImage = SphereImage(
        image: image,
        radius: r,
        origin: Offset(-minX, -minY),
        offset: Offset((widget.alignment.x + 1) * maxWidth / 2,
            (widget.alignment.y + 1) * maxHeight / 2),
      );
      c.complete(sphereImage);
    });
    return c.future;
  }

  /// Load the surface image
  void loadSurface(
    ImageProvider image,
    ImageConfiguration configuration,
  ) {
    image.resolve(configuration).addListener(
      ImageStreamListener(
        (info, call) {
          info.image.toByteData(format: ui.ImageByteFormat.rawRgba).then(
            (pixels) {
              surface = pixels!.buffer.asUint32List();
              surfaceWidth = info.image.width.toDouble();
              surfaceHeight = info.image.height.toDouble();
              setState(() {});
            },
          );
        },
      ),
    );
  }

  /// Handle tap event
  onTapEvent(TapDownDetails details) {
    setState(() {
      clickPoint = details.localPosition;
    });
  }

  /// Handle hover event
  onHover(PointerEvent event) {
    setState(() {
      hoveringPoint = event.localPosition;
    });
  }

  /// Load the background image
  void loadBackground(
    ImageProvider image,
    ImageConfiguration configuration,
    bool followsRotation,
  ) {
    image.resolve(configuration).addListener(
      ImageStreamListener(
        (info, call) {
          setState(() {
            backgroundFollowsRotation = followsRotation;
            backgroundImage = info.image;
          });
        },
      ),
    );
  }

  /// Remove the background image
  void removeBackground() {
    setState(() {
      backgroundImage = null;
      backgroundFollowsRotation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      trackpadScrollCausesScale: true,
      panEnabled: false,
      scaleFactor: 1000,
      onInteractionStart: (ScaleStartDetails details) {
        _lastZoom = zoom;
        _lastRotationX = rotationX;
        _lastRotationZ = rotationZ;
        _lastRotationY = rotationY;
        _lastFocalPoint = details.focalPoint;

        if (widget.controller.isRotating) {
          _rotationController.stop();
        }
        // _rotationController.stop();
      },
      onInteractionUpdate: (ScaleUpdateDetails details) {
        zoom = _lastZoom + math.log(details.scale) / math.ln2;
        // print(zoom);
        if (zoom < 0.4) {
          zoom = 0.4;
        } else if (zoom > 1.6) {
          zoom = 1.6;
        }
        final offset = details.focalPoint - _lastFocalPoint;
        rotationX = adjustModRotation(_lastRotationX + offset.dy / radius);
        rotationZ = adjustModRotation(_lastRotationZ - offset.dx / radius);
        rotationY = adjustModRotation(_lastRotationY + offset.dy / radius);
        // final offset = details.focalPoint - _lastFocalPoint;
        // print(rotationY);
        setState(() {});
      },
      onInteractionEnd: (ScaleEndDetails details) {
        final offset = details.velocity.pixelsPerSecond / 50;
        _angularVelocityX = offset.dy / radius;
        _angularVelocityY = offset.dy / radius;
        _angularVelocityZ = -offset.dx / radius;
        _decelerationController.forward(from: 0.0);

        if (widget.controller.isRotating) {
          _rotationController.forward(from: _rotationController.value);
        }
      },
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            children: [
              backgroundImage == null
                  ? Container()
                  : CustomPaint(
                      painter: StarryBackgroundPainter(
                        starTexture: backgroundImage!,
                        rotationX: backgroundFollowsRotation
                            ? rotationZ * (radius / math.pi)
                            : 0,
                        rotationY: backgroundFollowsRotation
                            ? rotationY * (radius / math.pi)
                            : 0,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight)),
              FutureBuilder(
                key: _futureBuilderKey,
                future:
                    buildSphere(constraints.maxWidth, constraints.maxHeight),
                builder: (BuildContext context,
                    AsyncSnapshot<SphereImage> snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data!;
                    return GestureDetector(
                      onTapDown: onTapEvent,
                      child: Listener(
                        onPointerHover: onHover,
                        child: CustomPaint(
                          foregroundPainter: ForegroundPainter(
                            hoverOverConnection: (connectionId, cartesian2D,
                                isHovering, isVisible) {
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
                            hoverOverPoint:
                                (pointId, cartesian2D, isHovering, isVisisble) {
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
                            radius: radius,
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
                            zoomFactor: zoom,
                            points: widget.controller.points,
                          ),
                          painter: SpherePainter(
                            style: widget.controller.sphereStyle,
                            sphereImage: data,
                          ),
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
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

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final box = e.value.key.currentContext
                              ?.findRenderObject() as RenderBox?;
                          if ((e.value.size?.height != box?.size.height ||
                                  e.value.size?.width != box?.size.width) &&
                              box?.size != null) {
                            visiblePoints.update(
                                e.key,
                                (value) => value.copyWith(
                                      size: box?.size,
                                    ));
                            setState(() {});
                          }
                        });

                        double width = e.value.size?.width ?? 0;
                        double height = e.value.size?.height ?? 0;
                        return Positioned(
                            key: e.value.key,
                            left: pos.dx - point.labelOffset.dx - (width / 2),
                            top: pos.dy - point.labelOffset.dy - height,
                            child: point.labelBuilder!(context, point,
                                    e.value.isHovering, e.value.isVisible) ??
                                Container());
                      },
                    )
                    .whereType<Widget>()
                    .toList(),
              if (visibleConnections.isNotEmpty)
                ...visibleConnections.entries
                    .map(
                      (e) {
                        final connection = widget.controller.connections
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

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final box = e.value.key.currentContext
                              ?.findRenderObject() as RenderBox?;
                          if ((e.value.size?.height != box?.size.height ||
                                  e.value.size?.width != box?.size.width) &&
                              box?.size != null) {
                            visibleConnections.update(
                                e.key,
                                (value) => value.copyWith(
                                      size: box?.size,
                                    ));
                            setState(() {});
                          }
                        });

                        double width = e.value.size?.width ?? 0;
                        double height = e.value.size?.height ?? 0;
                        return Positioned(
                            key: e.value.key,
                            left: pos.dx -
                                connection.labelOffset.dx -
                                (width / 2),
                            top: pos.dy - connection.labelOffset.dy - height,
                            child: connection.labelBuilder!(context, connection,
                                    e.value.isHovering, e.value.isVisible) ??
                                Container());
                      },
                    )
                    .whereType<Widget>()
                    .toList(),
            ],
          );
        },
      ),
    );
  }
}
