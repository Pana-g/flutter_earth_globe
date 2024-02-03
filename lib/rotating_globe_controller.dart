import 'point.dart';
import 'sphere_style.dart';
import 'package:flutter/material.dart';

import 'point_connection.dart';

import 'point_connection_style.dart';

/// This class is the controller of the [RotatingGlobe] widget.
///
/// It is used to add/remove/update points and connections.
/// It is also used to control the rotation of the globe.
/// It is also used to load the surface and background images.
/// It is also used to change the style of the sphere.
/// It is also used to listen to the events of the globe.
class RotatingGlobeController {
  bool _isRotating = false;
  bool _isReady = false;
  List<Point> points = [];
  List<AnimatedPointConnection> connections = [];
  SphereStyle sphereStyle = SphereStyle();

  // internal calls
  Function(AnimatedPointConnection connection,
      {required bool animateDraw,
      required Duration animateDrawDuration})? onPointConnectionAdded;
  Function()? onPointConnectionRemoved;

  Function()? onPointConnectionUpdated;

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
    onPointConnectionAdded?.call(animatedConnection,
        animateDraw: animateDraw, animateDrawDuration: animateDrawDuration);
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
    onPointConnectionUpdated?.call();
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
    onPointConnectionRemoved?.call();
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
    onPointAdded?.call();
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
    onPointUpdated?.call();
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
    onPointRemoved?.call();
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
    if (onSurfaceLoaded == null) return;
    onSurfaceLoaded?.call(image, configuration);
  }

  /// Loads the background image for the rotating globe.
  ///
  /// The [image] parameter specifies the image to be loaded as the background.
  /// The [configuration] parameter specifies the configuration for loading the image.
  /// The [followsRotation] parameter indicates whether the background image should follow the rotation of the globe.
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
    bool followsRotation = false,
  }) {
    if (onBackgroundLoaded == null) return;
    onBackgroundLoaded?.call(image, configuration, followsRotation);
  }

  /// Removes the background of the rotating globe.
  ///
  /// This method calls the [onBackgroundRemoved] callback if it is not null.
  /// The [onBackgroundRemoved] callback is responsible for handling the removal
  /// of the background.
  ///
  /// Example usage:
  /// ```dart
  /// controller.removeBackground();
  /// ```

  void removeBackground() {
    if (onBackgroundRemoved == null) return;
    onBackgroundRemoved?.call();
  }

  /// Changes the style of the rotating globe's sphere.
  ///
  /// The [style] parameter specifies the new style for the sphere.
  ///
  /// Example usage:
  /// ```dart
  /// RotatingGlobeController controller = RotatingGlobeController();
  /// controller.changeSphereStyle(SphereStyle(color: Colors.blue, radius: 100));
  /// ```
  void changeSphereStyle(SphereStyle style) {
    if (onChangeSphereStyle == null) return;
    sphereStyle = style;
    onChangeSphereStyle?.call();
  }

  /// Starts the rotation of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// RotatingGlobeController controller = RotatingGlobeController();
  /// controller.startRotation();
  /// ```
  void startRotation() {
    onStartGlobeRotation?.call();
    _isRotating = true;
  }

  /// Stops the rotation of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// RotatingGlobeController controller = RotatingGlobeController();
  /// controller.stopRotation();
  /// ```
  void stopRotation() {
    onStopGlobeRotation?.call();
    _isRotating = false;
  }

  /// Toggles the rotation of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// RotatingGlobeController controller = RotatingGlobeController();
  /// controller.toggleRotation();
  /// ```
  void toggleRotation() {
    onToggleGlobeRotation?.call();
    _isRotating = !_isRotating;
  }

  /// Resets the rotation of the globe.
  ///
  /// Example usage:
  /// ```dart
  /// RotatingGlobeController controller = RotatingGlobeController();
  /// controller.resetRotation();
  /// ```
  void resetRotation() {
    onResetGlobeRotation?.call();
  }

  /// A callback function that is called when the globe is loaded.
  VoidCallback? onLoaded;

  /// Disposes the controller.
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
