// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';

import 'globe_coordinates.dart';

/// Represents a point on a globe.
class Point {
  /// The coordinates of the point on the globe.
  final GlobeCoordinates coordinates;

  /// The label text of the point.
  final String? label;

  /// A builder function that returns a widget to display as the label of the point.
  final Widget? Function(
          BuildContext context, Point point, bool isHovering, bool isVisible)?
      labelBuilder;

  /// Determines whether the label is visible or not.
  final bool isLabelVisible;

  /// The offset of the label from the point.
  final Offset labelOffset;

  /// The unique identifier of the point.
  final String id;

  /// The style of the point.
  PointStyle style;

  /// The text style of the label.
  final TextStyle? labelTextStyle;

  /// A callback function that is called when the point is tapped.
  final VoidCallback? onTap;

  /// A callback function that is called when the point is hovered over.
  final VoidCallback? onHover;

  /// Creates a new instance of the [Point] class.
  ///
  /// The [coordinates] parameter represents the coordinates of the point on the globe.
  /// The [label] parameter is the label text of the point.
  /// The [labelBuilder] parameter is a builder function that returns a widget to display as the label of the point.
  /// The [isLabelVisible] parameter determines whether the label is visible or not.
  /// The [labelOffset] parameter is the offset of the label from the point.
  /// The [id] parameter is the unique identifier of the point.
  /// The [style] parameter is the style of the point.
  /// The [labelTextStyle] parameter is the text style of the label.
  /// The [onTap] parameter is a callback function that is called when the point is tapped.
  /// The [onHover] parameter is a callback function that is called when the point is hovered over.
  ///
  /// Example usage:
  /// ```dart
  ///   Point(
  ///     coordinates: GlobeCoordinates(0, 0),
  ///     label: 'Center of Globe',
  ///     labelBuilder: (context, point, isHovering, isVisible) {
  ///       return Text('This is the center');
  ///     },
  ///     isLabelVisible: true,
  ///     labelOffset: Offset(0, 0),
  ///     id: '0',
  ///     style: PointStyle(),
  ///     labelTextStyle: TextStyle(),
  ///     onTap: () {
  ///       print('Point tapped');
  ///      },
  ///     onHover: () {
  ///      print('Point hovered over');
  ///      },
  ///   );
  /// ```
  Point({
    required this.coordinates,
    this.label,
    this.labelBuilder,
    this.isLabelVisible = false,
    this.labelOffset = const Offset(0, 0),
    required this.id,
    this.style = const PointStyle(),
    this.labelTextStyle,
    this.onTap,
    this.onHover,
  });

  /// Creates a copy of the [Point] object with the specified properties overridden.
  Point copyWith({
    GlobeCoordinates? coordinates,
    String? label,
    Widget? Function(
            BuildContext context, Point point, bool isHovering, bool isVisible)?
        labelBuilder,
    bool? isLabelVisible,
    Offset? labelOffset,
    String? id,
    PointStyle? style,
    TextStyle? labelTextStyle,
    VoidCallback? onTap,
    VoidCallback? onHover,
  }) {
    return Point(
      coordinates: coordinates ?? this.coordinates,
      label: label ?? this.label,
      labelBuilder: labelBuilder ?? this.labelBuilder,
      isLabelVisible: isLabelVisible ?? this.isLabelVisible,
      labelOffset: labelOffset ?? this.labelOffset,
      id: id ?? this.id,
      style: style ?? this.style,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      onTap: onTap ?? this.onTap,
      onHover: onHover ?? this.onHover,
    );
  }
}

/// Represents the style of a point.
///
/// The [PointStyle] class provides methods to convert the style to a map, JSON, and a string representation.
/// It also supports copying the style with optional new size and color values.
class PointStyle {
  /// The size of the point.
  final double size;

  /// The color of the point.
  final Color color;

  /// Creates a new instance of the [PointStyle] class.
  ///
  /// The [size] parameter is the size of the point.
  /// The [color] parameter is the color of the point.
  ///
  /// The default value of [size] is 4.
  /// The default value of [color] is white.
  ///
  /// Example usage:
  /// ```dart
  /// PointStyle(
  ///  size: 4,
  /// color: Colors.white,
  /// );
  /// ```
  const PointStyle({this.size = 4, this.color = Colors.white});

  /// Converts the [PointStyle] object to a map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'size': size,
      'color': color.value,
    };
  }

  /// Creates a [PointStyle] object from a map.
  factory PointStyle.fromMap(Map<String, dynamic> map) {
    return PointStyle(
      size: map['size'] as double,
      color: Color(map['color'] as int),
    );
  }

  /// Converts the [PointStyle] object to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a [PointStyle] object from a JSON string.
  factory PointStyle.fromJson(String source) =>
      PointStyle.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Creates a copy of the [PointStyle] object with the specified properties overridden.
  PointStyle copyWith({
    double? size,
    Color? color,
  }) {
    return PointStyle(
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }
}
