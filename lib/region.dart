import 'package:flutter/material.dart';

class GlobeRegion {
  final String id;
  final String name;

  /// Each polygon is a list of [longitude, latitude] pairs.
  ///
  /// A country can have multiple polygons, for example:
  /// - mainland
  /// - islands
  /// - separated territories
  final List<List<List<double>>> polygons;

  final Color borderColor;
  final double borderWidth;
  final Color? fillColor;
  final Color? highlightColor;
  final bool isVisible;

  /// List of region IDs to clip this region's outline against.
  /// Used to resolve border overlaps (e.g. PK/CN clipping against IN).
  final List<String> clipAgainst;

  const GlobeRegion({
    required this.id,
    required this.name,
    required this.polygons,
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.fillColor,
    this.highlightColor,
    this.isVisible = true,
    this.clipAgainst = const [],
  });

  GlobeRegion copyWith({
    String? id,
    String? name,
    List<List<List<double>>>? polygons,
    Color? borderColor,
    double? borderWidth,
    Color? fillColor,
    Color? highlightColor,
    bool? isVisible,
    List<String>? clipAgainst,
  }) {
    return GlobeRegion(
      id: id ?? this.id,
      name: name ?? this.name,
      polygons: polygons ?? this.polygons,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      fillColor: fillColor ?? this.fillColor,
      highlightColor: highlightColor ?? this.highlightColor,
      isVisible: isVisible ?? this.isVisible,
      clipAgainst: clipAgainst ?? this.clipAgainst,
    );
  }
}
