import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart';

import 'globe_coordinates.dart';

/// Converts degrees to radians
double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

/// Converts radians to degrees
double radiansToDegrees(double radians) {
  return radians * 180 / pi;
}

/// Calculates the position of a point on the sphere
///
/// [coordinates] - the coordinates of the point
/// [radius] - the radius of the sphere
/// [rotationY] - the rotation around the Y-axis
/// [rotationZ] - the rotation around the Z-axis
///
/// Returns the position of the point on the sphere as a [Vector3]
Vector3 getSpherePosition3D(GlobeCoordinates coordinates, double radius,
    double rotationY, double rotationZ) {
  // radius += 10;
  // Convert latitude and longitude to radians
  double lat = degreesToRadians(coordinates.latitude);
  double lon = degreesToRadians(coordinates.longitude);

  // Convert spherical coordinates (lat, lon, radius) to Cartesian coordinates (x, y, z)
  Vector3 cartesian = Vector3(radius * cos(lat) * cos(lon),
      radius * cos(lat) * sin(lon), radius * sin(lat));

  // Create rotation matrices for X, Y, and Z axes
  Matrix3 rotationMatrixY = Matrix3.rotationY(-rotationY);
  Matrix3 rotationMatrixZ = Matrix3.rotationZ(-rotationZ);

  // Apply the rotations
  return rotationMatrixY.multiplied(rotationMatrixZ).transform(cartesian);
}

/// Returns the scaling factor for a point on the sphere
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

/// Returns the rectangle that represents a point on the sphere as [Rect]
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

/// Returns the rotation around the Z-axis
double adjustModRotation(double rotation) {
  double twoPi = 2 * pi;
  if (rotation < 0) {
    rotation = -(rotation.abs() % twoPi);
  } else {
    rotation = rotation % twoPi;
  }
  return rotation;
}
