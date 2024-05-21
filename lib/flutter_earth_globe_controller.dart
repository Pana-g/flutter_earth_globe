import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/misc.dart';
import 'package:flutter_earth_globe/rotating_globe.dart';

import 'globe_coordinates.dart';
import 'point.dart';
import 'sphere_style.dart';

import 'point_connection.dart';

import 'point_connection_style.dart';

/// This class is the controller of the [RotatingGlobe] widget.
///
/// It is used to add/remove/update points and connections.
/// It is also used to control the rotation of the globe.
/// It is also used to load the surface and background images.
/// It is also used to set the style of the sphere.
/// It is also used to listen to the events of the globe.
class FlutterEarthGlobeController extends ChangeNotifier {
  bool _isRotating = false; // Whether the globe is rotating.
  bool _isReady = false; // Whether the globe is ready.
  List<Point> points = []; // The points on the globe.
  List<AnimatedPointConnection> connections =
      []; // The connections between points.
  SphereStyle sphereStyle; // The style of the sphere.
  ui.Image? surface; // The surface image of the sphere.
  ui.Image? background; // The background image of the sphere.
  Uint32List? surfaceProcessed; // The processed surface image of the sphere.
  bool
      isBackgroundFollowingSphereRotation; // Whether the background follows the rotation of the sphere.
  ImageConfiguration
      surfaceConfiguration; // The configuration of the surface image.
  ImageConfiguration
      backgroundConfiguration; // The configuration of the background image.

  late AnimationController
      rotationController; // The animation controller for sphere rotation.

  double rotationSpeed; // The speed of the rotation.

  double zoom; // The zoom level of the globe.
  double maxZoom; // The maximum zoom level of the globe.
  double minZoom; // The minimum zoom level of the globe.
  bool isZoomEnabled; // Whether the zoom is enabled.

  GlobalKey<RotatingGlobeState> globeKey = GlobalKey();

  FlutterEarthGlobeController({
    ImageProvider? surface,
    ImageProvider? background,
    this.rotationSpeed = 0.2,
    this.isZoomEnabled = true,
    this.zoom = 1,
    this.maxZoom = 1.6,
    this.minZoom = 0.1,
    bool isRotating = false,
    this.isBackgroundFollowingSphereRotation = false,
    this.surfaceConfiguration = const ImageConfiguration(),
    this.backgroundConfiguration = const ImageConfiguration(),
    this.sphereStyle = const SphereStyle(),
  }) {
    assert(minZoom < maxZoom);
    assert(zoom >= minZoom && zoom <= maxZoom);
    _isRotating = isRotating;
    if (surface != null) {
      loadSurface(surface);
    }

    if (background != null) {
      loadBackground(background);
    }
  }

  // internal calls
  Function(AnimatedPointConnection connection,
      {required bool animateDraw,
      required Duration animateDrawDuration})? onPointConnectionAdded;

  Function()? onResetGlobeRotation;

  void load() {
    _isReady = true;
    onLoaded?.call();
    if (_isRotating) {
      startRotation();
    }
  }

  // external calls

  /// Returns true if the globe is rotating
  bool get isRotating => _isRotating;

  /// Sets the rotation of the globe
  set isRotating(bool value) => _isRotating;

  /// Returns true if the globe is ready
  bool get isReady => _isReady;

  /// Adds a [connection] between two [points] to the globe.
  ///
  /// The [connection] parameter represents the connection to be added to the globe.
  /// The [animateDraw] parameter represents whether the connection should be animated when drawn.
  /// The [animateDrawDuration] parameter represents the duration of the animation when drawing the connection.
  ///
  /// Example usage:
  /// ```dart
  /// controller.addPointConnection(PointConnection(
  ///   start: GlobeCoordinates(0, 0),
  ///   end: GlobeCoordinates(0, 0),
  ///   id: 'id',
  ///   title: 'title',
  ///   isTitleVisible: true,
  ///   showTitleOnHover: true,
  ///   isMoving: true),
  ///   animateDraw: true,
  ///  );
  /// ```
  void addPointConnection(PointConnection connection,
      {bool animateDraw = false,
      Duration animateDrawDuration = const Duration(seconds: 2)}) {
    final animatedConnection = AnimatedPointConnection.fromPointConnection(
        pointConnection: connection);
    connections.add(animatedConnection);
    notifyListeners();
    onPointConnectionAdded?.call(animatedConnection,
        animateDraw: animateDraw, animateDrawDuration: animateDrawDuration);
  }

  /// Focuses on the [coordinates] on the globe.
  ///
  /// The [coordinates] parameter represents the coordinates to focus on.
  /// The [animate] parameter represents whether the focus should be animated.
  /// The [duration] parameter represents the duration of the animation.
  ///
  /// Example usage:
  /// ```dart
  /// controller.focusOnCoordinates(GlobeCoordinates(0, 0), animate: true);
  /// ```
  void focusOnCoordinates(GlobeCoordinates coordinates,
      {bool animate = false,
      Duration? duration = const Duration(milliseconds: 500)}) {
    globeKey.currentState
        ?.focusOnCoordinates(coordinates, animate: animate, duration: duration);
  }

  /// Updates the [connection] between two [points] on the globe.
  ///
  /// The [id] parameter represents the id of the connection to be updated.
  /// The [label] parameter represents the label of the connection.
  /// The [labelBuilder] parameter represents the builder of the label of the connection.
  /// The [isLabelVisible] parameter represents the visibility of the label of the connection.
  /// The [labelOffset] parameter represents the offset of the label from the connection line.
  /// The [isMoving] parameter represents whether the connection is currently moving.
  /// The [style] parameter represents the style of the connection line.
  /// The [labelTextStyle] parameter represents the text style of the label.
  /// The [onTap] parameter is a callback function that is called when the connection is tapped.
  /// The [onHover] parameter is a callback function that is called when the connection is hovered over.
  ///
  /// Example usage:
  /// ```dart
  /// controller.updatePointConnection('id',
  ///   title: 'title',
  ///   textStyle: TextStyle(color: Colors.red),
  ///   isTitleVisible: true,
  ///   isMoving: true,
  ///   style: PointConnectionStyle(color: Colors.red),
  ///  );
  /// ```
  void updatePointConnection(
    String id, {
    String? label,
    Widget? Function(BuildContext context, PointConnection pointConnection,
            bool isHovering, bool isVisible)?
        labelBuilder,
    bool? isLabelVisible,
    Offset? labelOffset,
    bool? isMoving,
    PointConnectionStyle? style,
    TextStyle? labelTextStyle,
    VoidCallback? onTap,
    VoidCallback? onHover,
  }) {
    connections.firstWhere((element) => element.id == id).copyWith(
        label: label,
        isMoving: isMoving,
        labelBuilder: labelBuilder,
        isLabelVisible: isLabelVisible,
        labelOffset: labelOffset,
        style: style,
        labelTextStyle: labelTextStyle,
        onTap: onTap,
        onHover: onHover);
    notifyListeners();
  }

  /// Removes the [connection] between two [points] from the globe.
  ///
  /// The [id] parameter represents the id of the connection to be removed.
  ///
  /// Example usage:
  /// ```dart
  ///  controller.removePointConnection('id');
  /// ```
  void removePointConnection(String id) {
    connections.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  /// Adds a [point] to the globe.
  ///
  /// The [point] parameter represents the point to be added to the globe.
  ///
  /// Example usage:
  /// ```dart
  /// controller.addPoint(Point(
  ///  coordinates: GlobeCoordinates(0, 0),
  /// id: 'id',
  /// title: 'title',
  /// isTitleVisible: true,
  /// showTitleOnHover: true,
  /// style: PointStyle(color: Colors.red),
  /// textStyle: TextStyle(color: Colors.red),
  /// onTap: () {},
  /// onHover: () {},
  /// ));
  /// ```
  void addPoint(Point point) {
    points.add(point);
    notifyListeners();
  }

  /// Updates the [point] on the globe.
  ///
  /// The [id] parameter represents the id of the point to be updated.
  /// The [label] parameter represents the label of the point.
  /// The [labelBuilder] parameter represents the builder of the label of the point.
  /// The [isLabelVisible] parameter represents the visibility of the label of the point.
  /// The [labelOffset] parameter represents the offset of the label from the point.
  /// The [style] parameter represents the style of the point.
  /// The [labelTextStyle] parameter represents the text style of the label.
  /// The [onTap] parameter is a callback function that is called when the point is tapped.
  /// The [onHover] parameter is a callback function that is called when the point is hovered over.
  ///
  /// Example usage:
  /// ```dart
  ///  controller.updatePoint('id',
  ///  title: 'title',
  /// textStyle: TextStyle(color: Colors.red),
  /// isTitleVisible: true,
  /// showTitleOnHover: true,
  /// style: PointStyle(color: Colors.red),
  /// );
  /// ```
  void updatePoint(
    String id, {
    String? label,
    Widget? Function(
            BuildContext context, Point point, bool isHovering, bool isVisible)?
        labelBuilder,
    bool? isLabelVisible,
    Offset? labelOffset,
    PointStyle? style,
    TextStyle? labelTextStyle,
    VoidCallback? onTap,
    VoidCallback? onHover,
  }) {
    points.firstWhere((element) => element.id == id).copyWith(
        label: label,
        labelBuilder: labelBuilder,
        isLabelVisible: isLabelVisible,
        labelOffset: labelOffset,
        style: style,
        labelTextStyle: labelTextStyle,
        onTap: onTap,
        onHover: onHover);
    notifyListeners();
  }

  /// Removes the [point] from the globe.
  ///
  /// The [id] parameter represents the id of the point to be removed.
  ///
  /// Example usage:
  /// ```dart
  /// controller.removePoint('id');
  /// ```
  void removePoint(String id) {
    points.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  /// Loads the [image] as the surface of the globe.
  ///
  /// The [image] parameter represents the image to be loaded as the surface of the globe.
  /// The [configuration] parameter is optional and can be used to customize the image configuration.
  ///
  /// Example usage:
  /// ```dart
  /// controller.loadSurface(
  ///  AssetImage('assets/earth.jpg'),
  /// );
  /// ```
  void loadSurface(
    ImageProvider image, {
    ImageConfiguration configuration = const ImageConfiguration(),
  }) {
    image
        .resolve(configuration)
        .addListener(ImageStreamListener((info, _) async {
      surface = info.image;
      surfaceConfiguration = configuration;
      surfaceProcessed = await convertImageToUint32List(info.image);
      notifyListeners();
    }));
  }

  /// Loads the background image for the rotating globe.
  ///
  /// The [image] parameter specifies the image to be loaded as the background.
  /// The [configuration] parameter specifies the configuration for loading the image.
  /// The [isBackgroundFollowingSphereRotation] parameter specifies whether the background should follow the rotation of the sphere.
  ///
  /// Example usage:
  /// ```dart
  /// controller.loadBackground(
  /// AssetImage('assets/background.jpg'),
  /// );
  /// ```
  void loadBackground(
    ImageProvider image, {
    ImageConfiguration configuration = const ImageConfiguration(),
    bool isBackgroundFollowingSphereRotation = false,
  }) {
    image.resolve(configuration).addListener(ImageStreamListener((info, _) {
      background = info.image;
      backgroundConfiguration = configuration;
      isBackgroundFollowingSphereRotation = isBackgroundFollowingSphereRotation;
      notifyListeners();
    }));
  }

  /// Removes the background of the rotating globe.
  ///
  /// Example usage:
  /// ```dart
  /// controller.removeBackground();
  /// ```

  void removeBackground() {
    background = null;
    notifyListeners();
  }

  /// Sets the style of the rotating globe's sphere.
  ///
  /// The [style] parameter specifies the new style for the sphere.
  ///
  /// Example usage:
  /// ```dart
  /// FlutterEarthGlobeController controller = FlutterEarthGlobeController();
  /// controller.setSphereStyle(SphereStyle(color: Colors.blue, radius: 100));
  /// ```
  void setSphereStyle(SphereStyle style) {
    sphereStyle = style;
    notifyListeners();
  }

  /// Starts the rotation of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// FlutterEarthGlobeController controller = FlutterEarthGlobeController();
  /// controller.startRotation();
  /// ```
  void startRotation({double? rotationSpeed}) {
    _isRotating = true;
    this.rotationSpeed = rotationSpeed ?? this.rotationSpeed;
    rotationController.forward();
    notifyListeners();
  }

  /// Stops the rotation of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// FlutterEarthGlobeController controller = FlutterEarthGlobeController();
  /// controller.stopRotation();
  /// ```
  void stopRotation() {
    _isRotating = false;
    rotationController.stop();
    notifyListeners();
  }

  /// Toggles the rotation of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// FlutterEarthGlobeController controller = FlutterEarthGlobeController();
  /// controller.toggleRotation();
  /// ```
  void toggleRotation() {
    _isRotating = !_isRotating;
    if (_isRotating) {
      rotationController.forward();
    } else {
      rotationController.stop();
    }
    notifyListeners();
  }

  /// Resets the rotation of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// FlutterEarthGlobeController controller = FlutterEarthGlobeController();
  /// controller.resetRotation();
  /// ```
  void resetRotation() {
    onResetGlobeRotation?.call();
  }

  /// Sets the rotation speed of the globe.
  ///
  /// The [rotationSpeed] parameter specifies the new rotation speed of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// FlutterEarthGlobeController controller = FlutterEarthGlobeController();
  /// controller.setRotationSpeed(0.5);
  /// ```
  void setRotationSpeed(double rotationSpeed) {
    this.rotationSpeed = rotationSpeed;
    notifyListeners();
  }

  /// Sets the zoom level of the globe.
  ///
  /// The [zoom] parameter specifies the new zoom level of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// FlutterEarthGlobeController controller = FlutterEarthGlobeController();
  /// controller.setZoom(2);
  /// ```
  void setZoom(double zoom) {
    assert(zoom >= minZoom && zoom <= maxZoom);
    if (zoom < minZoom) {
      zoom = minZoom;
    } else if (zoom > maxZoom) {
      zoom = maxZoom;
    } else {
      this.zoom = zoom;
    }
    notifyListeners();
  }

  /// A callback function that is called when the globe is loaded.
  VoidCallback? onLoaded;

  /// Disposes the controller.
  @override
  void dispose() {
    onPointConnectionAdded = null;
    onResetGlobeRotation = null;
    onLoaded = null;
    rotationController.dispose();
    super.dispose();
  }
}
