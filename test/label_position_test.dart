import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/rotating_globe.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a globe with a surface texture and one labelled point facing the
/// camera. Image decoding and shader loading are real async work, so they
/// run under [WidgetTester.runAsync].
Future<FlutterEarthGlobeController> pumpGlobeWithLabel(
    WidgetTester tester) async {
  // Not disposed here: the globe's state disposes the controller's
  // animation controllers when it unmounts.
  final controller = FlutterEarthGlobeController(isRotating: false);
  controller.addPoint(Point(
    id: 'p',
    coordinates: const GlobeCoordinates(0, 0),
    isLabelVisible: true,
    labelBuilder: (context, point, isHovering, isVisible) =>
        const Text('label'),
  ));

  await tester.runAsync(() async {
    final image = await createTestImage(width: 64, height: 32);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    controller.loadSurface(MemoryImage(png!.buffer.asUint8List()));
    for (var i = 0; i < 50 && controller.surface == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
  expect(controller.surface, isNotNull);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: FlutterEarthGlobe(controller: controller, radius: 150),
        ),
      ),
    ),
  ));
  // Let the shaders load and the label be measured.
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  return controller;
}

void main() {
  testWidgets('a point label shows as soon as its point is visible',
      (WidgetTester tester) async {
    final controller = await pumpGlobeWithLabel(tester);

    expect(controller.globeKey.currentState!.visiblePoints, contains('p'));
    expect(find.text('label'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'a point label is placed for the rotation painted in the same frame',
      (WidgetTester tester) async {
    await pumpGlobeWithLabel(tester);
    // Make sure the label exists before dragging, so this test checks
    // placement only.
    tester.element(find.byType(RotatingGlobe)).markNeedsBuild();
    await tester.pump();
    final label = find.text('label');
    expect(label, findsOneWidget);
    final before = tester.getTopLeft(label);

    // Drag slowly (no fling), one frame per move.
    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(FlutterEarthGlobe)));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(8, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final afterDrag = tester.getTopLeft(label);
    expect(afterDrag.dx, isNot(closeTo(before.dx, 1)),
        reason: 'the drag should have moved the label');

    // Rebuild without changing the rotation. A label placed from the
    // previous frame's positions catches up here; a correct one stays put.
    tester.element(find.byType(RotatingGlobe)).markNeedsBuild();
    await tester.pump();

    final afterRebuild = tester.getTopLeft(label);
    expect(afterRebuild.dx, closeTo(afterDrag.dx, 1e-6));
    expect(afterRebuild.dy, closeTo(afterDrag.dy, 1e-6));

    await gesture.up();
    await tester.pump(const Duration(seconds: 2));
  });
}
