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
  /// Example usage:
  /// ```dart
  /// PointConnectionStyle(
  /// type: PointConnectionType.solid,
  /// color: Colors.white,
  /// dotSize: 1,
  /// lineWidth: 1,
  /// dashSize: 4,
  /// spacing: 8,
  /// );
  /// ```
  const PointConnectionStyle({
    this.type = PointConnectionType.solid,
    this.color = Colors.white,
    this.dotSize = 1,
    this.lineWidth = 1,
    this.dashSize = 4,
    this.spacing = 8,
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
      'color': color.value,
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
}
