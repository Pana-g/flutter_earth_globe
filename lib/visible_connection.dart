import 'package:flutter/material.dart';

class VisibleConnection {
  final GlobalKey key;

  /// The size of the widget to render.
  final Size? size;

  /// The position of the visible connection.
  final Offset? position;

  /// Indicates whether the visible point is being hovered over.
  final bool isHovering;

  /// Indicates whether the visible connection is currently visible.
  final bool isVisible;

  /// The unique identifier of the visible connection.
  final String id;

  /// Creates a new instance of [VisibleConnection].
  ///
  /// [id] is the unique identifier of the visible connection.
  /// [position] is the position of the visible connection.
  /// [isHovering] indicates whether the visible connection is being hovered over.
  /// [isVisible] indicates whether the visible connection is currently visible.
  ///
  /// Example usage:
  /// ```dart
  /// VisibleConnection(
  /// id: 'connection1',
  /// position: Offset(100, 100),
  /// isHovering: false,
  /// isVisible: true,
  /// );
  /// ```
  VisibleConnection({
    required this.key,
    required this.id,
    this.size,
    this.position,
    required this.isHovering,
    required this.isVisible,
  });

  /// Creates a copy of the [VisibleConnection] with optional modifications.
  ///
  /// [position] (optional) specifies a new position for the visible connection.
  /// [size] specifies the size of the widget to render.
  /// [isHovering] (optional) specifies whether the visible connection is being hovered over.
  /// [isVisible] (optional) specifies whether the visible connection is currently visible.
  ///
  /// Returns a new instance of [VisibleConnection] with the specified modifications.
  VisibleConnection copyWith({
    Offset? position,
    bool? isHovering,
    bool? isVisible,
    Size? size,
  }) {
    return VisibleConnection(
      id: id,
      size: size ?? this.size,
      key: key,
      position: position ?? this.position,
      isHovering: isHovering ?? this.isHovering,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
