// Define the SphereImage class
import 'dart:ui';

/// Represents an image mapped onto a sphere.
///
/// The [SphereImage] class contains information about the image, its radius,
/// origin, and offset.
///
/// Example usage:
/// ```dart
/// final image = Image.asset('assets/earth.jpg');
/// final sphereImage = SphereImage(
///   image: image,
///   radius: 100,
///   origin: Offset(0, 0),
///   offset: Offset(10, 10),
/// );
/// ```
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
