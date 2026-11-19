import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/gpu_foreground_painter.dart';
import 'package:flutter_earth_globe/satellite.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the names of the canvas calls the painter makes.
class _RecordingCanvas implements Canvas {
  final List<Symbol> calls = [];
  final List<Offset> scales = [];

  @override
  void scale(double sx, [double? sy]) {
    calls.add(#scale);
    scales.add(Offset(sx, sy ?? sx));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    return null;
  }
}

ui.Picture _picture() {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 40, 20),
    Paint()..color = const Color(0xFFFF0000),
  );
  return recorder.endRecording();
}

_RecordingCanvas _paint(SatelliteStyle style) {
  final canvas = _RecordingCanvas();
  GpuForegroundPainter(
    points: const [],
    arcs: const [],
    regions: const [],
    radius: 150,
    center: const Offset(200, 200),
    satellites: [
      SatelliteRenderData(
        id: 'sat',
        position2D: const Offset(200, 200),
        depth: 1,
        isVisible: true,
        currentPosition: const GlobeCoordinates(0, 0),
        satellite: Satellite(
          id: 'sat',
          coordinates: const GlobeCoordinates(0, 0),
          style: style,
        ),
      ),
    ],
  ).paint(canvas, const Size(400, 400));
  return canvas;
}

void main() {
  group('SatelliteShape.customImage', () {
    test('draws the picture with a uniform, aspect-preserving scale', () {
      final picture = _picture();
      addTearDown(picture.dispose);

      final canvas = _paint(
        SatelliteStyle(
          size: 10,
          sizeAttenuation: false,
          shape: SatelliteShape.customImage,
          customImage: picture,
          customImageSize: const Size(40, 20),
        ),
      );

      expect(canvas.calls, contains(#drawPicture));
      expect(canvas.calls, isNot(contains(#drawCircle)));
      // size * 2 / max(40, 20) on both axes, so a 40x20 image stays 2:1.
      expect(canvas.scales.single, const Offset(0.5, 0.5));
    });

    test('falls back to a circle when no picture is set', () {
      final canvas = _paint(
        const SatelliteStyle(shape: SatelliteShape.customImage),
      );

      expect(canvas.calls, contains(#drawCircle));
      expect(canvas.calls, isNot(contains(#drawPicture)));
    });

    test('falls back to a circle when the picture size is empty', () {
      final picture = _picture();
      addTearDown(picture.dispose);

      final canvas = _paint(
        SatelliteStyle(
          shape: SatelliteShape.customImage,
          customImage: picture,
          customImageSize: Size.zero,
        ),
      );

      expect(canvas.calls, contains(#drawCircle));
      expect(canvas.calls, isNot(contains(#drawPicture)));
    });
  });

  group('SatelliteStyle custom image fields', () {
    test('copyWith keeps the picture, its size and rotation', () {
      final picture = _picture();
      addTearDown(picture.dispose);

      final style = SatelliteStyle(
        shape: SatelliteShape.customImage,
        customImage: picture,
        customImageSize: const Size(40, 20),
        customImageRotated: true,
      ).copyWith(size: 9);

      expect(style.size, 9);
      expect(style.customImage, same(picture));
      expect(style.customImageSize, const Size(40, 20));
      expect(style.customImageRotated, isTrue);
    });

    test('JSON leaves the picture out but keeps the rotation flag', () {
      final picture = _picture();
      addTearDown(picture.dispose);

      final style = SatelliteStyle(
        shape: SatelliteShape.customImage,
        customImage: picture,
        customImageSize: const Size(40, 20),
        customImageRotated: true,
      );

      final map = jsonDecode(style.toJson()) as Map<String, dynamic>;
      expect(map.containsKey('customImage'), isFalse);
      expect(map.containsKey('customImageSize'), isFalse);

      final restored = SatelliteStyle.fromJson(style.toJson());
      expect(restored.shape, SatelliteShape.customImage);
      expect(restored.customImageRotated, isTrue);
      expect(restored.customImage, isNull);
    });
  });
}
