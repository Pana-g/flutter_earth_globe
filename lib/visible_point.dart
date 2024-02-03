// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

/// Represents a visible point on the Earth's globe.
class VisiblePoint {
  /// The position of the visible point.
  final Offset position;

  /// Indicates whether the visible point is being hovered over.
  final bool isHovering;

  /// Indicates whether the visible point is currently visible.
  final bool isVisible;

  /// The unique identifier of the visible point.
  final String id;

  /// Creates a new instance of [VisiblePoint].
  ///
  /// [id] is the unique identifier of the visible point.
  /// [position] is the position of the visible point.
  /// [isHovering] indicates whether the visible point is being hovered over.
  /// [isVisible] indicates whether the visible point is currently visible.
  ///
  /// Example usage:
  /// ```dart
  /// VisiblePoint(
  ///  id: 'point1',
  /// position: Offset(100, 100),
  /// isHovering: false,
  /// isVisible: true,
  /// );
  /// ```
  VisiblePoint({
    required this.id,
    required this.position,
    required this.isHovering,
    required this.isVisible,
  });

  /// Creates a copy of the [VisiblePoint] with optional modifications.
  ///
  /// [position] (optional) specifies a new position for the visible point.
  /// [isHovering] (optional) specifies whether the visible point is being hovered over.
  /// [isVisible] (optional) specifies whether the visible point is currently visible.
  ///
  /// Returns a new instance of [VisiblePoint] with the specified modifications.
  VisiblePoint copyWith({
    Offset? position,
    bool? isHovering,
    bool? isVisible,
  }) {
    return VisiblePoint(
      id: id,
      position: position ?? this.position,
      isHovering: isHovering ?? this.isHovering,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
