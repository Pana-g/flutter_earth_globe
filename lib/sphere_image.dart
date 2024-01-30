// Define the SphereImage class
import 'dart:ui';

class SphereImage {
  SphereImage({
    required this.image,
    required this.radius,
    required this.origin,
    required this.offset,
  });

  final Image image;
  final double radius;
  final Offset origin;
  final Offset offset;
}
