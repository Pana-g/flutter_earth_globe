import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'grabbing the globe mid-fling keeps the current rotation '
      'instead of snapping back to where the fling started (#33)',
      (WidgetTester tester) async {
    // Not disposed here: the globe's state disposes the controller's
    // animation controllers when it unmounts.
    final controller = FlutterEarthGlobeController(isRotating: false);

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
    await tester.pump();

    final globe = find.byType(FlutterEarthGlobe);

    // Release with velocity, so the deceleration animation takes over.
    await tester.fling(globe, const Offset(150, 0), 3000);
    await tester.pump();
    final rotationAtRelease = controller.globeKey.currentState!.rotationZ;

    // Let the fling carry the globe well away from the release position.
    await tester.pump(const Duration(milliseconds: 300));
    final rotationMidFling = controller.globeKey.currentState!.rotationZ;
    expect(rotationMidFling, isNot(closeTo(rotationAtRelease, 1e-3)));

    // Re-grab. Moving past the tap slop but not the pan slop makes the tap
    // recognizer give up, so the scale recognizer wins the arena and fires
    // onInteractionStart on its own, with no onInteractionUpdate in the same
    // event. The next frame then paints whatever onInteractionStart left.
    final gesture = await tester.startGesture(tester.getCenter(globe));
    await gesture.moveBy(const Offset(kTouchSlop + 2, 0));
    await tester.pump();

    expect(
      controller.globeKey.currentState!.rotationZ,
      closeTo(rotationMidFling, 1e-6),
    );

    // The globe runs a repeating ticker, so it never settles: pump past the
    // fling instead of pumpAndSettle.
    await gesture.up();
    await tester.pump(const Duration(seconds: 2));
  });
}
