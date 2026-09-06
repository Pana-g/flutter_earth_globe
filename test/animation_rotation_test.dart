import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point_connection.dart';

void main() {
  group('PR 1: Animation & Rotation Unit Tests', () {
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

    test('Shortest-path spherical interpolation math handles boundaries', () {
      double shortestPath(double target, double initial) {
        double diff = target - initial;
        return (diff + math.pi) % (2 * math.pi) - math.pi;
      }

      // Small angle moves
      expect(shortestPath(0.1, 0.0), closeTo(0.1, 1e-9));
      expect(shortestPath(0.0, 0.1), closeTo(-0.1, 1e-9));

      // Crossing the anti-meridian (+170 deg to -170 deg)
      // +170 deg = 2.96706 rad, -170 deg = -2.96706 rad
      // Instead of moving -340 deg (-5.934 rad), shortest path is +20 deg (+0.349 rad)
      final initialLon = 170.0 * math.pi / 180.0;
      final targetLon = -170.0 * math.pi / 180.0;
      final delta = shortestPath(targetLon, initialLon);
      expect(delta, closeTo(20.0 * math.pi / 180.0, 1e-6));

      // Opposite direction (-170 deg to +170 deg) -> shortest path is -20 deg
      final deltaOpposite = shortestPath(initialLon, targetLon);
      expect(deltaOpposite, closeTo(-20.0 * math.pi / 180.0, 1e-6));

      // Full revolutions accumulated (e.g. after spinning for 50 revolutions: 100*pi rad)
      final accumulatedSpin = 100.0 * math.pi;
      final targetOrigin = 0.0;
      final deltaAfterSpin = shortestPath(targetOrigin, accumulatedSpin);
      expect(deltaAfterSpin, closeTo(0.0, 1e-6));
    });

    test('Frame-rate independent delta-time guard clamps invalid intervals', () {
      double computeDt(DateTime lastTick, DateTime now) {
        double dt = now.difference(lastTick).inMicroseconds / 1000000.0;
        if (dt <= 0.0 || dt > 0.1) {
          dt = 1 / 60.0;
        }
        return dt;
      }

      final now = DateTime.now();

      // Normal 60fps frame (~16.6ms)
      final normal60fps = now.subtract(const Duration(milliseconds: 16));
      expect(computeDt(normal60fps, now), closeTo(0.016, 1e-3));

      // Normal 120fps frame (~8.3ms)
      final normal120fps = now.subtract(const Duration(microseconds: 8333));
      expect(computeDt(normal120fps, now), closeTo(0.008333, 1e-3));

      // Sudden frame stutter / background pause (e.g. 5 seconds delay)
      final pause5s = now.subtract(const Duration(seconds: 5));
      expect(computeDt(pause5s, now), closeTo(1 / 60.0, 1e-9));

      // Non-monotonic clock / zero interval
      expect(computeDt(now, now), closeTo(1 / 60.0, 1e-9));
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
  });
}
