import 'dart:convert';

import 'package:flutter/material.dart';

/// Represents the type of connection between points.
enum PointConnectionType {
  /// A solid line connection.
  solid,

  /// A dashed line connection.
  dashed,

  /// A dotted line connection.
  dotted,
}

/// Represents the style of point connection.
///
/// Modeled after Globe.GL's arc styling with properties for:
/// - Dash animation timing (arcDashAnimateTime)
/// - Arc altitude (arcAltitude)
/// - Transition animations (arcsTransitionDuration)
class PointConnectionStyle {
  /// The type of connection.
  final PointConnectionType type;

  /// The size of the dots in the connection.
  final double dotSize;

  /// The spacing between dots in the connection.
  final double spacing;

  /// The size of the dashes in the connection.
  final double dashSize;

  /// The width of the line in the connection.
  final double lineWidth;

  /// The color of the connection.
  final Color color;

  /// Time in milliseconds for a dash to travel the full arc length.
  /// Set to 0 to disable dash animation.
  /// Similar to Globe.GL's arcDashAnimateTime.
  final int dashAnimateTime;

  /// Duration in milliseconds for the arc to animate when appearing/disappearing.
  /// Similar to Globe.GL's arcsTransitionDuration.
  final int transitionDuration;

  /// Whether the arc should animate growing from start to end when first appearing.
  /// Similar to Globe.GL's arc stroke animation.
  final bool animateOnAdd;

  /// Duration in milliseconds for the arc growth animation.
  final int growthAnimationDuration;

  /// Creates a new instance of [PointConnectionStyle].
  ///
  /// The [type] parameter specifies the type of connection. The default value is [PointConnectionType.solid].
  ///
  /// The [color] parameter specifies the color of the connection. The default value is [Colors.white].
  ///
  /// The [dotSize] parameter specifies the size of the dots in the connection. The default value is 1.
  ///
  /// The [lineWidth] parameter specifies the width of the line in the connection. The default value is 1.
  ///
  /// The [dashSize] parameter specifies the size of the dashes in the connection. The default value is 4.
  ///
  /// The [spacing] parameter specifies the spacing between dots in the connection. The default value is 8.
  ///
  /// The [dashAnimateTime] parameter specifies the time in ms for a dash to travel the arc. Default is 0 (disabled).
  ///
  /// The [transitionDuration] parameter specifies the fade in/out duration in ms. Default is 500.
  ///
  /// The [animateOnAdd] parameter enables arc growth animation. Default is true.
  ///
  /// The [growthAnimationDuration] parameter specifies arc growth duration in ms. Default is 1000.
  ///
  /// Example usage:
  /// ```dart
  /// PointConnectionStyle(
  ///   type: PointConnectionType.dashed,
  ///   color: Colors.white,
  ///   dashSize: 4,
  ///   spacing: 8,
  ///   dashAnimateTime: 2000, // Dashes move along arc over 2 seconds
  ///   transitionDuration: 500,
  ///   animateOnAdd: true,
  ///   growthAnimationDuration: 1000,
  /// );
  /// ```
  const PointConnectionStyle({
    this.type = PointConnectionType.solid,
    this.color = Colors.white,
    this.dotSize = 1,
    this.lineWidth = 1,
    this.dashSize = 4,
    this.spacing = 8,
    this.dashAnimateTime = 0,
    this.transitionDuration = 500,
    this.animateOnAdd = true,
    this.growthAnimationDuration = 1000,
  });

  /// Converts the [PointConnectionStyle] object to a map.
  ///
  /// Returns a map representation of the [PointConnectionStyle] object.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'dotSize': dotSize,
      'spacing': spacing,
      'dashSize': dashSize,
      'lineWidth': lineWidth,
      'color': color.toARGB32(),
      'dashAnimateTime': dashAnimateTime,
      'transitionDuration': transitionDuration,
      'animateOnAdd': animateOnAdd,
      'growthAnimationDuration': growthAnimationDuration,
    };
  }

  /// Creates a [PointConnectionStyle] object from a map.
  ///
  /// The [map] parameter is a map representation of the [PointConnectionStyle] object.
  factory PointConnectionStyle.fromMap(Map<String, dynamic> map) {
    return PointConnectionStyle(
      type: PointConnectionType.values.byName(map['type']),
      dotSize: map['dotSize'] as double,
      spacing: map['spacing'] as double,
      dashSize: map['dashSize'] as double,
      lineWidth: map['lineWidth'] as double,
      color: Color(map['color'] as int),
      dashAnimateTime: map['dashAnimateTime'] as int? ?? 0,
      transitionDuration: map['transitionDuration'] as int? ?? 500,
      animateOnAdd: map['animateOnAdd'] as bool? ?? true,
      growthAnimationDuration: map['growthAnimationDuration'] as int? ?? 1000,
    );
  }

  /// Converts the [PointConnectionStyle] object to a JSON string.
  ///
  /// Returns a JSON string representation of the [PointConnectionStyle] object.
  String toJson() => json.encode(toMap());

  /// Creates a [PointConnectionStyle] object from a JSON string.
  ///
  /// The [source] parameter is a JSON string representation of the [PointConnectionStyle] object.
  factory PointConnectionStyle.fromJson(String source) =>
      PointConnectionStyle.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Creates a copy of [PointConnectionStyle] with optionally updated properties.
  PointConnectionStyle copyWith({
    PointConnectionType? type,
    double? dotSize,
    double? spacing,
    double? dashSize,
    double? lineWidth,
    Color? color,
    int? dashAnimateTime,
    int? transitionDuration,
    bool? animateOnAdd,
    int? growthAnimationDuration,
  }) {
    return PointConnectionStyle(
      type: type ?? this.type,
      dotSize: dotSize ?? this.dotSize,
      spacing: spacing ?? this.spacing,
      dashSize: dashSize ?? this.dashSize,
      lineWidth: lineWidth ?? this.lineWidth,
      color: color ?? this.color,
      dashAnimateTime: dashAnimateTime ?? this.dashAnimateTime,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      animateOnAdd: animateOnAdd ?? this.animateOnAdd,
      growthAnimationDuration:
          growthAnimationDuration ?? this.growthAnimationDuration,
    );
  }
}
