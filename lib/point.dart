// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';

import 'globe_coordinates.dart';

/// Represents a [point] on the [globe].
class Point {
  final GlobeCoordinates coordinates;
  final String? title;
  final bool isTitleVisible;
  final String id;
  final PointStyle style;
  final TextStyle? textStyle;
  final VoidCallback? onTap;
  final VoidCallback? onHover;
  final bool showTitleOnHover;

  Point({
    required this.coordinates,
    required this.id,
    this.title,
    this.showTitleOnHover = false,
    this.onHover,
    this.onTap,
    this.textStyle,
    this.isTitleVisible = false,
    this.style = const PointStyle(),
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'coordinates': coordinates.toMap(),
      'title': title,
      'isTitleVisible': isTitleVisible,
      'showTitleOnHover': showTitleOnHover,
      'id': id,
      'style': style.toMap(),
    };
  }

  factory Point.fromMap(Map<String, dynamic> map) {
    return Point(
      coordinates:
          GlobeCoordinates.fromMap(map['coordinates'] as Map<String, dynamic>),
      title: map['title'] != null ? map['title'] as String : null,
      isTitleVisible: map['isTitleVisible'] as bool,
      showTitleOnHover: map['showTitleOnHover'] as bool,
      id: map['id'] as String,
      style: PointStyle.fromMap(map['style'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory Point.fromJson(String source) =>
      Point.fromMap(json.decode(source) as Map<String, dynamic>);

  Point copyWith({
    GlobeCoordinates? coordinates,
    String? title,
    bool? isTitleVisible,
    bool? showTitleOnHover,
    String? id,
    PointStyle? style,
    TextStyle? textStyle,
  }) {
    return Point(
      coordinates: coordinates ?? this.coordinates,
      title: title ?? this.title,
      isTitleVisible: isTitleVisible ?? this.isTitleVisible,
      showTitleOnHover: showTitleOnHover ?? this.showTitleOnHover,
      id: id ?? this.id,
      style: style ?? this.style,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  @override
  String toString() {
    return 'Point(coordinates: $coordinates, title: $title, isTitleVisible: $isTitleVisible, id: $id, style: $style, textStyle: $textStyle, onTap: $onTap, onHover: $onHover, showTitleOnHover: $showTitleOnHover)';
  }
}

/// This class defines the style of a [point].
class PointStyle {
  final double size;
  final Color color;

  const PointStyle({this.size = 4, this.color = Colors.white});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'size': size,
      'color': color.value,
    };
  }

  factory PointStyle.fromMap(Map<String, dynamic> map) {
    return PointStyle(
      size: map['size'] as double,
      color: Color(map['color'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory PointStyle.fromJson(String source) =>
      PointStyle.fromMap(json.decode(source) as Map<String, dynamic>);

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
