// Tests mount the globe in MaterialApp/Scaffold, as apps do. Flutter 3.50
// deprecates this import in favour of package:material_ui, which needs
// Flutter >= 3.47 and would break `pub get` on our 3.27 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disposing the controller after the globe is removed works',
      (WidgetTester tester) async {
    final controller = FlutterEarthGlobeController();
    await tester.pumpWidget(MaterialApp(
      home: FlutterEarthGlobe(controller: controller, radius: 150),
    ));
    // Let the globe finish loading (initState schedules controller.load()).
    await tester.pump(const Duration(milliseconds: 100));

    // The usual order: the globe unmounts, then its owner disposes the
    // controller (e.g. in State.dispose or a provider's onDispose).
    await tester.pumpWidget(const SizedBox());
    expect(controller.dispose, returnsNormally);
  });

  testWidgets('disposing a controller that never had a globe works',
      (WidgetTester tester) async {
    final controller = FlutterEarthGlobeController();
    expect(controller.dispose, returnsNormally);
  });
}
