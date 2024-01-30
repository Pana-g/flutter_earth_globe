import 'dart:math';
import 'dart:ui';

import 'misc.dart';
import 'math_helper.dart';
import 'point_connection_style.dart';
import 'package:vector_math/vector_math.dart';

import 'point_connection.dart';

/// This class is responsible for painting the foreground of the globe.
/// It paints the points and the connections between them.
///
/// Returns the path of the connection if it is visible, otherwise returns null.
Path? drawAnimatedLine(
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

  // Calculate control points for curvature
  if (isStartVisible || isEndVisible) {
    Paint paint = Paint()
      ..color = connection.style.color
      ..strokeWidth = connection.style.lineWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.moveTo(startCartesian2D.dx, startCartesian2D.dy);

    var midPoint = (startCartesian3D + endCartesian3D) / 2;
    midPoint.normalize();

    if ((radius * 2) - startCartesian3D.distanceTo(endCartesian3D) < 100) {
      final curvature =
          (startCartesian3D.distanceTo(endCartesian3D) * 0.005).clamp(1.7, 2.5);
      midPoint.scale(radius * curvature);
    } else {
      midPoint.scale(radius * 1.7);
    }

    final midPoint2D = Offset(center.dx + midPoint.y, center.dy - midPoint.z);

    path.quadraticBezierTo(
        midPoint2D.dx, midPoint2D.dy, endCartesian2D.dx, endCartesian2D.dy);

    PathMetric pathMetric = path.computeMetrics().first;

    double start = 0;
    double end = pathMetric.length * animationValue;

    if (!isStartVisible) {
      Offset? intersection =
          findCurveSphereIntersection(path, center, radius, 1, true);
      if (intersection != null) {
        // canvas.drawCircle(intersection, 5, paint);
        final perc = 1 - getDrawPercentage(path, intersection) / 100;
        // print(perc);
        start = pathMetric.length - (perc * pathMetric.length);
      } else {
        return null;
      }
    } else if (!isEndVisible) {
      Offset? intersection =
          findCurveSphereIntersection(path, center, radius, 1, false);
      if (intersection != null) {
        final perc =
            1 - getDrawPercentage(path, intersection, first: false) / 100;
        end = (pathMetric.length - (perc * pathMetric.length)) * animationValue;
      } else {
        return null;
      }
    }

    Path extractPath = pathMetric.extractPath(start, end);
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

    // paint text on the midpoint
    if ((connection.isTitleVisible &&
            (connection.title?.isNotEmpty ?? false)) ||
        (connection.showTitleOnHover &&
            hoverPoint != null &&
            isPointOnPath(extractPath, hoverPoint))) {
      double t = 0.5;
      Offset realMidPoint = Offset(
        pow(1 - t, 2) * startCartesian2D.dx +
            2 * (1 - t) * t * midPoint2D.dx +
            pow(t, 2) * endCartesian2D.dx,
        pow(1 - t, 2) * startCartesian2D.dy +
            2 * (1 - t) * t * midPoint2D.dy +
            pow(t, 2) * endCartesian2D.dy,
      );
      paintText(connection.title ?? '', connection.textStyle, realMidPoint,
          size, canvas);
    }
    return extractPath;
  }
  return null;
}

/// Calculates the length of the path up to the intersection with the sphere.
///
/// Returns a list of lengths up to the intersection.
List<double> getPathLengthsUpToIntersection(Path path, Offset intersection) {
  PathMetric pathMetric = path.computeMetrics().first;
  double totalLength = pathMetric.length;
  List<double> lengths = [];

  for (double d = 0.0; d <= totalLength; d += 1) {
    Tangent? tangent = pathMetric.getTangentForOffset(d);
    if (tangent == null) continue;
    if ((tangent.position - intersection).distance < 1) {
      lengths.add(d);
    }
  }

  return lengths;
}

/// Calculates the percentage of the path that is drawn up to the intersection
///
/// Returns the percentage of the path that is drawn up to the intersection.
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

/// Calculates the curvature of the path at the given distance.
///
/// Returns the curvature as [double].
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

/// Calculates the points on the path with a given tolerance.
///
/// Returns a list of points as [List<Offset>] on the path with a given tolerance.
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

/// Refines the intersection between the path and the sphere.
///
/// Returns the refined intersection between the path and the sphere as an [Offset].
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

/// Finds the intersection between the path and the sphere.
///
/// Returns the intersection between the path and the sphere as an [Offset].
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
