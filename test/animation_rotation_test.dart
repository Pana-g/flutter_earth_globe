import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point_connection.dart';

void main() {
  group('Animation & Rotation Tests', () {
    late FlutterEarthGlobeController controller;

    setUp(() {
      controller = FlutterEarthGlobeController();
    });

    test('DayNightMode is properly exported and configurable', () {
      // Verify DayNightMode enum is accessible from package root
      expect(DayNightMode.textureSwap, isNotNull);
      expect(DayNightMode.simulated, isNotNull);

      // Default should be textureSwap
      expect(controller.dayNightMode, DayNightMode.textureSwap);

      // Verify setting dayNightMode notifies listeners
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.dayNightMode = DayNightMode.simulated;
      expect(controller.dayNightMode, DayNightMode.simulated);
      expect(notified, isTrue);

      // Verify setSimulatedNightStyle
      controller.setSimulatedNightStyle(
        color: const Color(0xFF112233),
        intensity: 0.45,
      );
      expect(controller.simulatedNightColor, const Color(0xFF112233));
      expect(controller.simulatedNightIntensity, 0.45);
    });

    testWidgets('focusOnCoordinates takes the shortest spherical path across anti-meridian', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: controller,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(Duration.zero);

      final state = controller.globeKey.currentState!;

      // Focus to +170 longitude
      controller.focusOnCoordinates(
        const GlobeCoordinates(0, 170),
        animate: false,
      );
      await tester.pump();
      final initialRotZ = state.rotationZ;

      // Animate focus to -170 longitude over 1000ms
      // Shortest path is +20 deg (0.349 rad), not -340 deg
      controller.focusOnCoordinates(
        const GlobeCoordinates(0, -170),
        animate: true,
        duration: const Duration(milliseconds: 1000),
      );
      await tester.pump();
      // Halfway through animation (500ms)
      await tester.pump(const Duration(milliseconds: 500));

      // In 500ms, the rotation traveled ~10 degrees (~0.174 rad), NOT 170 degrees
      final halfDelta = (state.rotationZ - initialRotZ).abs();
      // Small delta proves it takes the 20 deg shortest path
      expect(halfDelta, lessThan(1.0));

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(Duration.zero);
    });

    testWidgets('auto-rotation advances proportionally to elapsed ticker duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: controller,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(Duration.zero);

      final state = controller.globeKey.currentState!;
      controller.startRotation(rotationSpeed: 0.1);
      await tester.pump();

      final initialRotZ = state.rotationZ;

      // Advance by 50ms
      await tester.pump(const Duration(milliseconds: 50));
      final delta50ms = (state.rotationZ - initialRotZ).abs();
      expect(delta50ms, isPositive);

      // Advance by another 100ms
      await tester.pump(const Duration(milliseconds: 100));
      final delta100ms = (state.rotationZ - (initialRotZ - delta50ms)).abs();
      // 100ms should rotate approximately twice as much as 50ms
      expect(delta100ms, closeTo(delta50ms * 2, 0.05));

      controller.stopRotation();
      await tester.pump();
      await tester.pump(Duration.zero);
    });

    testWidgets('RotatingGlobe initializes animationProgress for pre-existing connections', (tester) async {
      // Add connection before mounting widget
      controller.addPointConnection(
        PointConnection(
          start: const GlobeCoordinates(0, 0),
          end: const GlobeCoordinates(10, 10),
          id: 'test_conn_pre_mount',
        ),
      );

      // Verify connection was added
      expect(controller.connections.length, 1);
      final connection = controller.connections.first;

      // Mount RotatingGlobe in test harness
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: controller,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );

      // Drain microtasks and initial layout zero-duration timers
      await tester.pump();
      await tester.pump(Duration.zero);

      // Pre-existing connection must have its animationProgress initialized to 1.0
      expect(connection.animationProgress, 1.0);
    });

    testWidgets('RotatingGlobe responds to focusOnCoordinates without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: controller,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Immediate focus
      controller.focusOnCoordinates(
        const GlobeCoordinates(45, 90),
        animate: false,
      );
      await tester.pump();

      // Animated focus
      controller.focusOnCoordinates(
        const GlobeCoordinates(-20, -40),
        animate: true,
        duration: const Duration(milliseconds: 200),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(Duration.zero);
    });

    testWidgets('RotatingGlobe auto-rotation can start and stop cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: controller,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Start rotation
      controller.startRotation(rotationSpeed: 0.1);
      expect(controller.isRotating, isTrue);
      await tester.pump(const Duration(milliseconds: 100));

      // Stop rotation
      controller.stopRotation();
      expect(controller.isRotating, isFalse);
      await tester.pump();
      await tester.pump(Duration.zero);
    });

    testWidgets('resetRotation() cancels in-flight focus animation and maintains zero angles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: controller,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      final state = controller.globeKey.currentState!;

      // Start an animated focus to (45, 90) over 1000ms
      controller.focusOnCoordinates(
        const GlobeCoordinates(45, 90),
        animate: true,
        duration: const Duration(milliseconds: 1000),
      );

      // Start ticker and advance partway through the focus animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.rotationZ, isNot(0.0));

      // Call resetRotation() while the focus animation is actively running
      controller.resetRotation();
      await tester.pump();

      // Verify angles immediately reset to 0
      expect(state.rotationX, 0.0);
      expect(state.rotationY, 0.0);
      expect(state.rotationZ, 0.0);

      // Advance time past the original focus animation duration
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));

      // Verify angles were NOT overwritten by the canceled focus animation
      expect(state.rotationX, 0.0);
      expect(state.rotationY, 0.0);
      expect(state.rotationZ, 0.0);
    });

    testWidgets('resetRotation() during animated focus resumes auto-rotation from 0 when isRotating is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: controller,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      final state = controller.globeKey.currentState!;

      // Start auto-rotation
      controller.startRotation(rotationSpeed: 0.1);
      await tester.pump();
      expect(controller.isRotating, isTrue);

      // Focus on coordinates pauses rotationController during transition
      controller.focusOnCoordinates(
        const GlobeCoordinates(45, 90),
        animate: true,
        duration: const Duration(milliseconds: 1000),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.rotationController.isAnimating, isFalse);

      // Reset rotation should cancel focus animation and resume auto-rotation
      controller.resetRotation();
      expect(state.rotationX, 0.0);
      expect(state.rotationY, 0.0);
      expect(state.rotationZ, 0.0);

      await tester.pump();
      expect(controller.rotationController.isAnimating, isTrue);

      // Stop rotation for clean test teardown
      controller.stopRotation();
      await tester.pump();
      await tester.pump(Duration.zero);
    });

    test('FlutterEarthGlobeController can be disposed safely without mounting', () {
      final unmountedController = FlutterEarthGlobeController();
      expect(() => unmountedController.dispose(), returnsNormally);
    });

    test('controller.setZoom clamps zoom correctly', () {
      controller.setZoom(1.5);
      expect(controller.zoom, 1.5);

      // Clamps to minZoom / maxZoom
      controller.setZoom(-10.0);
      expect(controller.zoom, controller.minZoom);

      controller.setZoom(10.0);
      expect(controller.zoom, controller.maxZoom);
    });

    testWidgets('controller.isRotating setter starts and stops rotation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: controller,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      expect(controller.isRotating, isFalse);
      expect(controller.rotationController.isAnimating, isFalse);

      // Setter sets isRotating to true and starts animation
      controller.isRotating = true;
      expect(controller.isRotating, isTrue);
      await tester.pump();
      expect(controller.rotationController.isAnimating, isTrue);

      // Setter sets isRotating to false and stops animation
      controller.isRotating = false;
      expect(controller.isRotating, isFalse);
      await tester.pump();
      expect(controller.rotationController.isAnimating, isFalse);

      // toggleRotation
      controller.toggleRotation();
      expect(controller.isRotating, isTrue);
      await tester.pump();
      expect(controller.rotationController.isAnimating, isTrue);

      controller.toggleRotation();
      expect(controller.isRotating, isFalse);
      await tester.pump();
      expect(controller.rotationController.isAnimating, isFalse);
    });

    testWidgets('mounting with FlutterEarthGlobeController(isRotating: true) starts rotation immediately', (tester) async {
      final rotatingCtrl = FlutterEarthGlobeController(isRotating: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: rotatingCtrl,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);
      expect(rotatingCtrl.isRotating, isTrue);
      expect(rotatingCtrl.rotationController.isAnimating, isTrue);

      rotatingCtrl.stopRotation();
      await tester.pump();
      await tester.pump(Duration.zero);
    });

    testWidgets('pointer exit resets hover coordinates and hoveringPoint to null', (tester) async {
      GlobeCoordinates? lastHoverCoords;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterEarthGlobe(
              controller: controller,
              radius: 80,
              onHover: (coords) {
                lastHoverCoords = coords;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      final state = controller.globeKey.currentState!;

      // Simulate hover at the center of the sphere
      state.onHover(PointerHoverEvent(position: state.center));
      expect(state.hoveringPoint, state.center);
      expect(lastHoverCoords, isNotNull);

      // Simulate pointer exiting the globe widget
      state.onPointerExit(const PointerExitEvent());
      expect(state.hoveringPoint, isNull);
      expect(lastHoverCoords, isNull);

      // Verify that during auto-rotation, no phantom hover coordinates are emitted
      controller.startRotation();
      await tester.pump(const Duration(milliseconds: 100));
      expect(state.hoveringPoint, isNull);
      expect(lastHoverCoords, isNull);

      controller.stopRotation();
      await tester.pump();
      await tester.pump(Duration.zero);
    });

    testWidgets('focusOnCoordinates stops any active deceleration animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: FlutterEarthGlobe(
                  controller: controller,
                  radius: 80,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Fling the globe to start deceleration
      await tester.fling(find.byType(FlutterEarthGlobe), const Offset(100, 0), 1000);
      await tester.pump();

      // Focus on coordinates while deceleration is running
      controller.focusOnCoordinates(
        const GlobeCoordinates(20, 20),
        animate: true,
        duration: const Duration(milliseconds: 500),
      );
      await tester.pump();

      // Verify focus animation is running
      final state = controller.globeKey.currentState!;
      expect(state.genericAnimationController?.isAnimating, isTrue);

      // Wait for focus animation to finish
      await tester.pump(const Duration(milliseconds: 600));
      expect(state.rotationZ, isNot(0.0));
    });
  });
}
