library flutter_earth_globe;

import 'rotating_globe.dart';
import 'package:flutter/material.dart';

import 'rotating_globe_controller.dart';

/// This is the main widget of the package. It is a sphere that can be rotated and animated.
class FlutterEarthGlobe extends StatefulWidget {
  final double radius;
  final Alignment alignment;
  final RotatingGlobeController controller;
  const FlutterEarthGlobe({
    Key? key,
    required this.radius,
    required this.controller,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  _FlutterEarthGlobeState createState() => _FlutterEarthGlobeState();
}

class _FlutterEarthGlobeState extends State<FlutterEarthGlobe> {
  @override
  Widget build(BuildContext context) {
    return Sphere(
      controller: widget.controller,
      radius: widget.radius,
      alignment: widget.alignment,
    );
  }
}
