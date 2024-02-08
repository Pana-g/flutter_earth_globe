library flutter_earth_globe;

import 'globe_coordinates.dart';
import 'rotating_globe.dart';
import 'package:flutter/material.dart';

import 'flutter_earth_globe_controller.dart';

/// This is the main widget of the package. It is a sphere that can be rotated and animated.
class FlutterEarthGlobe extends StatefulWidget {
  final double radius;
  final Alignment alignment;
  final FlutterEarthGlobeController controller;
  final void Function(double zoom)? onZoomChanged;

  final void Function(GlobeCoordinates? coordinates)? onHover;

  final void Function(GlobeCoordinates? coordinates)? onTap;

  /// The [FlutterEarthGlobe] widget represents a 3D sphere that simulates the Earth globe. It can be rotated and animated using the provided [FlutterEarthGlobeController].
  ///
  /// The [radius] parameter specifies the radius of the sphere.
  /// The [alignment] parameter specifies the alignment of the sphere within its parent widget. By default, it is centered.
  /// The [controller] parameter is responsible for controlling the rotation and animation of the globe.
  /// The [onZoomChanged] parameter is a callback function that is called when the zoom level of the globe changes.
  /// The [onHover] parameter is a callback function that is called when the user hovers over a point on the globe.
  /// The [onTap] parameter is a callback function that is called when the user taps on a point on the globe.
  ///
  /// Example usage:
  /// ```dart
  /// FlutterEarthGlobe(
  ///  radius: 200,
  /// controller: FlutterEarthGlobeController(),
  /// onZoomChanged: (zoom) {
  /// print('Zoom level: $zoom');
  /// },
  /// onHover: (coordinates) {
  /// print('Hovering over coordinates: $coordinates');
  /// },
  /// )
  /// ```
  const FlutterEarthGlobe({
    Key? key,
    required this.radius,
    required this.controller,
    this.alignment = Alignment.center,
    this.onZoomChanged,
    this.onHover,
    this.onTap,
  }) : super(key: key);

  @override
  _FlutterEarthGlobeState createState() => _FlutterEarthGlobeState();
}

class _FlutterEarthGlobeState extends State<FlutterEarthGlobe> {
  @override
  Widget build(BuildContext context) {
    return RotatingGlobe(
      controller: widget.controller,
      radius: widget.radius,
      alignment: widget.alignment,
      onZoomChanged: widget.onZoomChanged,
      onHover: widget.onHover,
      onTap: widget.onTap,
    );
  }
}
