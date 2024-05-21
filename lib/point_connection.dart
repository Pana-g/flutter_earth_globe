import 'package:flutter/material.dart';

import 'globe_coordinates.dart';

import 'point_connection_style.dart';

/// This class defines the [PointConnection] between two [Point].
/// Represents a connection between two points on a globe.
class PointConnection {
  final GlobeCoordinates start;
  final GlobeCoordinates end;
  final String? label;
  final Widget? Function(BuildContext context, PointConnection pointConnection,
      bool isHovering, bool isVisible)? labelBuilder;
  final TextStyle? labelTextStyle;
  final String id;
  bool isMoving;
  bool isLabelVisible;
  final Offset labelOffset;
  final double curveScale;
  final PointConnectionStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onHover;

  /// Creates a new [PointConnection] instance.
  ///
  /// The [start] and [end] parameters represent the coordinates of the start and end points of the connection.
  /// The [id] parameter is a unique identifier for the connection.
  /// The [label] parameter is an optional label for the connection.
  /// The [labelOffset] parameter represents the offset of the label from the connection line.
  /// The [curveScale] parameter represents the scale of the curve.
  /// The [labelBuilder] parameter is a function that builds the label widget for the connection.
  /// The [labelTextStyle] parameter represents the style of the label text.
  /// The [isMoving] parameter indicates whether the connection is currently moving.
  /// The [isLabelVisible] parameter indicates whether the label is currently visible.
  /// The [style] parameter represents the style of the connection line.
  /// The [onTap] parameter is a callback function that is called when the connection is tapped.
  /// The [onHover] parameter is a callback function that is called when the connection is hovered over.
  PointConnection({
    required this.start,
    required this.end,
    required this.id,
    this.label,
    this.labelOffset = const Offset(0, 0),
    this.labelBuilder,
    this.curveScale = 1.5,
    this.labelTextStyle,
    this.isMoving = false,
    this.isLabelVisible = false,
    this.style = const PointConnectionStyle(),
    this.onTap,
    this.onHover,
  });

  double get strokeWidth {
    switch (style.type) {
      case PointConnectionType.solid:
        return style.lineWidth;
      case PointConnectionType.dashed:
        return style.dashSize;
      case PointConnectionType.dotted:
        return style.dotSize;
      default:
        return 0;
    }
  }

  /// Creates a new [PointConnection] instance with updated properties.
  ///
  /// The [start], [end], [label], [labelTextStyle], [id], [labelBuilder], [isMoving], [isLabelVisible],
  /// [labelOffset], [style], [onTap], and [onHover] parameters represent the updated properties of the connection.
  PointConnection copyWith({
    GlobeCoordinates? start,
    GlobeCoordinates? end,
    String? label,
    TextStyle? labelTextStyle,
    String? id,
    Widget? Function(BuildContext context, PointConnection pointConnection,
            bool isHovering, bool isVisible)?
        labelBuilder,
    bool? isMoving,
    bool? isLabelVisible,
    Offset? labelOffset,
    PointConnectionStyle? style,
    VoidCallback? onTap,
    VoidCallback? onHover,
  }) {
    return PointConnection(
      start: start ?? this.start,
      end: end ?? this.end,
      label: label ?? this.label,
      labelOffset: labelOffset ?? this.labelOffset,
      labelBuilder: labelBuilder ?? this.labelBuilder,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      id: id ?? this.id,
      isMoving: isMoving ?? this.isMoving,
      isLabelVisible: isLabelVisible ?? this.isLabelVisible,
      style: style ?? this.style,
      onTap: onTap ?? this.onTap,
      onHover: onHover ?? this.onHover,
    );
  }
}

/// Represents an animated point connection between two points on a globe.
///
/// This class extends [PointConnection] and adds the [animationOffset] and [animationProgress] properties.
class AnimatedPointConnection extends PointConnection {
  double animationOffset;
  double animationProgress;

  /// Creates a new [AnimatedPointConnection] instance.
  ///
  /// The [start] and [end] parameters represent the coordinates of the start and end points of the connection.
  /// The [id] parameter is a unique identifier for the connection.
  /// The [label] parameter is an optional label for the connection.
  /// The [labelOffset] parameter represents the offset of the label from the connection line.
  /// The [curveScale] parameter represents the scale of the curve.
  /// The [labelBuilder] parameter is a function that builds the label widget for the connection.
  /// The [labelTextStyle] parameter represents the style of the label text.
  /// The [isMoving] parameter indicates whether the connection is currently moving.
  /// The [isLabelVisible] parameter indicates whether the label is currently visible.
  /// The [style] parameter represents the style of the connection line.
  /// The [onTap] parameter is a callback function that is called when the connection is tapped.
  /// The [onHover] parameter is a callback function that is called when the connection is hovered over.
  /// The [animationProgress] parameter represents the progress of the animation.
  /// The [animationOffset] parameter represents the offset of the animation.
  AnimatedPointConnection(
      {required super.start,
      required super.end,
      required super.id,
      super.label,
      super.labelTextStyle,
      super.isMoving,
      super.onTap,
      super.onHover,
      super.style,
      super.labelOffset,
      super.curveScale = 1.5,
      super.isLabelVisible,
      super.labelBuilder,
      this.animationProgress = 0.0,
      this.animationOffset = 0.0});

  /// Creates a new [AnimatedPointConnection] instance from an existing [PointConnection].
  ///
  /// The [pointConnection] parameter represents the existing [PointConnection] to be converted to an [AnimatedPointConnection].
  /// The [animationOffset] parameter represents the offset of the animation.
  /// The [animationProgress] parameter represents the progress of the animation.
  ///
  /// Example usage:
  /// ```dart
  /// AnimatedPointConnection.fromPointConnection(
  ///  pointConnection: pointConnection,
  /// animationOffset: 0.0,
  /// animationProgress: 0.0,
  /// );
  /// ```
  AnimatedPointConnection.fromPointConnection({
    required PointConnection pointConnection,
    this.animationOffset = 0.0,
    this.animationProgress = 0.0,
  }) : super(
          start: pointConnection.start,
          labelOffset: pointConnection.labelOffset,
          end: pointConnection.end,
          id: pointConnection.id,
          curveScale: pointConnection.curveScale,
          label: pointConnection.label,
          labelTextStyle: pointConnection.labelTextStyle,
          isMoving: pointConnection.isMoving,
          isLabelVisible: pointConnection.isLabelVisible,
          style: pointConnection.style,
          onTap: pointConnection.onTap,
          onHover: pointConnection.onHover,
          labelBuilder: pointConnection.labelBuilder,
        );

  @override
  PointConnection copyWith({
    GlobeCoordinates? start,
    GlobeCoordinates? end,
    Offset? labelOffset,
    double? curveScale,
    String? label,
    TextStyle? labelTextStyle,
    String? id,
    Widget? Function(BuildContext context, PointConnection pointConnection,
            bool isHovering, bool isVisible)?
        labelBuilder,
    bool? isMoving,
    bool? isLabelVisible,
    PointConnectionStyle? style,
    VoidCallback? onTap,
    VoidCallback? onHover,
    double? animationOffset,
    double? animationProgress,
  }) {
    return AnimatedPointConnection(
      start: start ?? this.start,
      end: end ?? this.end,
      label: label ?? this.label,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      id: id ?? this.id,
      labelBuilder: labelBuilder ?? this.labelBuilder,
      labelOffset: labelOffset ?? this.labelOffset,
      curveScale: curveScale ?? this.curveScale,
      isMoving: isMoving ?? this.isMoving,
      isLabelVisible: isLabelVisible ?? this.isLabelVisible,
      style: style ?? this.style,
      onTap: onTap ?? this.onTap,
      onHover: onHover ?? this.onHover,
      animationOffset: animationOffset ?? this.animationOffset,
      animationProgress: animationProgress ?? this.animationProgress,
    );
  }
}
