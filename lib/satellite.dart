// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'globe_coordinates.dart';

/// Shapes available for satellite markers.
enum SatelliteShape {
  /// A circular marker (default).
  circle,

  /// A square/diamond marker.
  square,

  /// A triangle marker pointing in the direction of travel.
  triangle,

  /// A star-shaped marker.
  star,

  /// A satellite icon shape.
  satelliteIcon,
}

/// Represents the style of a satellite.
class SatelliteStyle {
  final double size;
  final Color color;
  final bool hasGlow;
  final Color? glowColor;
  final double glowIntensity;
  final bool sizeAttenuation;
  final int transitionDuration;
  final SatelliteShape shape;
  final bool showOrbitPath;
  final Color orbitPathColor;
  final double orbitPathWidth;
  final bool orbitPathDashed;

  const SatelliteStyle({
    this.size = 4.0,
    this.color = Colors.white,
    this.hasGlow = false,
    this.glowColor,
    this.glowIntensity = 0.5,
    this.sizeAttenuation = true,
    this.transitionDuration = 500,
    this.shape = SatelliteShape.circle,
    this.showOrbitPath = false,
    this.orbitPathColor = const Color(0x4DFFFFFF),
    this.orbitPathWidth = 1.0,
    this.orbitPathDashed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'color': color.value,
      'hasGlow': hasGlow,
      'glowColor': glowColor?.value,
      'glowIntensity': glowIntensity,
      'sizeAttenuation': sizeAttenuation,
      'transitionDuration': transitionDuration,
      'shape': shape.index,
      'showOrbitPath': showOrbitPath,
      'orbitPathColor': orbitPathColor.value,
      'orbitPathWidth': orbitPathWidth,
      'orbitPathDashed': orbitPathDashed,
    };
  }

  factory SatelliteStyle.fromMap(Map<String, dynamic> map) {
    return SatelliteStyle(
      size: map['size'] as double? ?? 4.0,
      color: Color(map['color'] as int? ?? 0xFFFFFFFF),
      hasGlow: map['hasGlow'] as bool? ?? false,
      glowColor:
          map['glowColor'] != null ? Color(map['glowColor'] as int) : null,
      glowIntensity: map['glowIntensity'] as double? ?? 0.5,
      sizeAttenuation: map['sizeAttenuation'] as bool? ?? true,
      transitionDuration: map['transitionDuration'] as int? ?? 500,
      shape: SatelliteShape.values[map['shape'] as int? ?? 0],
      showOrbitPath: map['showOrbitPath'] as bool? ?? false,
      orbitPathColor: Color(map['orbitPathColor'] as int? ?? 0x4DFFFFFF),
      orbitPathWidth: map['orbitPathWidth'] as double? ?? 1.0,
      orbitPathDashed: map['orbitPathDashed'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory SatelliteStyle.fromJson(String source) =>
      SatelliteStyle.fromMap(json.decode(source) as Map<String, dynamic>);

  SatelliteStyle copyWith({
    double? size,
    Color? color,
    bool? hasGlow,
    Color? glowColor,
    double? glowIntensity,
    bool? sizeAttenuation,
    int? transitionDuration,
    SatelliteShape? shape,
    bool? showOrbitPath,
    Color? orbitPathColor,
    double? orbitPathWidth,
    bool? orbitPathDashed,
  }) {
    return SatelliteStyle(
      size: size ?? this.size,
      color: color ?? this.color,
      hasGlow: hasGlow ?? this.hasGlow,
      glowColor: glowColor ?? this.glowColor,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      sizeAttenuation: sizeAttenuation ?? this.sizeAttenuation,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      shape: shape ?? this.shape,
      showOrbitPath: showOrbitPath ?? this.showOrbitPath,
      orbitPathColor: orbitPathColor ?? this.orbitPathColor,
      orbitPathWidth: orbitPathWidth ?? this.orbitPathWidth,
      orbitPathDashed: orbitPathDashed ?? this.orbitPathDashed,
    );
  }
}

/// Represents orbital parameters for an animated satellite.
class SatelliteOrbit {
  final double inclination;
  final double raan;
  final Duration period;
  final double initialPhase;
  final double eccentricity;
  final double argumentOfPeriapsis;

  const SatelliteOrbit({
    this.inclination = 0.0,
    this.raan = 0.0,
    required this.period,
    this.initialPhase = 0.0,
    this.eccentricity = 0.0,
    this.argumentOfPeriapsis = 0.0,
  });

  GlobeCoordinates getPositionAtTime(DateTime time, DateTime referenceTime) {
    final elapsedMs = time.difference(referenceTime).inMilliseconds;
    final periodMs = period.inMilliseconds;

    if (periodMs <= 0) {
      return const GlobeCoordinates(0, 0);
    }

    final phaseRad =
        (initialPhase * math.pi / 180) + (2 * math.pi * elapsedMs / periodMs);
    final trueAnomaly = phaseRad;

    final incRad = inclination * math.pi / 180;
    final raanRad = raan * math.pi / 180;
    final argPeriRad = argumentOfPeriapsis * math.pi / 180;

    final u = trueAnomaly + argPeriRad;

    final latitude = math.asin(math.sin(incRad) * math.sin(u)) * 180 / math.pi;
    final longitude =
        (raanRad + math.atan2(math.cos(incRad) * math.sin(u), math.cos(u))) *
            180 /
            math.pi;

    var normalizedLon = longitude % 360;
    if (normalizedLon > 180) normalizedLon -= 360;
    if (normalizedLon < -180) normalizedLon += 360;

    return GlobeCoordinates(latitude, normalizedLon);
  }

  Map<String, dynamic> toMap() {
    return {
      'inclination': inclination,
      'raan': raan,
      'period': period.inMilliseconds,
      'initialPhase': initialPhase,
      'eccentricity': eccentricity,
      'argumentOfPeriapsis': argumentOfPeriapsis,
    };
  }

  factory SatelliteOrbit.fromMap(Map<String, dynamic> map) {
    return SatelliteOrbit(
      inclination: map['inclination'] as double? ?? 0.0,
      raan: map['raan'] as double? ?? 0.0,
      period: Duration(milliseconds: map['period'] as int),
      initialPhase: map['initialPhase'] as double? ?? 0.0,
      eccentricity: map['eccentricity'] as double? ?? 0.0,
      argumentOfPeriapsis: map['argumentOfPeriapsis'] as double? ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SatelliteOrbit.fromJson(String source) =>
      SatelliteOrbit.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Represents a satellite orbiting around the globe.
class Satellite {
  final String id;
  final String? label;
  final Widget? Function(BuildContext context, Satellite satellite,
      bool isHovering, bool isVisible)? labelBuilder;
  final bool isLabelVisible;
  final Offset labelOffset;
  final TextStyle? labelTextStyle;
  final SatelliteStyle style;
  final GlobeCoordinates coordinates;
  final double altitude;
  final SatelliteOrbit? orbit;
  final VoidCallback? onTap;
  final VoidCallback? onHover;
  final DateTime referenceTime;

  Satellite({
    required this.id,
    required this.coordinates,
    this.altitude = 0.1,
    this.label,
    this.labelBuilder,
    this.isLabelVisible = false,
    this.labelOffset = const Offset(0, 0),
    this.style = const SatelliteStyle(),
    this.labelTextStyle,
    this.orbit,
    this.onTap,
    this.onHover,
    DateTime? referenceTime,
  }) : referenceTime = referenceTime ?? DateTime.now();

  GlobeCoordinates getPositionAtTime(DateTime time) {
    if (orbit != null) {
      return orbit!.getPositionAtTime(time, referenceTime);
    }
    return coordinates;
  }

  Satellite copyWith({
    String? id,
    GlobeCoordinates? coordinates,
    double? altitude,
    String? label,
    Widget? Function(BuildContext context, Satellite satellite, bool isHovering,
            bool isVisible)?
        labelBuilder,
    bool? isLabelVisible,
    Offset? labelOffset,
    SatelliteStyle? style,
    TextStyle? labelTextStyle,
    SatelliteOrbit? orbit,
    VoidCallback? onTap,
    VoidCallback? onHover,
    DateTime? referenceTime,
  }) {
    return Satellite(
      id: id ?? this.id,
      coordinates: coordinates ?? this.coordinates,
      altitude: altitude ?? this.altitude,
      label: label ?? this.label,
      labelBuilder: labelBuilder ?? this.labelBuilder,
      isLabelVisible: isLabelVisible ?? this.isLabelVisible,
      labelOffset: labelOffset ?? this.labelOffset,
      style: style ?? this.style,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      orbit: orbit ?? this.orbit,
      onTap: onTap ?? this.onTap,
      onHover: onHover ?? this.onHover,
      referenceTime: referenceTime ?? this.referenceTime,
    );
  }
}
