import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'foreground_painter.dart';
import 'math_helper.dart';
import 'point_connection.dart';
import 'rotating_globe_controller.dart';
import 'sphere_image.dart';
import 'sphere_painter.dart';
import 'package:flutter/material.dart';

import 'point_connection_style.dart';
import 'starry_background_painter.dart';

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

class _SphereState extends State<Sphere> with TickerProviderStateMixin {
  late Uint32List surface;
  ui.Image? backgroundImage;
  bool backgroundFollowsRotation = false;
  String? surfacePath;
  double? surfaceWidth;
  double? surfaceHeight;
  late double zoom = 1;
  late double rotationX = 0;
  late double rotationZ = 0;
  late double _lastZoom;
  late double _lastRotationX;
  late double _lastRotationZ;
  late double rotationY = 0; // Add Y-axis rotation variable
  late double _lastRotationY; // Add a variable to store the last Y rotation
  final GlobalKey _futureBuilderKey = GlobalKey();

  late Offset _lastFocalPoint;
  late AnimationController _rotationController;
  late AnimationController _lineMovingController;

  double _angularVelocityX = 0.0;
  double _angularVelocityY = 0.0;
  double _angularVelocityZ = 0.0;
  late AnimationController _decelerationController;

  List<AnimatedPointConnection> _connections = [];
  // late MapTileProvider _mapTileProvider; // Provider for map tiles

  double get radius => widget.radius * math.pow(2, zoom);

  Offset? hoveringPoint;
  Offset? clickPoint;

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

    widget.controller.onPointConnectionRemoved = _removeConnection;
    widget.controller.onPointConnectionUpdated = _updateConnection;

    widget.controller.onPointAdded = _refresh;
    widget.controller.onPointRemoved = _refresh;
    widget.controller.onPointUpdated = _refresh;

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
        for (var connection in _connections) {
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

  void startRotation() {
    if (!widget.controller.isRotating) {
      widget.controller.isRotating = true;
      _rotationController.forward();
      setState(() {});
    }
  }

  void stopRotation() {
    if (widget.controller.isRotating) {
      widget.controller.isRotating = false;
      _rotationController.stop();
      setState(() {});
    }
  }

  void toggleRotation() {
    if (widget.controller.isRotating) {
      stopRotation();
    } else {
      startRotation();
    }
  }

  void resetRotation() {
    rotationX = 0;
    rotationY = 0; // Reset rotationY
    rotationZ = 0;
    setState(() {});
  }

  _refresh() {
    setState(() {});
  }

  // _addPoint(Point point) {
  //   Future.delayed(Duration.zero, () {
  //     setState(() {
  //       _points.add(point);
  //     });
  //   });
  // }

  // _removePoint(String id) {
  //   // _points.removeWhere((element) => element.id == id);
  //   setState(() {
  //     _points = _points;
  //   });
  // }

  // _updatePoint(String id,
  //     {String? title,
  //     bool? isTitleVisible,
  //     PointStyle? style,
  //     TextStyle? textStyle,
  //     bool? showTitleOnHover}) {
  //   final index = _points.indexWhere((element) => element.id == id);
  //   if (index >= 0) {
  //     Future.delayed(Duration.zero, () {
  //       setState(() {
  //         _points[index] = _points[index].copyWith(
  //           title: title,
  //           isTitleVisible: isTitleVisible,
  //           style: style,
  //           textStyle: textStyle,
  //           showTitleOnHover: showTitleOnHover,
  //         );
  //       });
  //     });
  //   }
  // }

  _updateConnection(
    String id, {
    String? title,
    TextStyle? textStyle,
    bool? isTitleVisible,
    bool? showTitleOnHover,
    bool? isMoving,
    PointConnectionStyle? style,
  }) {
    final index = _connections.indexWhere((element) => element.id == id);
    if (index >= 0) {
      Future.delayed(Duration.zero, () {
        setState(() {
          _connections[index] = _connections[index].copyWith(
            title: title,
            isTitleVisible: isTitleVisible,
            textStyle: textStyle,
            showTitleOnHover: showTitleOnHover,
            isMoving: isMoving,
            style: style,
          );
        });
      });
    }
  }

  _addConnection(PointConnection connection,
      {required bool animateDraw, required Duration animateDrawDuration}) {
    final animatedConnection = AnimatedPointConnection.fromMap({
      ...connection.toMap(),
      'animationProgress': animateDraw ? 0.0 : 1.0,
    }, connection.onTap, connection.onHover);
    setState(() {
      _connections.add(animatedConnection);
    });

    if (animateDraw) {
      final animation = AnimationController(
        vsync: this,
        duration: animateDrawDuration,
      )..forward();

      Tween<double>(begin: 0.0, end: 1.0).animate(animation).addListener(() {
        setState(() {
          animatedConnection.animationProgress = animation.value;
        });
      });
    }
  }

  _removeConnection(String id) {
    _connections.removeWhere((element) => element.id == id);
    setState(() {
      _connections = _connections;
    });
  }

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

  onTapEvent(TapDownDetails details) {
    setState(() {
      clickPoint = details.localPosition;
    });
  }

  onHover(PointerEvent event) {
    setState(() {
      hoveringPoint = event.localPosition;
    });
  }

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
                            connections: _connections,
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
            ],
          );
        },
      ),
    );
  }
}
