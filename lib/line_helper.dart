import 'dart:math';
import 'dart:ui';

import 'package:flutter_earth_globe/globe_coordinates.dart';

import 'misc.dart';
import 'math_helper.dart';
import 'point_connection_style.dart';
import 'package:vector_math/vector_math_64.dart';

import 'point_connection.dart';

/// Draws an animated line on the canvas connecting two points on a sphere.
///
/// The line is drawn using the provided [canvas] object and is animated based on the [animationValue].
/// The [radius] parameter specifies the radius of the sphere.
/// The [rotationY] and [rotationZ] parameters control the rotation of the sphere.
/// The [size] parameter represents the size of the canvas.
/// The [hoverPoint] parameter is an optional offset representing the position of a hover point.
///
/// Returns a [Map] with a path and a Offset representing the drawn line, or null if the line is not visible.
Map? drawAnimatedLine(
    Canvas canvas,
    AnimatedPointConnection connection,
    double radius,
    double rotationY,
    double rotationZ,
    double animationValue,
    Size size,
    Offset? hoverPoint) {
  // Calculate 3D positions for the start and end points
  Vector3 startCartesian3D =
      getSpherePosition3D(connection.start, radius, rotationY, rotationZ);
  Vector3 endCartesian3D =
      getSpherePosition3D(connection.end, radius, rotationY, rotationZ);

  // Project 3D positions to 2D canvas
  final center = Offset(size.width / 2, size.height / 2);
  Offset startCartesian2D =
      Offset(center.dx + startCartesian3D.y, center.dy - startCartesian3D.z);
  Offset endCartesian2D =
      Offset(center.dx + endCartesian3D.y, center.dy - endCartesian3D.z);

  // Check if points are on the visible side of the sphere
  bool isStartVisible = startCartesian3D.x > 0;
  bool isEndVisible = endCartesian3D.x > 0;

  // Calculate midpoint visibility for cases where both endpoints are hidden
  // but the arc passes over the visible side
  var midPoint3D = (startCartesian3D + endCartesian3D) / 2;
  midPoint3D.normalize();
  final angle = calculateCentralAngle(connection.start, connection.end);
  midPoint3D.scale(((radius + (angle) * 10 * pi) * connection.curveScale));
  bool isMidpointVisible = midPoint3D.x > 0;

  // Only draw if at least one endpoint or the midpoint is visible
  if (isStartVisible || isEndVisible || isMidpointVisible) {
    Paint paint = Paint()
      ..color = connection.style.color
      ..strokeWidth = connection.style.lineWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.moveTo(startCartesian2D.dx, startCartesian2D.dy);

    final midPoint2D =
        Offset(center.dx + midPoint3D.y, center.dy - midPoint3D.z);

    path.quadraticBezierTo(
        midPoint2D.dx, midPoint2D.dy, endCartesian2D.dx, endCartesian2D.dy);

    PathMetric pathMetric = path.computeMetrics().first;
    double totalLength = pathMetric.length;

    double drawStart = 0;
    double drawEnd = totalLength * animationValue;

    // Handle visibility clipping
    if (!isStartVisible && !isEndVisible) {
      // Both ends hidden - find both intersection points
      Offset? startIntersection =
          findCurveSphereIntersection(path, center, radius, 1, true);
      Offset? endIntersection =
          findCurveSphereIntersection(path, center, radius, 1, false);

      if (startIntersection != null && endIntersection != null) {
        final startPerc = getDrawPercentage(path, startIntersection) / 100;
        final endPerc =
            getDrawPercentage(path, endIntersection, first: false) / 100;
        drawStart = totalLength * startPerc;
        drawEnd = min(totalLength * endPerc, totalLength * animationValue);
      } else {
        return {'path': null, 'midPoint': midPoint2D};
      }
    } else if (!isStartVisible) {
      // Start is hidden - clip from intersection
      Offset? intersection =
          findCurveSphereIntersection(path, center, radius, 1, true);
      if (intersection != null) {
        final perc = getDrawPercentage(path, intersection) / 100;
        drawStart = totalLength * perc;
        // Don't extend drawEnd beyond animation progress
        drawEnd = totalLength * animationValue;
      } else {
        return {'path': null, 'midPoint': midPoint2D};
      }
    } else if (!isEndVisible) {
      // End is hidden - clip at intersection
      Offset? intersection =
          findCurveSphereIntersection(path, center, radius, 1, false);
      if (intersection != null) {
        final perc = getDrawPercentage(path, intersection, first: false) / 100;
        double visibleEnd = totalLength * perc;
        // Cap the draw end at the visible portion, scaled by animation progress
        drawEnd = min(visibleEnd, totalLength * animationValue);
      } else {
        return {'path': null, 'midPoint': midPoint2D};
      }
    }

    // Ensure drawStart doesn't exceed drawEnd
    if (drawStart >= drawEnd) {
      return {'path': null, 'midPoint': midPoint2D};
    }

    Path extractPath = pathMetric.extractPath(drawStart, drawEnd);
    final pathMetrics = extractPath.computeMetrics();
    if (pathMetrics.isNotEmpty) {
      switch (connection.style.type) {
        case PointConnectionType.solid:
          canvas.drawPath(extractPath, paint);
          break;
        case PointConnectionType.dashed:
          PathMetric extractPathMetric = extractPath.computeMetrics().first;

          double dashLength = connection.style.dashSize;
          double gapLength = connection.style.spacing;

          double animationOffset = connection.animationOffset;

          double distance = animationOffset;

          while (distance < extractPathMetric.length) {
            final double startDash = distance;
            final double endDash = startDash + dashLength;

            if (endDash < extractPathMetric.length) {
              final Tangent? startTangent =
                  extractPathMetric.getTangentForOffset(startDash);
              final Tangent? endTangent =
                  extractPathMetric.getTangentForOffset(endDash);

              if (startTangent != null && endTangent != null) {
                final Offset startPoint = startTangent.position;
                final Offset endPoint = endTangent.position;
                canvas.drawLine(startPoint, endPoint, paint);
              }
            }

            distance += dashLength + gapLength;
          }
          break;
        case PointConnectionType.dotted:
          PathMetric extractPathMetric = extractPath.computeMetrics().first;

          double distance = connection.animationOffset;

          while (distance < extractPathMetric.length) {
            Tangent? tangent = extractPathMetric.getTangentForOffset(distance);
            if (tangent != null) {
              final Offset point = tangent.position;
              canvas.drawCircle(point, connection.style.dotSize, paint);
            }
            distance += connection.style.spacing;
          }
          break;
      }
    }

    double t = 0.5;
    Offset realMidPoint = Offset(
      pow(1 - t, 2) * startCartesian2D.dx +
          2 * (1 - t) * t * midPoint2D.dx +
          pow(t, 2) * endCartesian2D.dx,
      pow(1 - t, 2) * startCartesian2D.dy +
          2 * (1 - t) * t * midPoint2D.dy +
          pow(t, 2) * endCartesian2D.dy,
    );
    // paint text on the midpoint
    if ((connection.isLabelVisible &&
            (connection.label?.isNotEmpty ?? false)) &&
        connection.labelBuilder == null) {
      paintText(connection.label ?? '', connection.labelTextStyle, realMidPoint,
          size, canvas);
    }
    return {'path': extractPath, 'midPoint': realMidPoint};
  }
  // Return midpoint even when completely hidden for potential future use
  final hiddenMidPoint3D = (startCartesian3D + endCartesian3D) / 2;
  hiddenMidPoint3D.normalize();
  final hiddenAngle = calculateCentralAngle(connection.start, connection.end);
  hiddenMidPoint3D
      .scale(((radius + (hiddenAngle) * 10 * pi) * connection.curveScale));
  final hiddenMidPoint2D =
      Offset(center.dx + hiddenMidPoint3D.y, center.dy - hiddenMidPoint3D.z);
  return {'path': null, 'midPoint': hiddenMidPoint2D};
}

/// Calculates the central angle between two points on a sphere.
///
/// The [start] and [end] parameters represent the start and end points.
///
/// Returns the central angle as a double value in radians.
double calculateCentralAngle(GlobeCoordinates start, GlobeCoordinates end) {
  // Convert latitude and longitude from degrees to radians
  double lat1 = degreesToRadians(start.latitude);
  double lon1 = degreesToRadians(start.longitude);
  double lat2 = degreesToRadians(end.latitude);
  double lon2 = degreesToRadians(end.longitude);

  // Apply the spherical law of cosines
  double deltaLon = lon2 - lon1;
  double centralAngle =
      acos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(deltaLon));

  return centralAngle; // Angle in radians
}

/// Calculates the lengths of the path up to the given intersection point.
///
/// The [path] parameter represents the path to calculate the lengths from.
/// The [intersection] parameter is the intersection point.
///
/// Returns a list of lengths representing the distances along the path up to the intersection point.
List<double> getPathLengthsUpToIntersection(Path path, Offset intersection) {
  PathMetric pathMetric = path.computeMetrics().first;
  double totalLength = pathMetric.length;
  List<double> lengths = [];

  // Use larger step size for better performance
  final step = max(1.0, totalLength / 100);
  for (double d = 0.0; d <= totalLength; d += step) {
    Tangent? tangent = pathMetric.getTangentForOffset(d);
    if (tangent == null) continue;
    if ((tangent.position - intersection).distance < step) {
      lengths.add(d);
    }
  }

  return lengths;
}

/// Calculates the draw percentage of the path up to the given intersection point.
///
/// The [path] parameter represents the path to calculate the draw percentage from.
/// The [intersection] parameter is the intersection point.
/// The [first] parameter specifies whether to calculate the draw percentage up to the first or last intersection.
///
/// Returns the draw percentage as a double value between 0 and 100.
double getDrawPercentage(Path path, Offset intersection, {bool first = true}) {
  List<double> lengthsUpToIntersections =
      getPathLengthsUpToIntersection(path, intersection);
  if (lengthsUpToIntersections.isEmpty) return 100.0; // No intersection

  PathMetric pathMetric = path.computeMetrics().first;
  double totalLength = pathMetric.length;

  double nearestIntersectionLength = first
      ? lengthsUpToIntersections.reduce(min)
      : lengthsUpToIntersections.reduce(max);
  return (nearestIntersectionLength / totalLength) * 100;
}

/// Calculates the curvature at a given distance along the path.
///
/// The [currentTangent] parameter represents the tangent at the current distance.
/// The [pathMetric] parameter represents the path metric of the path.
/// The [distance] parameter specifies the distance along the path.
/// The [step] parameter specifies the step size for calculating the next tangent.
///
/// Returns the curvature as a double value.
double calculateCurvature(Tangent currentTangent, PathMetric pathMetric,
    double distance, double step) {
  // Calculate the next tangent in the path
  double nextDistance = distance + step;
  if (nextDistance >= pathMetric.length) {
    nextDistance = pathMetric.length - 1;
  }
  Tangent? nextTangent = pathMetric.getTangentForOffset(nextDistance);

  if (nextTangent == null) return 0.0;

  // Calculate the angle difference between the current and next tangent
  double currentAngle = currentTangent.angle;
  double nextAngle = nextTangent.angle;
  double angleDifference = (nextAngle - currentAngle).abs();

  // Normalize the angle difference
  if (angleDifference > pi) {
    angleDifference = 2 * pi - angleDifference;
  }

  return angleDifference;
}

/// Converts a path into a list of points with adaptive spacing.
///
/// The [path] parameter represents the path to convert.
/// The [maxTolerance] parameter specifies the maximum tolerance for spacing between points.
///
/// Returns a list of points representing the path with adaptive spacing.
List<Offset> adaptivePathToPoints(Path path, double maxTolerance) {
  List<Offset> points = [];
  PathMetric pathMetric = path.computeMetrics().first;

  double distance = 0.0;
  double step = 1.0; // Initial step size

  while (distance < pathMetric.length) {
    Tangent? tangent = pathMetric.getTangentForOffset(distance);
    if (tangent == null) continue;
    points.add(tangent.position);

    double curvature = calculateCurvature(tangent, pathMetric, distance, step);
    // double curvature = tangent.angle;

    // Adjust step based on curvature
    step = maxTolerance / (1 + curvature.abs());
    distance += step;
  }

  return points;
}

/// Refines the intersection point between a line segment and a sphere.
///
/// The [start] and [end] parameters represent the endpoints of the line segment.
/// The [center] parameter represents the center of the sphere.
/// The [radius] parameter specifies the radius of the sphere.
///
/// Returns the refined intersection point as an [Offset].
Offset refineIntersection(
    Offset start, Offset end, Offset center, double radius) {
  double startDistance = (start - center).distance - radius;
  // double endDistance = (end - center).distance - radius;

  for (int i = 0; i < 10; i++) {
    Offset midpoint = (start + end) / 2;
    double midDistance = (midpoint - center).distance - radius;

    if (midDistance.abs() < 1) {
      return midpoint;
    }

    if (startDistance.sign == midDistance.sign) {
      start = midpoint;
      startDistance = midDistance;
    } else {
      end = midpoint;
      // endDistance = midDistance;
    }
  }

  return (start + end) / 2;
}

/// Finds the intersection point between a curved path and a sphere.
///
/// The [path] parameter represents the curved path.
/// The [center] parameter represents the center of the sphere.
/// The [radius] parameter specifies the radius of the sphere.
/// The [maxTolerance] parameter specifies the maximum tolerance for spacing between points on the path.
/// The [firstIntersection] parameter specifies whether to find the first or last intersection.
///
/// Returns the intersection point as an [Offset], or null if no intersection is found.
Offset? findCurveSphereIntersection(Path path, Offset center, double radius,
    double maxTolerance, bool firstIntersection) {
  List<Offset> points = adaptivePathToPoints(path, maxTolerance);
  List<Offset> intersections = [];
  Offset previousPoint = points.first;
  for (Offset point in points.skip(1)) {
    double prevDist = (previousPoint - center).distance - radius;
    double currDist = (point - center).distance - radius;

    if (prevDist.sign != currDist.sign) {
      Offset intersection =
          refineIntersection(previousPoint, point, center, radius);
      intersections.add(intersection);
    }

    previousPoint = point;
  }

  if (intersections.isNotEmpty) {
    return firstIntersection ? intersections.first : intersections.last;
  }

  return null;
}
