import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'globe_coordinates.dart';
import 'line_helper.dart';
import 'math_helper.dart';
import 'point.dart';
import 'point_connection.dart';
import 'point_connection_style.dart';
import 'satellite.dart';
import 'region.dart';

/// Calculated position data for a point on the globe
class PointRenderData {
  final String id;
  final Offset position2D;
  final double depth; // 0-1, higher = closer to camera
  final bool isVisible;
  final Point point;
  final double transitionProgress; // 0-1 for fade in animation

  // 3D surface normal for tilt effect (Globe.GL style)
  final double normalX; // Surface normal x component (towards camera)
  final double normalY; // Surface normal y component (horizontal)
  final double normalZ; // Surface normal z component (vertical)
  final double
      tiltAngle; // Angle from camera view (0 = facing camera, pi/2 = edge)

  PointRenderData({
    required this.id,
    required this.position2D,
    required this.depth,
    required this.isVisible,
    required this.point,
    this.transitionProgress = 1.0,
    this.normalX = 1.0,
    this.normalY = 0.0,
    this.normalZ = 0.0,
    this.tiltAngle = 0.0,
  });
}

/// Calculated position data for an arc/connection on the globe
class ArcRenderData {
  final String id;
  final Offset start2D;
  final Offset end2D;
  final Offset
      control2D; // Bezier control point (legacy, kept for compatibility)
  final Offset midPoint2D;
  final List<Offset> arcPoints2D; // Points along the great circle arc
  final List<bool> arcPointsVisible; // Visibility of each arc point
  final bool isStartVisible;
  final bool isEndVisible;
  final bool isMidVisible;
  final AnimatedPointConnection connection;
  final double transitionProgress; // 0-1 for fade in animation
  final double growthProgress; // 0-1 for arc growth animation
  final double dashOffset; // Current dash animation offset

  ArcRenderData({
    required this.id,
    required this.start2D,
    required this.end2D,
    required this.control2D,
    required this.midPoint2D,
    required this.arcPoints2D,
    required this.arcPointsVisible,
    required this.isStartVisible,
    required this.isEndVisible,
    required this.isMidVisible,
    required this.connection,
    this.transitionProgress = 1.0,
    this.growthProgress = 1.0,
    this.dashOffset = 0.0,
  });
}

/// Calculated position data for a satellite on the globe
class SatelliteRenderData {
  final String id;
  final Offset position2D;
  final double depth; // 0-1, higher = closer to camera
  final bool isVisible;
  final Satellite satellite;
  final double transitionProgress; // 0-1 for fade in animation
  final GlobeCoordinates
      currentPosition; // Current position (for orbiting satellites)

  // 3D surface normal for tilt effect
  final double normalX;
  final double normalY;
  final double normalZ;
  final double tiltAngle;

  // Orbit path points (if showOrbitPath is enabled)
  final List<Offset>? orbitPath2D;
  final List<bool>? orbitPathVisible;

  SatelliteRenderData({
    required this.id,
    required this.position2D,
    required this.depth,
    required this.isVisible,
    required this.satellite,
    required this.currentPosition,
    this.transitionProgress = 1.0,
    this.normalX = 1.0,
    this.normalY = 0.0,
    this.normalZ = 0.0,
    this.tiltAngle = 0.0,
    this.orbitPath2D,
    this.orbitPathVisible,
  });
}

/// Manages transition animations for points and connections
class TransitionState {
  final DateTime addedAt;
  double transitionProgress;
  double growthProgress;

  TransitionState({
    required this.addedAt,
    this.transitionProgress = 0.0,
    this.growthProgress = 0.0,
  });
}

/// Cached orbit path data to avoid recalculation every frame
class CachedOrbitPath {
  final List<Offset> path2D;
  final List<bool> pathVisible;
  final double rotationY;
  final double rotationZ;
  final double radius;

  CachedOrbitPath({
    required this.path2D,
    required this.pathVisible,
    required this.rotationY,
    required this.rotationZ,
    required this.radius,
  });

  /// Check if the cache is still valid for the given parameters
  bool isValidFor(double rotY, double rotZ, double r) {
    // Use small epsilon for floating point comparison
    const epsilon = 0.0001;
    return (rotationY - rotY).abs() < epsilon &&
        (rotationZ - rotZ).abs() < epsilon &&
        (radius - r).abs() < epsilon;
  }
}

class RegionRenderData {
  final String id;
  final String baseId;
  final GlobeRegion region;
  final List<Path> visiblePaths;
  final Path? fillPath;
  final Path? polygonPath;
  final Color borderColor;
  final double borderWidth;
  final Color? fillColor;
  final Color? highlightColor;
  final bool isSelected;
  final bool isVisible;
  final List<String> clipAgainst;

  const RegionRenderData({
    required this.id,
    required this.baseId,
    required this.region,
    required this.visiblePaths,
    this.fillPath,
    this.polygonPath,
    required this.borderColor,
    required this.borderWidth,
    required this.fillColor,
    required this.highlightColor,
    required this.isSelected,
    required this.isVisible,
    required this.clipAgainst,
  });
}

class CachedPolygonData {
  final List<Vector3> vertices;
  final Vector3 center;
  final double sinThetaMax;

  CachedPolygonData({
    required this.vertices,
    required this.center,
    required this.sinThetaMax,
  });
}

/// Globe.GL-style foreground renderer for points and connections.
///
/// This class calculates positions for all elements and renders them
/// with proper animations, transitions, and GPU acceleration where possible.
class GlobeForegroundRenderer {
  final Map<String, List<CachedPolygonData>> _regionCoordinateCache = {};

  // Cache for region calculation to avoid recalculating when globe is stationary
  List<RegionRenderData>? _cachedRegionRenderData;
  double? _lastRegionRadius;
  double? _lastRegionRotationY;
  double? _lastRegionRotationZ;
  Size? _lastRegionCanvasSize;
  Set? _lastRegionSelectedIds;
  List? _lastRegions;
  int? _lastRegionLength;
  int? _lastRegionRevision;

  // Transition states for animations
  final Map<String, TransitionState> _pointTransitions = {};
  final Map<String, TransitionState> _connectionTransitions = {};
  final Map<String, TransitionState> _satelliteTransitions = {};

  // Time tracking for dash animations
  DateTime? _lastFrameTime;

  // Accumulated dash offsets per connection (for continuous animation)
  final Map<String, double> _dashOffsets = {};

  // Cached orbit paths to avoid expensive recalculation every frame
  // Key is satellite ID, value is cached path data
  final Map<String, CachedOrbitPath> _orbitPathCache = {};

  /// Calculate render data for all points
  List<PointRenderData> calculatePointPositions({
    required List<Point> points,
    required double radius,
    required double rotationY,
    required double rotationZ,
    required Size canvasSize,
    required DateTime now,
  }) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final List<PointRenderData> result = [];

    for (final point in points) {
      // Initialize transition if new point
      if (!_pointTransitions.containsKey(point.id)) {
        _pointTransitions[point.id] = TransitionState(addedAt: now);
      }

      // Update transition progress
      final transition = _pointTransitions[point.id]!;
      final elapsed = now.difference(transition.addedAt).inMilliseconds;
      final duration = point.style.transitionDuration;
      transition.transitionProgress =
          duration > 0 ? (elapsed / duration).clamp(0.0, 1.0) : 1.0;

      // Calculate 3D position
      final cartesian3D = getSpherePosition3D(
        point.coordinates,
        radius,
        rotationY,
        rotationZ,
      );

      // Project to 2D
      final position2D = Offset(
        center.dx + cartesian3D.y,
        center.dy - cartesian3D.z,
      );

      // Visibility check (front-facing)
      final isVisible = cartesian3D.x > 0;

      // Depth calculation for scaling (normalized 0-1)
      final depth = isVisible ? (cartesian3D.x / radius).clamp(0.0, 1.0) : 0.0;

      // Calculate surface normal (normalized cartesian3D is the surface normal)
      // This gives us the direction the surface is facing
      final normalX = cartesian3D.x / radius; // Towards camera
      final normalY = cartesian3D.y / radius; // Horizontal
      final normalZ = cartesian3D.z / radius; // Vertical

      // Tilt angle: angle between surface normal and camera direction (1,0,0)
      // cos(angle) = dot(normal, cameraDir) = normalX
      final tiltAngle = math.acos(normalX.clamp(-1.0, 1.0));

      result.add(PointRenderData(
        id: point.id,
        position2D: position2D,
        depth: depth,
        isVisible: isVisible,
        point: point,
        transitionProgress: transition.transitionProgress,
        normalX: normalX,
        normalY: normalY,
        normalZ: normalZ,
        tiltAngle: tiltAngle,
      ));
    }

    // Sort by depth (back to front) for proper overlapping
    result.sort((a, b) => a.depth.compareTo(b.depth));

    return result;
  }

  List<CachedPolygonData> _getCachedRegionCoordinates(GlobeRegion region) {
    final cached = _regionCoordinateCache[region.id];

    if (cached != null) {
      return cached;
    }

    final result = <CachedPolygonData>[];

    // TODO: Dynamic zoom-based simplification threshold. Currently fixed and computed
    // once upon loading, which can cause outlines to appear coarse when heavily zoomed in.
    // Pre-simplification threshold on the unit sphere (in radians squared)
    // 0.004 radians corresponds to ~0.6 screen pixels at default zoom.
    const simplifyThresholdSq = 0.000016; // 0.004 * 0.004

    for (final polygon in region.polygons) {
      final rawCoordinates = <Vector3>[];

      for (final coordinate in polygon) {
        final latitude = degreesToRadians(coordinate[1]);
        final longitude = degreesToRadians(coordinate[0]);

        final cosLatitude = math.cos(latitude);

        rawCoordinates.add(
          Vector3(
            cosLatitude * math.cos(longitude),
            cosLatitude * math.sin(longitude),
            math.sin(latitude),
          ),
        );
      }

      // Simplify the unit vectors on the sphere
      final polygonCoordinates = <Vector3>[];
      if (rawCoordinates.isNotEmpty) {
        polygonCoordinates.add(rawCoordinates.first);
        for (int i = 1; i < rawCoordinates.length - 1; i++) {
          final current = rawCoordinates[i];
          final lastKept = polygonCoordinates.last;
          final dx = current.x - lastKept.x;
          final dy = current.y - lastKept.y;
          final dz = current.z - lastKept.z;
          final distSq = dx * dx + dy * dy + dz * dz;
          if (distSq >= simplifyThresholdSq) {
            polygonCoordinates.add(current);
          }
        }
        if (rawCoordinates.length > 1) {
          polygonCoordinates.add(rawCoordinates.last);
        }
      }

      // Precompute polygon center
      var sumX = 0.0;
      var sumY = 0.0;
      var sumZ = 0.0;
      for (final v in polygonCoordinates) {
        sumX += v.x;
        sumY += v.y;
        sumZ += v.z;
      }
      final count = polygonCoordinates.length;
      var centerVec = Vector3(sumX / count, sumY / count, sumZ / count);
      final len = math.sqrt(centerVec.x * centerVec.x +
          centerVec.y * centerVec.y +
          centerVec.z * centerVec.z);
      if (len > 0.0001) {
        centerVec =
            Vector3(centerVec.x / len, centerVec.y / len, centerVec.z / len);
      } else if (polygonCoordinates.isNotEmpty) {
        centerVec = polygonCoordinates.first;
      } else {
        centerVec = Vector3(0.0, 0.0, 0.0);
      }

      // Precompute sinThetaMax
      var minDot = 1.0;
      for (final v in polygonCoordinates) {
        final dot = v.x * centerVec.x + v.y * centerVec.y + v.z * centerVec.z;
        if (dot < minDot) {
          minDot = dot;
        }
      }
      double sinThetaMax;
      if (minDot < 0.0) {
        sinThetaMax = 1.0;
      } else {
        sinThetaMax = math.sqrt((1.0 - minDot * minDot).clamp(0.0, 1.0));
      }

      result.add(
        CachedPolygonData(
          vertices: polygonCoordinates,
          center: centerVec,
          sinThetaMax: sinThetaMax,
        ),
      );
    }

    _regionCoordinateCache[region.id] = result;

    return result;
  }

  List<RegionRenderData> calculateRegionPositions({
    required List<GlobeRegion> regions,
    required double radius,
    required double rotationY,
    required double rotationZ,
    required Size canvasSize,
    Set<String> selectedRegionIds = const {},
    int regionRevision = 0,
  }) {
    // Check if cache is still valid (stationary state)
    final isCacheValid = _cachedRegionRenderData != null &&
        _lastRegionRadius == radius &&
        _lastRegionRotationY == rotationY &&
        _lastRegionRotationZ == rotationZ &&
        _lastRegionCanvasSize == canvasSize &&
        _lastRegionRevision == regionRevision &&
        identical(_lastRegions, regions) &&
        _lastRegionLength == regions.length &&
        setEquals(_lastRegionSelectedIds, selectedRegionIds);

    if (isCacheValid) {
      return _cachedRegionRenderData!;
    }

    final center = Offset(
      canvasSize.width / 2,
      canvasSize.height / 2,
    );

    final List<RegionRenderData> result = [];

    // Precompute trigonometric functions
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final cosZ = math.cos(rotationZ);
    final sinZ = math.sin(rotationZ);

    // Rotation matrix elements for R = Ry * Rz
    final r00 = cosY * cosZ;
    final r01 = -cosY * sinZ;
    final r02 = -sinY;
    final r10 = sinZ;
    final r11 = cosZ;
    final r20 = sinY * cosZ;
    final r21 = -sinY * sinZ;
    final r22 = cosY;

    // Combined rotation and projection factors
    final m10 = radius * r10;
    final m11 = radius * r11;
    final m20 = -radius * r20;
    final m21 = -radius * r21;
    final m22 = -radius * r22;

    for (final region in regions) {
      if (!region.isVisible) continue;

      final cachedPolygons = _getCachedRegionCoordinates(region);

      for (int polygonIndex = 0;
          polygonIndex < cachedPolygons.length;
          polygonIndex++) {
        final polygon = cachedPolygons[polygonIndex];

        // Bounding spherical cap check (filter out polygons entirely on the back side of the globe)
        final polyCenter = polygon.center;
        final centerRotatedX =
            r00 * polyCenter.x + r01 * polyCenter.y + r02 * polyCenter.z;

        // If the center is sufficiently on the back side, the entire polygon is invisible.
        if (centerRotatedX <= -polygon.sinThetaMax) {
          continue;
        }

        final fillColor = selectedRegionIds.contains(region.id) && region.highlightColor != null
            ? region.highlightColor!
            : region.fillColor;
        final needsFill = fillColor != null;

        final List<Path> borderPaths = [];
        Path? currentBorderPath;
        final polygonPath = Path();
        bool isFirst = true;

        for (final unitVector in polygon.vertices) {
          final x = unitVector.x;
          final y = unitVector.y;
          final z = unitVector.z;

          // Perform rotation directly
          final rotatedX = r00 * x + r01 * y + r02 * z;

          // Project for borders (only front-facing)
          if (rotatedX > 0) {
            final px = center.dx + m10 * x + m11 * y;
            final py = center.dy + m20 * x + m21 * y + m22 * z;

            if (currentBorderPath == null) {
              currentBorderPath = Path();
              currentBorderPath.moveTo(px, py);
            } else {
              currentBorderPath.lineTo(px, py);
            }
          } else {
            if (currentBorderPath != null) {
              borderPaths.add(currentBorderPath);
              currentBorderPath = null;
            }
          }

          // Project for polygon (clamp back-facing to horizon circle for fill & hit-testing)
          double fpx, fpy;
          if (rotatedX > 0) {
            fpx = center.dx + m10 * x + m11 * y;
            fpy = center.dy + m20 * x + m21 * y + m22 * z;
          } else {
            final ry = r10 * x + r11 * y;
            final rzVal = r20 * x + r21 * y + r22 * z;
            final d = math.sqrt(ry * ry + rzVal * rzVal);
            if (d > 0.0001) {
              fpx = center.dx + (ry / d) * radius;
              fpy = center.dy - (rzVal / d) * radius;
            } else {
              fpx = center.dx;
              fpy = center.dy;
            }
          }

          if (isFirst) {
            polygonPath.moveTo(fpx, fpy);
            isFirst = false;
          } else {
            polygonPath.lineTo(fpx, fpy);
          }
        }

        if (currentBorderPath != null) {
          borderPaths.add(currentBorderPath);
        }
        if (!isFirst) {
          polygonPath.close();
        }

        // If no parts of the polygon are visible, skip adding it
        if (borderPaths.isEmpty) {
          continue;
        }

        final fillPath = needsFill ? polygonPath : null;

        result.add(
          RegionRenderData(
            id: '${region.id}_$polygonIndex',
            baseId: region.id,
            region: region,
            visiblePaths: borderPaths,
            fillPath: fillPath,
            polygonPath: polygonPath,
            borderColor: region.borderColor,
            borderWidth: region.borderWidth,
            fillColor: region.fillColor,
            highlightColor: region.highlightColor,
            isSelected: selectedRegionIds.contains(region.id),
            isVisible: region.isVisible,
            clipAgainst: region.clipAgainst,
          ),
        );
      }
    }

    // Update stationary cache
    _cachedRegionRenderData = result;
    _lastRegionRadius = radius;
    _lastRegionRotationY = rotationY;
    _lastRegionRotationZ = rotationZ;
    _lastRegionCanvasSize = canvasSize;
    _lastRegions = regions;
    _lastRegionLength = regions.length;
    _lastRegionRevision = regionRevision;
    _lastRegionSelectedIds = Set.from(selectedRegionIds);

    return result;
  }

  /// Calculate render data for all connections (Globe.GL style)
  List<ArcRenderData> calculateConnectionPositions({
    required List<AnimatedPointConnection> connections,
    required double radius,
    required double rotationY,
    required double rotationZ,
    required Size canvasSize,
    required DateTime now,
  }) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final List<ArcRenderData> result = [];

    // Calculate delta time for dash animation
    final deltaMs = _lastFrameTime != null
        ? now.difference(_lastFrameTime!).inMilliseconds.toDouble()
        : 16.0;
    _lastFrameTime = now;

    for (final connection in connections) {
      // Initialize transition if new connection
      if (!_connectionTransitions.containsKey(connection.id)) {
        _connectionTransitions[connection.id] = TransitionState(addedAt: now);
        _dashOffsets[connection.id] = 0.0;
      }

      final transition = _connectionTransitions[connection.id]!;
      final elapsed = now.difference(transition.addedAt).inMilliseconds;

      // Update transition (fade in) progress
      final transitionDuration = connection.style.transitionDuration;
      transition.transitionProgress = transitionDuration > 0
          ? (elapsed / transitionDuration).clamp(0.0, 1.0)
          : 1.0;

      // Update growth animation progress
      final growthDuration = connection.style.growthAnimationDuration;
      if (connection.style.animateOnAdd) {
        transition.growthProgress = growthDuration > 0
            ? (elapsed / growthDuration).clamp(0.0, 1.0)
            : 1.0;
      } else {
        transition.growthProgress = 1.0;
      }

      // Update dash animation offset
      // Animate if dashAnimateTime is set (like Globe.GL's dashAnimateTime prop)
      // OR if isMoving is true (legacy behavior)
      if (connection.style.dashAnimateTime > 0 || connection.isMoving) {
        final animateTime = connection.style.dashAnimateTime > 0
            ? connection.style.dashAnimateTime
            : 1000.0; // Default 1 second if just isMoving
        final dashSpeed = 1.0 / animateTime;
        final dashIncrement = deltaMs * dashSpeed;
        _dashOffsets[connection.id] =
            ((_dashOffsets[connection.id] ?? 0.0) + dashIncrement) % 1.0;
      }

      // === Globe.GL Style Arc Calculation ===
      // Get 3D positions
      final startVec =
          getSpherePosition3D(connection.start, radius, rotationY, rotationZ);
      final endVec =
          getSpherePosition3D(connection.end, radius, rotationY, rotationZ);

      // Project to 2D
      final start2D = Offset(center.dx + startVec.y, center.dy - startVec.z);
      final end2D = Offset(center.dx + endVec.y, center.dy - endVec.z);

      // Calculate arc using Globe.GL's method:
      // altitude = geoDistance / 2 * altAutoScale (default 0.5)
      final centralAngle =
          calculateCentralAngle(connection.start, connection.end);
      final geoDistance = centralAngle; // In radians, proportional to distance

      // Globe.GL default: altitude = distance/2 * 0.5 = distance/4
      // Scaled by curveScale for user control
      final altitude = (geoDistance / 2) * 0.5 * connection.curveScale;
      final arcAltitude = radius * altitude;

      // Generate arc points - use more segments for smoother edge transitions
      // Higher resolution prevents visible "stepping" when arc disappears at sphere edge
      const numSegments =
          1000; // Higher than Globe.GL default for smoother clipping
      final List<Offset> arcPoints2D = [];
      final List<bool> arcPointsVisible = [];

      // Normalized start/end vectors
      final startNorm = startVec.normalized();
      final endNorm = endVec.normalized();

      for (int i = 0; i <= numSegments; i++) {
        final t = i / numSegments;

        // Spherical interpolation for the base point on the sphere
        final sinAngle = math.sin(centralAngle);
        double baseX, baseY, baseZ;

        if (sinAngle > 0.0001) {
          final a = math.sin((1 - t) * centralAngle) / sinAngle;
          final b = math.sin(t * centralAngle) / sinAngle;
          baseX = a * startNorm.x + b * endNorm.x;
          baseY = a * startNorm.y + b * endNorm.y;
          baseZ = a * startNorm.z + b * endNorm.z;
        } else {
          baseX = startNorm.x * (1 - t) + endNorm.x * t;
          baseY = startNorm.y * (1 - t) + endNorm.y * t;
          baseZ = startNorm.z * (1 - t) + endNorm.z * t;
        }

        // Normalize base point
        final baseLen =
            math.sqrt(baseX * baseX + baseY * baseY + baseZ * baseZ);
        if (baseLen > 0) {
          baseX /= baseLen;
          baseY /= baseLen;
          baseZ /= baseLen;
        }

        // Globe.GL altitude profile: smooth curve peaking at middle
        // Using sine profile for smoother arc (similar to Globe.GL's bezier)
        final altFactor = math.sin(t * math.pi);
        final currentAltitude = arcAltitude * altFactor;
        final currentRadius = radius + currentAltitude;

        // Final 3D position
        final arcX = baseX * currentRadius;
        final arcY = baseY * currentRadius;
        final arcZ = baseZ * currentRadius;

        // Project to 2D
        final point2D = Offset(center.dx + arcY, center.dy - arcZ);
        arcPoints2D.add(point2D);

        // Visibility check: for elevated arcs, we need to check if the point
        // would be occluded by the sphere.
        // In 2D projection, the sphere appears as a circle of radius `radius`.
        // An arc point at (arcX, arcY, arcZ) is visible if:
        // 1. It's in front of the sphere (arcX > 0), OR
        // 2. It's elevated above the sphere's visible edge
        //
        // For smooth edge transitions, we use the actual 3D geometry:
        // The visible horizon of the sphere is at x=0 (camera at infinity on +X).
        // For an elevated point at radius R+altitude, it becomes hidden when
        // arcX becomes negative enough that the sphere surface blocks it.

        final projectedDistFromCenter = math.sqrt(arcY * arcY + arcZ * arcZ);

        // For elevated arcs: calculate if the point is above the sphere's silhouette
        // The sphere silhouette is a circle of radius `radius` in the YZ plane
        // An elevated point appears "above" the silhouette if its 2D projection
        // is outside this circle
        final isAboveSilhouette =
            projectedDistFromCenter > radius && currentAltitude > 0;

        // For the front/back check, use a slightly lenient threshold
        // This prevents harsh cutting exactly at x=0
        // Points just behind the center plane but elevated should still show
        final horizonThreshold = -currentAltitude * 0.3;
        final isInFrontEnough = arcX > horizonThreshold;

        arcPointsVisible.add(isInFrontEnough || isAboveSilhouette);
      }

      // Calculate midpoint for label
      const midIdx = numSegments ~/ 2;
      final midPoint2D = arcPoints2D[midIdx];

      // Legacy control point
      var midPoint3D = (startVec + endVec) / 2;
      midPoint3D.normalize();
      midPoint3D.scale(radius + arcAltitude);
      final control2D =
          Offset(center.dx + midPoint3D.y, center.dy - midPoint3D.z);

      result.add(ArcRenderData(
        id: connection.id,
        start2D: start2D,
        end2D: end2D,
        control2D: control2D,
        midPoint2D: midPoint2D,
        arcPoints2D: arcPoints2D,
        arcPointsVisible: arcPointsVisible,
        isStartVisible: startVec.x > 0,
        isEndVisible: endVec.x > 0,
        isMidVisible: midPoint3D.x > 0,
        connection: connection,
        transitionProgress: transition.transitionProgress,
        growthProgress: transition.growthProgress,
        dashOffset: _dashOffsets[connection.id] ?? 0.0,
      ));
    }

    return result;
  }

  /// Calculate render data for all satellites
  List<SatelliteRenderData> calculateSatellitePositions({
    required List<Satellite> satellites,
    required double radius,
    required double rotationY,
    required double rotationZ,
    required Size canvasSize,
    required DateTime now,
  }) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final List<SatelliteRenderData> result = [];

    for (final satellite in satellites) {
      // Initialize transition if new satellite
      if (!_satelliteTransitions.containsKey(satellite.id)) {
        _satelliteTransitions[satellite.id] = TransitionState(addedAt: now);
      }

      // Update transition progress
      final transition = _satelliteTransitions[satellite.id]!;
      final elapsed = now.difference(transition.addedAt).inMilliseconds;
      final duration = satellite.style.transitionDuration;
      transition.transitionProgress =
          duration > 0 ? (elapsed / duration).clamp(0.0, 1.0) : 1.0;

      // Get current position (handles orbiting satellites)
      final currentPosition = satellite.getPositionAtTime(now);

      // Calculate satellite radius (globe radius + altitude)
      final satelliteRadius = radius * (1.0 + satellite.altitude);

      // Calculate 3D position at the satellite's altitude
      final cartesian3D = getSpherePosition3D(
        currentPosition,
        satelliteRadius,
        rotationY,
        rotationZ,
      );

      // Project to 2D
      final position2D = Offset(
        center.dx + cartesian3D.y,
        center.dy - cartesian3D.z,
      );

      // Visibility check - satellites above the globe can be visible even when
      // coordinates are "behind" the globe
      // Use the same logic as arc points for elevated objects
      final projectedDistFromCenter = math
          .sqrt(cartesian3D.y * cartesian3D.y + cartesian3D.z * cartesian3D.z);
      final isAboveSilhouette =
          projectedDistFromCenter > radius && satellite.altitude > 0;
      final horizonThreshold = -satellite.altitude * radius * 0.3;
      final isVisible = cartesian3D.x > horizonThreshold || isAboveSilhouette;

      // Depth calculation for scaling (normalized 0-1)
      final depth =
          isVisible ? (cartesian3D.x / satelliteRadius).clamp(0.0, 1.0) : 0.0;

      // Calculate surface normal
      final normalX = cartesian3D.x / satelliteRadius;
      final normalY = cartesian3D.y / satelliteRadius;
      final normalZ = cartesian3D.z / satelliteRadius;
      final tiltAngle = math.acos(normalX.clamp(-1.0, 1.0));

      // Calculate orbit path if enabled - use caching for performance
      List<Offset>? orbitPath2D;
      List<bool>? orbitPathVisible;

      if (satellite.style.showOrbitPath && satellite.orbit != null) {
        // Check if we have a valid cached orbit path
        final cachedPath = _orbitPathCache[satellite.id];
        if (cachedPath != null &&
            cachedPath.isValidFor(rotationY, rotationZ, satelliteRadius)) {
          // Use cached path - huge performance win!
          orbitPath2D = cachedPath.path2D;
          orbitPathVisible = cachedPath.pathVisible;
        } else {
          // Calculate new orbit path
          orbitPath2D = [];
          orbitPathVisible = [];

          // Generate orbit path points (reduced from 360 to 180 for performance)
          const numOrbitPoints = 180;
          final orbitPeriod = satellite.orbit!.period;

          for (int i = 0; i <= numOrbitPoints; i++) {
            final t = i / numOrbitPoints;
            final orbitTime = satellite.referenceTime.add(
              Duration(milliseconds: (orbitPeriod.inMilliseconds * t).round()),
            );

            final orbitPos = satellite.orbit!
                .getPositionAtTime(orbitTime, satellite.referenceTime);
            final orbitCartesian = getSpherePosition3D(
              orbitPos,
              satelliteRadius,
              rotationY,
              rotationZ,
            );

            final orbitPoint2D = Offset(
              center.dx + orbitCartesian.y,
              center.dy - orbitCartesian.z,
            );
            orbitPath2D.add(orbitPoint2D);

            // Visibility check for orbit path
            final orbitProjDist = math.sqrt(
                orbitCartesian.y * orbitCartesian.y +
                    orbitCartesian.z * orbitCartesian.z);
            final orbitAboveSilhouette =
                orbitProjDist > radius && satellite.altitude > 0;
            final orbitHorizonThreshold = -satellite.altitude * radius * 0.3;
            orbitPathVisible.add(orbitCartesian.x > orbitHorizonThreshold ||
                orbitAboveSilhouette);
          }

          // Cache the computed path
          _orbitPathCache[satellite.id] = CachedOrbitPath(
            path2D: orbitPath2D,
            pathVisible: orbitPathVisible,
            rotationY: rotationY,
            rotationZ: rotationZ,
            radius: satelliteRadius,
          );
        }
      }

      result.add(SatelliteRenderData(
        id: satellite.id,
        position2D: position2D,
        depth: depth,
        isVisible: isVisible,
        satellite: satellite,
        currentPosition: currentPosition,
        transitionProgress: transition.transitionProgress,
        normalX: normalX,
        normalY: normalY,
        normalZ: normalZ,
        tiltAngle: tiltAngle,
        orbitPath2D: orbitPath2D,
        orbitPathVisible: orbitPathVisible,
      ));
    }

    // Sort by depth (back to front) for proper overlapping
    result.sort((a, b) => a.depth.compareTo(b.depth));

    return result;
  }

  /// Clean up transitions and cached geometry for removed elements
  void cleanupRemovedElements(
      List<Point> points, List<AnimatedPointConnection> connections,
      [List<Satellite>? satellites, List<GlobeRegion>? regions]) {
    final pointIds = points.map((p) => p.id).toSet();
    final connectionIds = connections.map((c) => c.id).toSet();

    _pointTransitions.removeWhere((key, _) => !pointIds.contains(key));
    _connectionTransitions
        .removeWhere((key, _) => !connectionIds.contains(key));
    _dashOffsets.removeWhere((key, _) => !connectionIds.contains(key));

    if (satellites != null) {
      final satelliteIds = satellites.map((s) => s.id).toSet();
      _satelliteTransitions
          .removeWhere((key, _) => !satelliteIds.contains(key));
      // Also cleanup orbit path cache
      _orbitPathCache.removeWhere((key, _) => !satelliteIds.contains(key));
    }

    if (regions != null) {
      final regionIds = regions.map((r) => r.id).toSet();
      _regionCoordinateCache.removeWhere((key, _) => !regionIds.contains(key));
    }
  }

  /// Explicitly clear all cached region coordinates
  void clearRegionCoordinateCache() {
    _regionCoordinateCache.clear();
  }

  /// Explicitly remove cached coordinates for a specific region ID
  void removeRegionCoordinate(String id) {
    _regionCoordinateCache.remove(id);
  }
}

/// GPU-accelerated foreground painter using Fragment Shaders
class GpuForegroundPainter extends CustomPainter {
  final List<PointRenderData> points;
  final List<ArcRenderData> arcs;
  final List<SatelliteRenderData> satellites;
  final List<RegionRenderData> regions;
  final double radius;
  final Offset center;
  final Offset? hoverPoint;
  final Offset? clickPoint;

  // Whether to skip satellite shape drawing (when using GPU shader for satellites)
  // Orbit paths and labels will still be drawn via Canvas
  final bool skipSatelliteShapes;

  // Callbacks
  final void Function(
          String pointId, Offset? position, bool isHovering, bool isVisible)?
      onPointHover;
  final void Function(String connectionId, Offset? position, bool isHovering,
      bool isVisible)? onConnectionHover;
  final void Function(String satelliteId, Offset? position, bool isHovering,
      bool isVisible)? onSatelliteHover;
  final VoidCallback? onPointClicked;
  final void Function(GlobeRegion region)? onRegionTap;
  final void Function(GlobeRegion? region)? onRegionHover;

  // Previous state for change detection
  final String? previousHoveredPointId;
  final String? previousHoveredConnectionId;
  final String? previousHoveredSatelliteId;
  final String? previousHoveredRegionId;

  GpuForegroundPainter({
    required this.points,
    required this.arcs,
    required this.satellites,
    required this.regions,
    required this.radius,
    required this.center,
    this.hoverPoint,
    this.clickPoint,
    this.skipSatelliteShapes = false,
    this.onPointHover,
    this.onConnectionHover,
    this.onSatelliteHover,
    this.onPointClicked,
    this.onRegionTap,
    this.onRegionHover,
    this.previousHoveredPointId,
    this.previousHoveredConnectionId,
    this.previousHoveredSatelliteId,
    this.previousHoveredRegionId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    String? currentHoveredPointId;
    String? currentHoveredConnectionId;
    bool clickHandled = false;

    // Cache to avoid rebuilding the combined clip paths repeatedly on the same frame
    final Map<String, Path?> frameClipPathCache = {};

    // Draw all visible regions with generic clipping
    for (final region in regions) {
      if (!region.isVisible) continue;

      Path? inverseClipPath;
      if (region.clipAgainst.isNotEmpty) {
        final clipKey = (List<String>.from(region.clipAgainst)..sort()).join(',');

        if (frameClipPathCache.containsKey(clipKey)) {
          inverseClipPath = frameClipPathCache[clipKey];
        } else {
          final clipIds = region.clipAgainst.toSet();
          final combinedClipPath = Path();
          bool hasClips = false;

          for (final otherRegion in regions) {
            final otherBaseId = otherRegion.baseId;
            if (clipIds.contains(otherBaseId)) {
              if (otherRegion.polygonPath != null) {
                combinedClipPath.addPath(otherRegion.polygonPath!, Offset.zero);
                hasClips = true;
              } else {
                for (final path in otherRegion.visiblePaths) {
                  combinedClipPath.addPath(path, Offset.zero);
                  hasClips = true;
                }
              }
            }
          }

          if (hasClips) {
            inverseClipPath = Path()
              ..addRect(Rect.fromLTWH(-size.width, -size.height, size.width * 3, size.height * 3))
              ..addPath(combinedClipPath, Offset.zero);
            inverseClipPath.fillType = PathFillType.evenOdd;
          }
          frameClipPathCache[clipKey] = inverseClipPath;
        }
      }

      if (inverseClipPath != null) {
        canvas.save();
        canvas.clipPath(inverseClipPath);
        _drawRegion(canvas, region);
        canvas.restore();
      } else {
        _drawRegion(canvas, region);
      }
    }

    // Draw points first (behind arcs)
    for (final point in points) {
      if (!point.isVisible) {
        onPointHover?.call(point.id, point.position2D, false, false);
        continue;
      }

      _drawPoint(canvas, point);

      // Draw label (non-builder labels)
      if (point.point.isLabelVisible &&
          point.point.label != null &&
          point.point.label!.isNotEmpty &&
          point.point.labelBuilder == null) {
        _drawLabel(canvas, point.point.label!, point.point.labelTextStyle,
            point.position2D, size);
      }
    }

    // Draw arcs (on top of points)
    for (final arc in arcs) {
      // Check if any portion of the arc is visible (elevated arcs can peek over horizon)
      final hasVisiblePortion = arc.arcPointsVisible.any((v) => v);
      if (!hasVisiblePortion) {
        onConnectionHover?.call(arc.id, arc.midPoint2D, false, false);
        continue;
      }

      final path = _drawArc(canvas, arc, size);

      if (path != null) {
        // Check hover on arc (arcs have priority over points since they're on top)
        final isHovering = currentHoveredConnectionId == null &&
            hoverPoint != null &&
            _isPointOnPath(hoverPoint!, path, arc.connection.strokeWidth + 4);

        if (isHovering) {
          currentHoveredConnectionId = arc.id;
          if (arc.id != previousHoveredConnectionId) {
            arc.connection.onHover?.call();
          }
        }

        onConnectionHover?.call(arc.id, arc.midPoint2D, isHovering, true);

        // Handle click on arc first (since arcs are on top)
        if (!clickHandled &&
            clickPoint != null &&
            _isPointOnPath(clickPoint!, path, arc.connection.strokeWidth + 4)) {
          // Defer callback to after paint to avoid triggering widget builds during paint
          final callback = arc.connection.onTap;
          if (callback != null) {
            SchedulerBinding.instance.addPostFrameCallback((_) => callback());
          }
          onPointClicked?.call();
          clickHandled = true;
        }
      } else {
        onConnectionHover?.call(arc.id, arc.midPoint2D, false, false);
      }
    }

    // Handle point hover/click after drawing (points are behind arcs but still interactive)
    for (final point in points) {
      if (!point.isVisible) continue;

      // Calculate hit rect for hover/click
      final scaledSize = point.point.style.size * (0.7 + 0.6 * point.depth);
      final hitRect = Rect.fromCenter(
        center: point.position2D,
        width: scaledSize * 2 + 8, // Add padding for easier clicking
        height: scaledSize * 2 + 8,
      );

      final isHovering = currentHoveredPointId == null &&
          currentHoveredConnectionId == null && // Arc hover takes priority
          hoverPoint != null &&
          hitRect.contains(hoverPoint!);

      if (isHovering) {
        currentHoveredPointId = point.id;
        if (point.id != previousHoveredPointId) {
          point.point.onHover?.call();
        }
      }

      onPointHover?.call(
          point.id, point.position2D, isHovering, point.isVisible);

      // Handle click (arcs already handled, so only if not already clicked)
      if (!clickHandled &&
          clickPoint != null &&
          hitRect.contains(clickPoint!)) {
        // Defer callback to after paint to avoid triggering widget builds during paint
        final callback = point.point.onTap;
        if (callback != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) => callback());
        }
        onPointClicked?.call();
        clickHandled = true;
      }
    }

    // Draw satellites (on top of arcs, as they are elevated objects)
    String? currentHoveredSatelliteId;
    for (final satellite in satellites) {
      if (!satellite.isVisible) {
        onSatelliteHover?.call(
            satellite.id, satellite.position2D, false, false);
        continue;
      }

      // Draw orbit path first (behind the satellite) - always use Canvas for paths
      if (satellite.orbitPath2D != null && satellite.orbitPathVisible != null) {
        _drawOrbitPath(canvas, satellite);
      }

      // Draw the satellite shape (skip if using GPU shader for satellite shapes)
      if (!skipSatelliteShapes) {
        _drawSatellite(canvas, satellite);
      }

      // Draw label (non-builder labels) - always use Canvas for labels
      if (satellite.satellite.isLabelVisible &&
          satellite.satellite.label != null &&
          satellite.satellite.label!.isNotEmpty &&
          satellite.satellite.labelBuilder == null) {
        _drawLabel(
            canvas,
            satellite.satellite.label!,
            satellite.satellite.labelTextStyle,
            satellite.position2D + satellite.satellite.labelOffset,
            size);
      }

      // Calculate hit rect for hover/click
      final scaledSize =
          satellite.satellite.style.size * (0.7 + 0.6 * satellite.depth);
      final hitRect = Rect.fromCenter(
        center: satellite.position2D,
        width: scaledSize * 2 + 8,
        height: scaledSize * 2 + 8,
      );

      final isHovering = currentHoveredSatelliteId == null &&
          currentHoveredConnectionId == null &&
          currentHoveredPointId == null &&
          hoverPoint != null &&
          hitRect.contains(hoverPoint!);

      if (isHovering) {
        currentHoveredSatelliteId = satellite.id;
        if (satellite.id != previousHoveredSatelliteId) {
          satellite.satellite.onHover?.call();
        }
      }

      onSatelliteHover?.call(
          satellite.id, satellite.position2D, isHovering, true);

      // Handle click
      if (!clickHandled &&
          clickPoint != null &&
          hitRect.contains(clickPoint!)) {
        // Defer callback to after paint to avoid triggering widget builds during paint
        final callback = satellite.satellite.onTap;
        if (callback != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) => callback());
        }
        onPointClicked?.call();
        clickHandled = true;
      }
    }

    // Handle click on regions (only if not already handled by arcs, points, or satellites)
    if (!clickHandled && clickPoint != null && onRegionTap != null) {
      for (int i = regions.length - 1; i >= 0; i--) {
        final regionData = regions[i];
        if (!regionData.isVisible || regionData.polygonPath == null) continue;

        if (regionData.polygonPath!.contains(clickPoint!)) {
          final clipKey = regionData.clipAgainst.isNotEmpty
              ? (List<String>.from(regionData.clipAgainst)..sort()).join(',')
              : null;
          final clipPath = clipKey != null ? frameClipPathCache[clipKey] : null;
          if (clipPath != null && !clipPath.contains(clickPoint!)) {
            continue;
          }

          final callback = onRegionTap;
          final regionObj = regionData.region;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            callback?.call(regionObj);
          });
          onPointClicked?.call();
          clickHandled = true;
          break;
        }
      }
    }

    // Handle hover on regions (only if no arc, point, or satellite is hovered)
    if (hoverPoint != null &&
        currentHoveredConnectionId == null &&
        currentHoveredPointId == null &&
        currentHoveredSatelliteId == null &&
        onRegionHover != null) {
      String? currentHoveredRegionId;
      for (int i = regions.length - 1; i >= 0; i--) {
        final regionData = regions[i];
        if (!regionData.isVisible || regionData.polygonPath == null) continue;

        if (regionData.polygonPath!.contains(hoverPoint!)) {
          final clipKey = regionData.clipAgainst.isNotEmpty
              ? (List<String>.from(regionData.clipAgainst)..sort()).join(',')
              : null;
          final clipPath = clipKey != null ? frameClipPathCache[clipKey] : null;
          if (clipPath != null && !clipPath.contains(hoverPoint!)) {
            continue;
          }

          currentHoveredRegionId = regionData.baseId;
          if (currentHoveredRegionId != previousHoveredRegionId) {
            final callback = onRegionHover;
            final regionObj = regionData.region;
            SchedulerBinding.instance.addPostFrameCallback((_) {
              callback?.call(regionObj);
            });
          }
          break;
        }
      }

      if (currentHoveredRegionId == null && previousHoveredRegionId != null) {
        final callback = onRegionHover;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          callback?.call(null);
        });
      }
    }
  }

  Path? _drawArc(Canvas canvas, ArcRenderData arc, Size size) {
    final connection = arc.connection;

    // Scale relative to globe size
    const baseRadius = 150.0;
    final globeScale = radius / baseRadius;

    // Apply growth animation to animation progress
    final effectiveProgress = arc.growthProgress * connection.animationProgress;
    if (effectiveProgress <= 0) return null;

    // Check for invalid/NaN coordinates
    if (arc.start2D.dx.isNaN ||
        arc.start2D.dy.isNaN ||
        arc.end2D.dx.isNaN ||
        arc.end2D.dy.isNaN) {
      return null;
    }

    // Skip if start and end are the same
    if ((arc.start2D - arc.end2D).distance < 1) {
      return null;
    }

    final paint = Paint()
      ..color = connection.style.color.withAlpha(
          (connection.style.color.a * arc.transitionProgress * 255).round())
      ..strokeWidth = connection.style.lineWidth * globeScale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Build path from pre-calculated arc points (follows great circle on sphere)
    if (arc.arcPoints2D.length < 2) return null;

    // Apply growth animation - limit how far along the arc we draw
    final progressIdx =
        ((arc.arcPoints2D.length - 1) * effectiveProgress).round();
    if (progressIdx < 1) return null;

    // Globe.GL style: draw only the visible segments
    // Build path with gaps where segments are hidden behind the sphere
    final path = Path();
    bool inPath = false;
    int? lastVisibleIdx;

    for (int i = 0; i <= progressIdx; i++) {
      final isVisible = arc.arcPointsVisible[i];
      final point = arc.arcPoints2D[i];

      if (isVisible) {
        if (!inPath) {
          // Starting a new visible segment
          path.moveTo(point.dx, point.dy);
          inPath = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
        lastVisibleIdx = i;
      } else {
        // Hidden segment - end current path segment
        inPath = false;
      }
    }

    // If no visible segments, don't draw
    if (lastVisibleIdx == null) return null;

    // Calculate the visible path for hit detection and styling
    final pathMetricsList = path.computeMetrics().toList();

    if (pathMetricsList.isEmpty) return null;

    // Get total length across all path segments
    double totalLength = 0;
    for (final metric in pathMetricsList) {
      totalLength += metric.length;
    }

    if (totalLength < 1) return null;

    switch (connection.style.type) {
      case PointConnectionType.solid:
        canvas.drawPath(path, paint);
        break;

      case PointConnectionType.dashed:
        final dashLength = connection.style.dashSize * globeScale;
        final gapLength = connection.style.spacing * globeScale;
        final patternLength = dashLength + gapLength;

        // Calculate dash offset based on arc.dashOffset (0-1 normalized)
        final animatedOffset = arc.dashOffset * patternLength;

        // Draw dashes across all path segments
        for (final metric in pathMetricsList) {
          double distance = animatedOffset % patternLength;
          while (distance < metric.length) {
            final startDash = distance;
            final endDash = math.min(startDash + dashLength, metric.length);

            if (startDash < metric.length) {
              final startTangent = metric.getTangentForOffset(startDash);
              final endTangent = metric.getTangentForOffset(endDash);

              if (startTangent != null && endTangent != null) {
                canvas.drawLine(
                    startTangent.position, endTangent.position, paint);
              }
            }
            distance += patternLength;
          }
        }
        break;

      case PointConnectionType.dotted:
        final spacing = connection.style.spacing * globeScale;
        final animatedOffset = arc.dashOffset * spacing;
        final dotSize = connection.style.dotSize * globeScale;

        // Draw dots across all path segments
        for (final metric in pathMetricsList) {
          double distance = animatedOffset % spacing;
          while (distance < metric.length) {
            final tangent = metric.getTangentForOffset(distance);
            if (tangent != null) {
              canvas.drawCircle(tangent.position, dotSize, paint);
            }
            distance += spacing;
          }
        }
        break;
    }

    // Draw label
    if (connection.isLabelVisible &&
        connection.label != null &&
        connection.label!.isNotEmpty &&
        connection.labelBuilder == null) {
      _drawLabel(canvas, connection.label!, connection.labelTextStyle,
          arc.midPoint2D, size);
    }

    return path;
  }

  void _drawPoint(Canvas canvas, PointRenderData point) {
    final style = point.point.style;

    // Scale point relative to globe size
    // Use a base reference radius (150) so points scale with zoom
    const baseRadius = 150.0;
    final globeScale = radius / baseRadius;

    // Scale point based on depth (closer = larger)
    final depthScale = 0.7 + 0.6 * point.depth;
    final scaledSize = style.size * depthScale * globeScale;

    // Apply transition animation
    final alpha = style.color.a * point.transitionProgress;

    // Draw point with altitude effect
    final altitudeOffset = style.altitude * point.depth * 2.0 * globeScale;
    final drawPos =
        Offset(point.position2D.dx, point.position2D.dy - altitudeOffset);

    // === Globe.GL Style 3D Tilted Point ===
    // The point should appear as if it's a disc lying flat on the sphere surface
    // We're viewing the disc from an angle, so it appears as an ellipse

    // The foreshortening factor based on how tilted the surface is
    // normalX is how much the surface faces the camera (1 = facing, 0 = edge)
    final foreshortening = point.normalX.abs().clamp(0.1, 1.0);

    // Calculate the angle at which to orient the ellipse
    // The ellipse major axis should be PERPENDICULAR to the radial direction from center
    // normalY = horizontal position (but screen X increases right, so negate)
    // normalZ = vertical position on sphere
    // The foreshortening happens toward the center of the sphere
    final angleToCenter = math.atan2(point.normalZ, -point.normalY);

    // Full size for the major axis (tangent to sphere surface)
    final majorAxis = scaledSize * 2.0;
    // Compressed size for minor axis (radial direction, foreshortened)
    final minorAxis = scaledSize * 2.0 * foreshortening;

    canvas.save();
    canvas.translate(drawPos.dx, drawPos.dy);
    // Rotate so the minor axis points toward sphere center
    canvas.rotate(angleToCenter + math.pi / 2);

    // Draw the main colored disc
    final paint = Paint()
      ..color = style.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    // Width = major axis (full), Height = minor axis (foreshortened)
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: majorAxis,
      height: minorAxis,
    );
    canvas.drawOval(rect, paint);

    canvas.restore();
  }

  void _drawSatellite(Canvas canvas, SatelliteRenderData satellite) {
    final style = satellite.satellite.style;

    // Scale satellite relative to globe size
    const baseRadius = 150.0;
    final globeScale = radius / baseRadius;

    // Scale based on depth and size attenuation
    final depthScale =
        style.sizeAttenuation ? (0.7 + 0.6 * satellite.depth) : 1.0;
    final scaledSize = style.size * depthScale * globeScale;

    // Apply transition animation
    final alpha = style.color.a * satellite.transitionProgress;

    // Draw glow effect first (behind the satellite)
    if (style.hasGlow) {
      final glowColor = style.glowColor ?? style.color;
      final glowPaint = Paint()
        ..color = glowColor
            .withAlpha((alpha * style.glowIntensity * 0.5 * 255).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scaledSize * 1.5);
      canvas.drawCircle(satellite.position2D, scaledSize * 1.5, glowPaint);
    }

    // Draw the satellite based on shape
    final paint = Paint()
      ..color = style.color.withAlpha((alpha * 255).round())
      ..style = PaintingStyle.fill;

    switch (style.shape) {
      case SatelliteShape.circle:
        canvas.drawCircle(satellite.position2D, scaledSize, paint);
        break;

      case SatelliteShape.square:
        final rect = Rect.fromCenter(
          center: satellite.position2D,
          width: scaledSize * 2,
          height: scaledSize * 2,
        );
        canvas.save();
        canvas.translate(satellite.position2D.dx, satellite.position2D.dy);
        canvas.rotate(math.pi / 4); // Rotate 45 degrees for diamond shape
        canvas.translate(-satellite.position2D.dx, -satellite.position2D.dy);
        canvas.drawRect(rect, paint);
        canvas.restore();
        break;

      case SatelliteShape.triangle:
        final path = Path();
        path.moveTo(
            satellite.position2D.dx, satellite.position2D.dy - scaledSize);
        path.lineTo(satellite.position2D.dx - scaledSize * 0.866,
            satellite.position2D.dy + scaledSize * 0.5);
        path.lineTo(satellite.position2D.dx + scaledSize * 0.866,
            satellite.position2D.dy + scaledSize * 0.5);
        path.close();
        canvas.drawPath(path, paint);
        break;

      case SatelliteShape.star:
        _drawStar(canvas, satellite.position2D, scaledSize, paint);
        break;

      case SatelliteShape.satelliteIcon:
        _drawSatelliteIcon(canvas, satellite.position2D, scaledSize, paint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    const innerRadius = 0.4;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? size : size * innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSatelliteIcon(
      Canvas canvas, Offset center, double size, Paint paint) {
    // Draw a simple satellite shape: body with two solar panels
    final bodySize = size * 0.6;
    final panelWidth = size * 0.8;
    final panelHeight = size * 0.3;

    // Body (rectangle)
    final bodyRect = Rect.fromCenter(
      center: center,
      width: bodySize,
      height: bodySize,
    );
    canvas.drawRect(bodyRect, paint);

    // Left solar panel
    final leftPanel = Rect.fromCenter(
      center: Offset(center.dx - bodySize / 2 - panelWidth / 2, center.dy),
      width: panelWidth,
      height: panelHeight,
    );
    canvas.drawRect(leftPanel, paint);

    // Right solar panel
    final rightPanel = Rect.fromCenter(
      center: Offset(center.dx + bodySize / 2 + panelWidth / 2, center.dy),
      width: panelWidth,
      height: panelHeight,
    );
    canvas.drawRect(rightPanel, paint);
  }

  void _drawOrbitPath(Canvas canvas, SatelliteRenderData satellite) {
    if (satellite.orbitPath2D == null || satellite.orbitPathVisible == null) {
      return;
    }

    final style = satellite.satellite.style;
    final alpha = style.orbitPathColor.a * satellite.transitionProgress * 255;

    final paint = Paint()
      ..color = style.orbitPathColor.withAlpha(alpha.round())
      ..strokeWidth = style.orbitPathWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Build path with gaps where segments are hidden
    final path = Path();
    bool inPath = false;

    for (int i = 0; i < satellite.orbitPath2D!.length; i++) {
      final isVisible = satellite.orbitPathVisible![i];
      final point = satellite.orbitPath2D![i];

      if (isVisible) {
        if (!inPath) {
          path.moveTo(point.dx, point.dy);
          inPath = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      } else {
        inPath = false;
      }
    }

    if (style.orbitPathDashed) {
      // Draw dashed line
      final pathMetrics = path.computeMetrics();
      const dashLength = 5.0;
      const gapLength = 3.0;

      for (final metric in pathMetrics) {
        double distance = 0;
        while (distance < metric.length) {
          final startDash = distance;
          final endDash = math.min(startDash + dashLength, metric.length);

          if (startDash < metric.length) {
            final startTangent = metric.getTangentForOffset(startDash);
            final endTangent = metric.getTangentForOffset(endDash);

            if (startTangent != null && endTangent != null) {
              canvas.drawLine(
                  startTangent.position, endTangent.position, paint);
            }
          }
          distance += dashLength + gapLength;
        }
      }
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _drawLabel(Canvas canvas, String text, TextStyle? style, Offset position,
      Size size) {
    final textStyle =
        style ?? const TextStyle(color: Colors.white, fontSize: 12);
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height - 8,
    );

    // Ensure label stays within bounds
    final clampedOffset = Offset(
      offset.dx.clamp(0, size.width - textPainter.width),
      offset.dy.clamp(0, size.height - textPainter.height),
    );

    textPainter.paint(canvas, clampedOffset);
  }

  bool _isPointOnPath(Offset point, Path path, double tolerance) {
    // Approximate by sampling path
    final metricsList = path.computeMetrics().toList();
    if (metricsList.isEmpty) return false;

    final metric = metricsList.first;
    const samples = 50;

    for (int i = 0; i <= samples; i++) {
      final t = metric.length * i / samples;
      final tangent = metric.getTangentForOffset(t);
      if (tangent != null) {
        if ((tangent.position - point).distance <= tolerance) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant GpuForegroundPainter oldDelegate) {
    // Only repaint if the render data has changed
    // The CustomPaint is already being rebuilt by ValueListenableBuilder when animation updates
    // so we can compare the actual data to avoid redundant repaints
    return points != oldDelegate.points ||
        arcs != oldDelegate.arcs ||
        satellites != oldDelegate.satellites ||
        regions != oldDelegate.regions ||
        hoverPoint != oldDelegate.hoverPoint ||
        clickPoint != oldDelegate.clickPoint ||
        radius != oldDelegate.radius ||
        center != oldDelegate.center;
  }

  void _drawRegion(
    Canvas canvas,
    RegionRenderData region,
  ) {
    // Draw the fill first so the border remains visible on top.
    final fillColor = region.isSelected && region.highlightColor != null
        ? region.highlightColor!
        : region.fillColor;

    if (fillColor != null && region.fillPath != null) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor;

      canvas.drawPath(region.fillPath!, fillPaint);
    }

    if (region.visiblePaths.isNotEmpty) {
      // Draw the border on top.
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = region.borderWidth
        ..color = region.borderColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (final path in region.visiblePaths) {
        canvas.drawPath(path, borderPaint);
      }
    }
  }
}
