import 'point.dart';
import 'line_helper.dart';
import 'math_helper.dart';
import 'point_connection.dart';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;

import 'misc.dart';

/// This class is responsible for painting the foreground of the globe.
/// It paints the points and the connections between them.
/// It also handles the hover and click events.
class ForegroundPainter extends CustomPainter {
  ForegroundPainter({
    required this.connections,
    required this.radius,
    required this.rotationZ,
    required this.rotationY,
    required this.rotationX,
    required this.zoomFactor,
    required this.points,
    this.hoverPoint,
    this.clickPoint,
    this.onPointClicked,
  });

  VoidCallback? onPointClicked;
  final List<AnimatedPointConnection> connections;
  final Offset? hoverPoint;
  final Offset? clickPoint;
  final double radius;
  final double rotationZ;
  final double rotationY;
  final double rotationX;
  final double zoomFactor;
  final List<Point> points;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final localHover = hoverPoint;
    final localClick = clickPoint;

    for (var point in points) {
      final pointPaint = Paint()..color = point.style.color;
      vector.Vector3 cartesian3D =
          getSpherePosition3D(point.coordinates, radius, rotationY, rotationZ);
      Offset cartesian2D =
          Offset(center.dx + cartesian3D.y, center.dy - cartesian3D.z);

      if (cartesian3D.x > 0) {
        final rect = getRectOnSphere(cartesian3D, cartesian2D, center, radius,
            zoomFactor, point.style.size);
        canvas.drawOval(rect, pointPaint);
        // if(rect.contains())
        if (localHover != null && rect.contains(localHover)) {
          Future.delayed(Duration.zero, () {
            point.onHover?.call();
          });
        }

        if (localClick != null && rect.contains(localClick)) {
          Future.delayed(Duration.zero, () {
            point.onTap?.call();
            onPointClicked?.call();
          });
        }

        if ((point.isTitleVisible &&
                point.title != null &&
                point.title!.isNotEmpty) ||
            (point.showTitleOnHover &&
                localHover != null &&
                rect.contains(localHover))) {
          paintText(point.title!, point.textStyle, cartesian2D, size, canvas);
        }
      }
    }
    for (var connection in connections) {
      Path? path = drawAnimatedLine(canvas, connection, radius, rotationY,
          rotationZ, connection.animationProgress, size, hoverPoint);

      if (path != null) {
        if (localHover != null && isPointOnPath(path, localHover)) {
          Future.delayed(Duration.zero, () {
            connection.onHover?.call();
          });
        }
        if (localClick != null && isPointOnPath(path, localClick)) {
          Future.delayed(Duration.zero, () {
            connection.onTap?.call();
            onPointClicked?.call();
          });
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
