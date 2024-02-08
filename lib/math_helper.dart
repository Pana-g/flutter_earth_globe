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
  // Convert the 2D offset back into 3D coordinates relative to the center
  double x = hoverOffset.dx - sphereCenter.dx;
  double y = hoverOffset.dy - sphereCenter.dy;
  // Assuming z can be derived from x and y considering the radius and the spherical nature
  double z = sqrt(radius * radius - x * x - y * y);

  // Convert back to the original Cartesian coordinate system before rotations were applied
  Vector3 cartesian = Vector3(z, x, -y);

  // Inverse the rotations using rotation matrices
  Matrix3 rotationMatrixY = Matrix3.rotationY(rotationY); // Inverse rotation
  Matrix3 rotationMatrixZ = Matrix3.rotationZ(rotationZ); // Inverse rotation
  Vector3 originalCartesian =
      rotationMatrixZ.multiplied(rotationMatrixY).transform(cartesian);

  // Convert Cartesian coordinates back to spherical coordinates
  double lat = asin(originalCartesian.z / radius);
  double lon;
  if (radius * cos(lat) != 0) {
    // Avoid division by zero
    lon = atan2(originalCartesian.y, originalCartesian.x);
  } else {
    lon = 0;
  }

  // Convert radians back to degrees
  double latitude = radiansToDegrees(lat);
  double longitude = radiansToDegrees(lon);
  if (latitude.isNaN || longitude.isNaN) return null;
  // Return the GlobeCoordinates object
  return GlobeCoordinates(latitude, longitude);
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
  if (rotation < 0) {
    rotation = -(rotation.abs() % twoPi);
  } else {
    rotation = rotation % twoPi;
  }
  return rotation;
}
