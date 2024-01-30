import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart' as material;

import 'globe_coordinates.dart';
import 'point_connection_style.dart';

/// This class defines the [connection] between two [points].
class PointConnection {
  final GlobeCoordinates start;
  final GlobeCoordinates end;
  final String? title;
  final material.TextStyle? textStyle;
  final String id;
  bool isMoving;
  bool showTitleOnHover;
  bool isTitleVisible;
  final PointConnectionStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onHover;

  PointConnection(
      {required this.start,
      required this.end,
      required this.id,
      this.onHover,
      this.textStyle,
      this.onTap,
      this.isMoving = false,
      this.showTitleOnHover = false,
      this.isTitleVisible = true,
      this.title,
      this.style = const PointConnectionStyle()});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'start': start.toMap(),
      'end': end.toMap(),
      'title': title,
      'isTitleVisible': isTitleVisible,
      'showTitleOnHover': showTitleOnHover,
      'id': id,
      'isMoving': isMoving,
      'style': style.toMap(),
    };
  }

  factory PointConnection.fromMap(Map<String, dynamic> map) {
    return PointConnection(
      start: GlobeCoordinates.fromMap(map['start'] as Map<String, dynamic>),
      end: GlobeCoordinates.fromMap(map['end'] as Map<String, dynamic>),
      title: map['title'] != null ? map['title'] as String : null,
      id: map['id'],
      isTitleVisible: map['isTitleVisible'] as bool,
      showTitleOnHover: map['showTitleOnHover'] as bool,
      isMoving: map['isMoving'] as bool,
      style: PointConnectionStyle.fromMap(map['style'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory PointConnection.fromJson(String source) =>
      PointConnection.fromMap(json.decode(source) as Map<String, dynamic>);

  PointConnection copyWith({
    GlobeCoordinates? start,
    GlobeCoordinates? end,
    String? title,
    String? id,
    bool? isMoving,
    bool? isTitleVisible,
    bool? showTitleOnHover,
    material.TextStyle? textStyle,
    PointConnectionStyle? style,
  }) {
    return PointConnection(
      start: start ?? this.start,
      end: end ?? this.end,
      title: title ?? this.title,
      id: id ?? this.id,
      textStyle: textStyle ?? this.textStyle,
      isMoving: isMoving ?? this.isMoving,
      isTitleVisible: isTitleVisible ?? this.isTitleVisible,
      showTitleOnHover: showTitleOnHover ?? this.showTitleOnHover,
      style: style ?? this.style,
    );
  }
}

/// This class extends [PointConnection] and adds the [animationOffset] and [animationProgress] properties.
/// The [animationOffset] is used to animate the [PointConnection]s in a staggered way.
/// The [animationProgress] is used to animate the [PointConnection]s from the start to the end.
class AnimatedPointConnection extends PointConnection {
  double animationOffset;
  double animationProgress;
  AnimatedPointConnection(
      {super.title,
      required super.start,
      required super.end,
      required super.id,
      super.style,
      super.isMoving,
      super.onTap,
      super.onHover,
      super.textStyle,
      super.isTitleVisible,
      super.showTitleOnHover,
      this.animationProgress = 0.0,
      this.animationOffset = 0.0});

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      ...super.toMap(),
      'animationOffset': animationOffset,
      'animationProgress': animationProgress,
    };
  }

  factory AnimatedPointConnection.fromMap(
      Map<String, dynamic> map, VoidCallback? onTap, VoidCallback? onHover) {
    return AnimatedPointConnection(
      animationOffset: map['animationOffset'] != null
          ? map['animationOffset'] as double
          : 0.0,
      start: GlobeCoordinates.fromMap(map['start'] as Map<String, dynamic>),
      end: GlobeCoordinates.fromMap(map['end'] as Map<String, dynamic>),
      title: map['title'] != null ? map['title'] as String : null,
      id: map['id'],
      isTitleVisible: map['isTitleVisible'],
      animationProgress: map['animationProgress'] != null
          ? map['animationProgress'] as double
          : 0.0,
      isMoving: map['isMoving'] as bool,
      showTitleOnHover: map['showTitleOnHover'] as bool,
      onHover: onHover,
      onTap: onTap,
      style: PointConnectionStyle.fromMap(map['style'] as Map<String, dynamic>),
    );
  }

  @override
  AnimatedPointConnection copyWith({
    double? animationOffset,
    double? animationProgress,
    GlobeCoordinates? start,
    VoidCallback? onHover,
    VoidCallback? onTap,
    GlobeCoordinates? end,
    String? title,
    material.TextStyle? textStyle,
    String? id,
    bool? isMoving,
    bool? isTitleVisible,
    bool? showTitleOnHover,
    PointConnectionStyle? style,
  }) {
    return AnimatedPointConnection(
      animationOffset: animationOffset ?? this.animationOffset,
      animationProgress: animationProgress ?? this.animationProgress,
      start: start ?? this.start,
      end: end ?? this.end,
      onHover: onHover ?? this.onHover,
      onTap: onTap ?? this.onTap,
      title: title ?? this.title,
      textStyle: textStyle ?? this.textStyle,
      id: id ?? this.id,
      isMoving: isMoving ?? this.isMoving,
      isTitleVisible: isTitleVisible ?? this.isTitleVisible,
      showTitleOnHover: showTitleOnHover ?? this.showTitleOnHover,
      style: style ?? this.style,
    );
  }
}
