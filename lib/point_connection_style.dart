import 'dart:convert';

import 'package:flutter/material.dart';

/// This enum defines the type of the connection between two points.
enum PointConnectionType { solid, dashed, dotted }

/// This class defines the style of the connection between two points.
class PointConnectionStyle {
  final PointConnectionType type;
  final double dotSize;
  final double spacing;
  final double dashSize;
  final double lineWidth;
  final Color color;

  const PointConnectionStyle(
      {this.type = PointConnectionType.solid,
      this.color = Colors.white,
      this.dotSize = 1,
      this.lineWidth = 1,
      this.dashSize = 4,
      this.spacing = 8});

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

  String toJson() => json.encode(toMap());

  factory PointConnectionStyle.fromJson(String source) =>
      PointConnectionStyle.fromMap(json.decode(source) as Map<String, dynamic>);
}
