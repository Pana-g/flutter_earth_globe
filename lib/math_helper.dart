import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'globe_coordinates.dart';

/// Converts degrees to radians.
///
/// Takes a [degrees] value and returns the equivalent value in radians.
double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

/// Converts radians to degrees.
///
/// Takes a [radians] value and returns the equivalent value in degrees.
double radiansToDegrees(double radians) {
  return radians * 180 / pi;
}

/// Calculates the 3D position of a point on a sphere.
///
/// Takes [coordinates], [radius], [rotationY], and [rotationZ] as input parameters.
/// [coordinates] is an instance of [GlobeCoordinates] containing the latitude and longitude of the point.
/// [radius] is the radius of the sphere.
/// [rotationY] and [rotationZ] are rotation angles around the Y and Z axes, respectively.
/// Returns a [Vector3] representing the 3D position of the point on the sphere.
Vector3 getSpherePosition3D(GlobeCoordinates coordinates, double radius,
    double rotationY, double rotationZ) {
  // Convert latitude and longitude to radians
  double lat = degreesToRadians(coordinates.latitude);
  double lon = degreesToRadians(coordinates.longitude);

  // Convert spherical coordinates (lat, lon, radius) to Cartesian coordinates (x, y, z)
  // Standard spherical to cartesian conversion:
  // x = R * cos(lat) * cos(lon)
  // y = R * cos(lat) * sin(lon)
  // z = R * sin(lat)
  Vector3 cartesian = Vector3(
    radius * cos(lat) * cos(lon),
    radius * cos(lat) * sin(lon),
    radius * sin(lat),
  );

  // Apply rotations
  // Note: rotationY and rotationZ are in radians
  Matrix4 rotationMatrix = Matrix4.identity()
    ..rotateY(-rotationY)
    ..rotateZ(-rotationZ);

  return rotationMatrix.transform3(cartesian);
}

/// Converts the 2D offset to spherical coordinates.
///
/// Takes [hoverOffset], [sphereCenter], [radius], [rotationY], and [rotationZ] as input parameters.
/// [hoverOffset] is the 2D position of the point on the screen.
/// [sphereCenter] is the center of the sphere.
/// [radius] is the radius of the sphere.
/// [rotationY] and [rotationZ] are rotation angles around the Y and Z axes, respectively.
///
/// Returns a [GlobeCoordinates] object representing the spherical coordinates of the point.
/// Returns null if the point is not on the sphere.
GlobeCoordinates? convert2DPointToSphereCoordinates(Offset hoverOffset,
    Offset sphereCenter, double radius, double rotationY, double rotationZ) {
  // Convert 2D screen coordinate to 3D position relative to center
  double y = hoverOffset.dx - sphereCenter.dx;
  double z = -(hoverOffset.dy - sphereCenter.dy);

  // Check if the point is within the circle in 2D
  double distSq = y * y + z * z;
  if (distSq > radius * radius) return null;

  // Derive X coordinate from the sphere's equation: x^2 + y^2 + z^2 = R^2
  // We take the positive root because it's the front of the sphere (facing the camera)
  double x = sqrt(radius * radius - distSq);

  Vector3 currentVec = Vector3(x, y, z);

  // Undo the rotation in reverse order: first undo Z, then undo Y
  Matrix4 undoRotation = Matrix4.identity()
    ..rotateZ(rotationZ)
    ..rotateY(rotationY);

  Vector3 originalVec = undoRotation.transform3(currentVec);

  // Convert back to latitude and longitude
  // lat = asin(z / R)
  // lon = atan2(y, x)
  double latRad = asin((originalVec.z / radius).clamp(-1.0, 1.0));
  double lonRad = atan2(originalVec.y, originalVec.x);

  return GlobeCoordinates(radiansToDegrees(latRad), radiansToDegrees(lonRad));
}

/// Calculates the scale factor for a point on the sphere.
///
/// Takes [point], [center], [radius], [isXAxis], [zCoord], and [zoomFactor] as input parameters.
/// [point] is the 2D position of the point on the screen.
/// [center] is the center of the screen.
/// [radius] is the radius of the sphere.
/// [isXAxis] indicates whether the point lies on the X-axis or Y-axis.
/// [zCoord] is the Z-coordinate of the point in 3D space.
/// [zoomFactor] is the zoom factor of the sphere.
/// Returns the scale factor for the point.
double getScaleFactor(Offset point, Offset center, double radius, bool isXAxis,
    double zCoord, double zoomFactor) {
  // Calculate distance from the point to the center for the specified axis
  double distance =
      isXAxis ? (point.dx - center.dx).abs() : (point.dy - center.dy).abs();

  // Normalize Z-coordinate relative to the radius and adjust for zoom factor
  double normalizedZ = (zCoord / radius).clamp(-1, 1) * zoomFactor;

  // Check if the point is behind the sphere (not visible)
  if (normalizedZ < 0) return 0;

  // Perspective scaling factor
  double perspectiveScaling = 0.5 + 0.5 * normalizedZ;

  // Calculate the scaling factor based on the distance and perspective
  double scaleFactor = max(0.6, 1 - distance / radius) * perspectiveScaling;

  return scaleFactor;
}

/// Calculates the rectangle on the sphere corresponding to a 3D point and its 2D position on the screen.
///
/// Takes [cartesian3D], [cartesian2D], [center], [radius], [zoomFactor], and [pointSize] as input parameters.
/// [cartesian3D] is the 3D position of the point on the sphere.
/// [cartesian2D] is the 2D position of the point on the screen.
/// [center] is the center of the screen.
/// [radius] is the radius of the sphere.
/// [zoomFactor] is the zoom factor of the sphere.
/// [pointSize] is the size of the point.
/// Returns a [Rect] representing the rectangle on the sphere.
Rect getRectOnSphere(Vector3 cartesian3D, Offset cartesian2D, Offset center,
    double radius, double zoomFactor, double pointSize) {
  // Calculate scale factors
  double scaleFactorX = getScaleFactor(
      cartesian2D, center, radius, true, cartesian3D.x, zoomFactor);
  double scaleFactorY = getScaleFactor(
      cartesian2D, center, radius, false, cartesian3D.x, zoomFactor);

  // Adjust width and height based on the position on the sphere
  double adjustedWidth =
      pointSize * scaleFactorX * 2 * cos(cartesian3D.y / radius);
  double adjustedHeight =
      pointSize * scaleFactorY * 2 * cos(cartesian3D.z / radius);

  // Draw an ellipse that represents a circle on the sphere
  return Rect.fromCenter(
    center: cartesian2D,
    width: adjustedWidth,
    height: adjustedHeight,
  );
}

/// Adjusts the rotation angle to be within the range of 0 to 2π.
///
/// Takes a [rotation] angle in radians and returns the adjusted angle within the range of 0 to 2π.
double adjustModRotation(double rotation) {
  double twoPi = 2 * pi;
  // Proper modulo that handles negative numbers correctly
  rotation = rotation % twoPi;
  if (rotation < 0) {
    rotation += twoPi;
  }
  return rotation;
}
