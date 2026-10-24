import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpGlobe(
    WidgetTester tester, FlutterEarthGlobeController controller) async {
  await tester.pumpWidget(MaterialApp(
    home: FlutterEarthGlobe(controller: controller, radius: 150),
  ));
  // initState schedules controller.load() on a zero delay.
  await tester.pump(const Duration(milliseconds: 100));
}

Future<MemoryImage> testImageProvider(WidgetTester tester) async {
  late MemoryImage provider;
  await tester.runAsync(() async {
    final image = await createTestImage(width: 8, height: 8);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    provider = MemoryImage(png!.buffer.asUint8List());
  });
  return provider;
}

/// Waits (in real time) until [condition] holds, for image decoding.
Future<void> waitFor(WidgetTester tester, bool Function() condition) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 50 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
}

void main() {
  group('updates', () {
    test('updatePoint replaces the point', () {
      final controller = FlutterEarthGlobeController();
      controller.addPoint(Point(
        id: 'p',
        coordinates: const GlobeCoordinates(10, 20),
        label: 'old',
      ));

      controller.updatePoint('p',
          label: 'new', style: const PointStyle(color: Colors.red));

      expect(controller.points.single.label, 'new');
      expect(controller.points.single.style.color, Colors.red);
      expect(controller.points.single.coordinates.latitude, 10);
    });

    test('updatePointConnection replaces the connection', () {
      final controller = FlutterEarthGlobeController();
      controller.addPointConnection(PointConnection(
        id: 'c',
        start: const GlobeCoordinates(0, 0),
        end: const GlobeCoordinates(10, 10),
        label: 'old',
      ));

      controller.updatePointConnection('c',
          label: 'new',
          isMoving: true,
          style: const PointConnectionStyle(color: Colors.red));

      final connection = controller.connections.single;
      expect(connection, isA<AnimatedPointConnection>());
      expect(connection.label, 'new');
      expect(connection.isMoving, isTrue);
      expect(connection.style.color, Colors.red);
    });

    test('updating an unknown id is a no-op', () {
      final controller = FlutterEarthGlobeController();
      expect(
          () => controller.updatePoint('missing', label: 'x'), returnsNormally);
      expect(() => controller.updatePointConnection('missing', label: 'x'),
          returnsNormally);
    });

    test('getSatellite returns null for an unknown id', () {
      expect(FlutterEarthGlobeController().getSatellite('missing'), isNull);
    });
  });

  group('zoom', () {
    test('setZoom clamps to the allowed range', () {
      final controller = FlutterEarthGlobeController(minZoom: -1, maxZoom: 2);

      controller.setZoom(5);
      expect(controller.zoom, 2);

      controller.setZoom(-3);
      expect(controller.zoom, -1);

      controller.setZoom(0.5);
      expect(controller.zoom, 0.5);
    });
  });

  group('rotation', () {
    testWidgets('the isRotating setter starts and stops the rotation',
        (tester) async {
      final controller = FlutterEarthGlobeController();
      await pumpGlobe(tester, controller);
      expect(controller.rotationController.isAnimating, isFalse);

      controller.isRotating = true;
      expect(controller.isRotating, isTrue);
      expect(controller.rotationController.isAnimating, isTrue);

      controller.isRotating = false;
      expect(controller.isRotating, isFalse);
      expect(controller.rotationController.isAnimating, isFalse);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('toggleRotation flips the rotation', (tester) async {
      final controller = FlutterEarthGlobeController();
      await pumpGlobe(tester, controller);

      controller.toggleRotation();
      expect(controller.isRotating, isTrue);
      expect(controller.rotationController.isAnimating, isTrue);

      controller.toggleRotation();
      expect(controller.isRotating, isFalse);
      expect(controller.rotationController.isAnimating, isFalse);

      await tester.pumpWidget(const SizedBox());
    });

    test('rotation calls before a globe is mounted only update the flag', () {
      final controller = FlutterEarthGlobeController();
      expect(controller.startRotation, returnsNormally);
      expect(controller.isRotating, isTrue);
      expect(controller.stopRotation, returnsNormally);
      expect(controller.toggleRotation, returnsNormally);
      expect(controller.isRotating, isTrue);
    });

    testWidgets('rotation calls after the globe unmounts do not throw (#27)',
        (tester) async {
      final controller = FlutterEarthGlobeController(isRotating: true);
      await pumpGlobe(tester, controller);
      await tester.pumpWidget(const SizedBox());

      expect(controller.isReady, isFalse);
      expect(controller.stopRotation, returnsNormally);
      expect(controller.startRotation, returnsNormally);
      expect(controller.toggleRotation, returnsNormally);
      expect(controller.resetRotation, returnsNormally);
      expect(controller.dispose, returnsNormally);
    });

    testWidgets('a controller can be reused by a new globe', (tester) async {
      final controller = FlutterEarthGlobeController(isRotating: true);
      await pumpGlobe(tester, controller);
      await tester.pumpWidget(const SizedBox());
      await pumpGlobe(tester, controller);

      expect(controller.isReady, isTrue);
      expect(controller.rotationController.isAnimating, isTrue);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('swapping the controller moves the globe to the new one',
        (tester) async {
      final first = FlutterEarthGlobeController();
      final second = FlutterEarthGlobeController(isRotating: true);
      await pumpGlobe(tester, first);
      await pumpGlobe(tester, second);

      expect(second.isReady, isTrue);
      expect(second.rotationController.isAnimating, isTrue);
      expect(first.isReady, isFalse);
      expect(first.startRotation, returnsNormally);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('connections', () {
    testWidgets('unmounting during a draw animation does not leak a ticker',
        (tester) async {
      final controller = FlutterEarthGlobeController();
      await pumpGlobe(tester, controller);

      controller.addPointConnection(
        PointConnection(
          id: 'c',
          start: const GlobeCoordinates(0, 0),
          end: const GlobeCoordinates(10, 10),
        ),
        animateDraw: true,
        animateDrawDuration: const Duration(seconds: 2),
      );
      await tester.pump(); // The draw animation's ticker starts here.
      await tester.pump(const Duration(milliseconds: 500));
      final progress = controller.connections.single.animationProgress;
      expect(progress, greaterThan(0));
      expect(progress, lessThan(1));

      // Throws "was disposed with an active Ticker" if the draw animation
      // controller is not disposed with the globe.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a draw animation completes', (tester) async {
      final controller = FlutterEarthGlobeController();
      await pumpGlobe(tester, controller);

      controller.addPointConnection(
        PointConnection(
          id: 'c',
          start: const GlobeCoordinates(0, 0),
          end: const GlobeCoordinates(10, 10),
        ),
        animateDraw: true,
        animateDrawDuration: const Duration(milliseconds: 300),
      );
      await tester.pump(); // The draw animation's ticker starts here.
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.connections.single.animationProgress, 1.0);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('images', () {
    testWidgets('loadBackground stores isBackgroundFollowingSphereRotation',
        (tester) async {
      final controller = FlutterEarthGlobeController();
      final provider = await testImageProvider(tester);

      controller.loadBackground(provider,
          isBackgroundFollowingSphereRotation: true);
      await waitFor(tester, () => controller.background != null);

      expect(controller.background, isNotNull);
      expect(controller.isBackgroundFollowingSphereRotation, isTrue);
    });

    testWidgets('removeBackground wins over a load that is still pending',
        (tester) async {
      final controller = FlutterEarthGlobeController();
      final provider = await testImageProvider(tester);

      controller.loadBackground(provider);
      controller.removeBackground();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));

      expect(controller.background, isNull);
    });

    testWidgets('a load that finishes after dispose is ignored',
        (tester) async {
      final controller = FlutterEarthGlobeController();
      final provider = await testImageProvider(tester);

      controller.loadSurface(provider);
      controller.dispose();
      // notifyListeners on a disposed ChangeNotifier would throw here.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));

      expect(controller.surface, isNull);
    });
  });
}
