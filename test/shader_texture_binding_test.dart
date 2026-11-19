import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_earth_globe/background_shader_painter.dart';
import 'package:flutter_earth_globe/sphere_shader_painter.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 20;

Future<ui.Image> _solidImage(Color color) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, _size.toDouble(), _size.toDouble()),
      Paint()..color = color);
  return recorder.endRecording().toImage(_size, _size);
}

/// Paints [painter] and returns the RGBA bytes of the centre pixel.
Future<List<int>> _centrePixel(CustomPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size(_size.toDouble(), _size.toDouble()));
  final image = await recorder.endRecording().toImage(_size, _size);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final offset = ((_size ~/ 2) * _size + _size ~/ 2) * 4;
  return bytes.buffer.asUint8List(offset, 4).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // With the CanvasKit web renderer, a sampler bound once is deleted when the
  // ImageShader that owns it is garbage-collected, and the globe turned into
  // a blank disk as soon as it rotated. The painters must therefore bind
  // their textures on every paint rather than rely on the bindings made when
  // the shader was created. Here the shader is created with a blue texture
  // and painted with a red one: the red one has to be what gets drawn.

  test('SphereShaderPainter binds its textures when it paints', () async {
    final program = await ui.FragmentProgram.fromAsset('shaders/sphere.frag');
    final blue = await _solidImage(const Color(0xFF0000FF));
    final red = await _solidImage(const Color(0xFFFF0000));
    final shader = program.fragmentShader();
    bindSphereTextures(shader, blue, blue);

    final pixel = await _centrePixel(SphereShaderPainter(
      shader: shader,
      daySurface: red,
      radius: _size / 2,
      center: Offset(_size / 2, _size / 2),
      rotationX: 0,
      rotationZ: 0.3,
      lightingEnabled: false,
    ));

    expect(pixel, [255, 0, 0, 255]);
  });

  test('BackgroundShaderPainter binds its texture when it paints', () async {
    final program =
        await ui.FragmentProgram.fromAsset('shaders/background.frag');
    final blue = await _solidImage(const Color(0xFF0000FF));
    final red = await _solidImage(const Color(0xFFFF0000));
    final shader = program.fragmentShader()..setImageSampler(0, blue);

    final pixel = await _centrePixel(BackgroundShaderPainter(
      shader: shader,
      starTexture: red,
      offsetX: 3,
      offsetY: 0,
      texWidth: _size.toDouble(),
      texHeight: _size.toDouble(),
    ));

    expect(pixel, [255, 0, 0, 255]);
  });
}
