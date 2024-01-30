import 'point.dart';
import 'sphere_style.dart';
import 'package:flutter/material.dart';

import 'point_connection.dart';

import 'point_connection_style.dart';

/// This class is the controller of the [RotatingGlobe] widget.
/// It is used to add/remove/update points and connections.
/// It is also used to control the rotation of the globe.
/// It is also used to load the surface and background images.
/// It is also used to change the style of the sphere.
class RotatingGlobeController {
  bool _isRotating = false;
  bool _isReady = false;
  List<Point> points = [];
  List<PointConnection> connections = [];
  SphereStyle sphereStyle = SphereStyle();

  // internal calls
  Function(PointConnection connection,
      {required bool animateDraw,
      required Duration animateDrawDuration})? onPointConnectionAdded;
  Function(
    String id,
  )? onPointConnectionRemoved;

  Function(
    String id, {
    String? title,
    TextStyle? textStyle,
    bool? isTitleVisible,
    bool? showTitleOnHover,
    bool? isMoving,
    PointConnectionStyle? style,
  })? onPointConnectionUpdated;

  Function()? onPointAdded;

  Function()? onPointUpdated;

  Function()? onPointRemoved;

  Function(
    ImageProvider image,
    ImageConfiguration configuration,
  )? onSurfaceLoaded;

  Function(
    ImageProvider image,
    ImageConfiguration configuration,
    bool followsRotation,
  )? onBackgroundLoaded;

  Function()? onBackgroundRemoved;
  Function()? onChangeSphereStyle;

  Function()? onStartGlobeRotation;
  Function()? onStopGlobeRotation;
  Function()? onToggleGlobeRotation;
  Function()? onResetGlobeRotation;
  void load() {
    _isReady = true;
    onLoaded?.call();
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
    onPointConnectionAdded?.call(connection,
        animateDraw: animateDraw, animateDrawDuration: animateDrawDuration);

    connections.add(connection);
  }

  /// Updates the [connection] between two [points] on the globe.
  ///
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
    String? title,
    TextStyle? textStyle,
    bool? isTitleVisible,
    bool? isMoving,
    PointConnectionStyle? style,
  }) {
    onPointConnectionUpdated?.call(id,
        title: title,
        textStyle: textStyle,
        isTitleVisible: isTitleVisible,
        isMoving: isMoving,
        style: style);
    connections.firstWhere((element) => element.id == id).copyWith(
        title: title,
        textStyle: textStyle,
        isTitleVisible: isTitleVisible,
        isMoving: isMoving,
        style: style);
  }

  /// Removes the [connection] between two [points] from the globe.
  ///
  /// ```dart
  ///  controller.removePointConnection('id');
  /// ```
  void removePointConnection(String id) {
    onPointConnectionRemoved?.call(id);
    connections.removeWhere((element) => element.id == id);
  }

  /// Adds a [point] to the globe.
  ///
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
    onPointAdded?.call();
    points.add(point);
  }

  /// Updates the [point] on the globe.
  ///
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
    String? title,
    bool? isTitleVisible,
    bool? showTitleOnHover,
    PointStyle? style,
    TextStyle? textStyle,
  }) {
    onPointUpdated?.call();
    points.firstWhere((element) => element.id == id).copyWith(
        title: title,
        isTitleVisible: isTitleVisible,
        showTitleOnHover: showTitleOnHover,
        style: style,
        textStyle: textStyle);
  }

  void removePoint(String id) {
    onPointRemoved?.call();
    points.removeWhere((element) => element.id == id);
  }

  void loadSurface(
    ImageProvider image, {
    ImageConfiguration configuration = const ImageConfiguration(),
  }) {
    if (onSurfaceLoaded == null) return;
    onSurfaceLoaded?.call(image, configuration);
  }

  void loadBackground(
    ImageProvider image, {
    ImageConfiguration configuration = const ImageConfiguration(),
    bool followsRotation = false,
  }) {
    if (onBackgroundLoaded == null) return;
    onBackgroundLoaded?.call(image, configuration, followsRotation);
  }

  void removeBackground() {
    if (onBackgroundRemoved == null) return;
    onBackgroundRemoved?.call();
  }

  void changeSphereStyle(SphereStyle style) {
    if (onChangeSphereStyle == null) return;
    sphereStyle = style;
    onChangeSphereStyle?.call();
  }

  void startRotation() {
    onStartGlobeRotation?.call();
    _isRotating = true;
  }

  void stopRotation() {
    onStopGlobeRotation?.call();
    _isRotating = false;
  }

  void toggleRotation() {
    onToggleGlobeRotation?.call();
    _isRotating = !_isRotating;
  }

  void resetRotation() {
    onResetGlobeRotation?.call();
  }

  VoidCallback? onLoaded;

  void dispose() {
    onPointConnectionAdded = null;
    onPointConnectionRemoved = null;
    onPointConnectionUpdated = null;
    onPointAdded = null;
    onPointRemoved = null;
    onPointUpdated = null;
    onStartGlobeRotation = null;
    onStopGlobeRotation = null;
    onToggleGlobeRotation = null;
    onResetGlobeRotation = null;
    onSurfaceLoaded = null;
    onBackgroundLoaded = null;
    onBackgroundRemoved = null;
    onChangeSphereStyle = null;
    onLoaded = null;
  }
}
