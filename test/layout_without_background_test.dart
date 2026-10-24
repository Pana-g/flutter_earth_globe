import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/rotating_globe.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Quick Start layout from the README, without a background image.
Future<FlutterEarthGlobeController> pumpQuickStartWithoutBackground(
    WidgetTester tester) async {
  // Not disposed here: the globe's state disposes the controller's
  // animation controllers when it unmounts.
  final controller = FlutterEarthGlobeController(isRotating: false);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: FlutterEarthGlobe(controller: controller, radius: 120),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
  return controller;
}

void main() {
  testWidgets('a globe without a background fills the space it is given',
      (WidgetTester tester) async {
    await pumpQuickStartWithoutBackground(tester);

    // The test view has no system insets, so the SafeArea is the whole body.
    expect(
      tester.getSize(find.byType(FlutterEarthGlobe)),
      tester.getSize(find.byType(Scaffold)),
    );
  });

  testWidgets('a globe without a background can be dragged',
      (WidgetTester tester) async {
    await pumpQuickStartWithoutBackground(tester);
    final state =
        tester.state<RotatingGlobeState>(find.byType(RotatingGlobe));

    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(Scaffold)));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(8, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();

    expect(state.rotationZ, isNot(0.0));
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a globe without a background still lays out in a Column',
      (WidgetTester tester) async {
    // Unbounded height: keep today's behaviour instead of throwing.
    final controller = FlutterEarthGlobeController(isRotating: false);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            FlutterEarthGlobe(controller: controller, radius: 120),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
