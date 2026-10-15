import 'package:flutter/material.dart';

class GlobeRegion {
  final String id;
  final String name;

  /// Polygons comprising this region.
  ///
  /// Following GeoJSON specifications:
  /// - Each element in [polygons] is a Polygon consisting of one or more linear rings:
  ///   - `rings[0]`: exterior ring (outer boundary)
  ///   - `rings[1..n]`: interior rings (holes)
  /// - Each ring is a list of [longitude, latitude] coordinate pairs.
  final List<List<List<List<double>>>> polygons;

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

  /// Factory constructor that accepts either 3-level or 4-level polygon lists
  /// and automatically normalizes them into standard 4-level structure.
  factory GlobeRegion.fromCoordinates({
    required String id,
    required String name,
    required dynamic polygons,
    Color borderColor = Colors.white,
    double borderWidth = 1.0,
    Color? fillColor,
    Color? highlightColor,
    bool isVisible = true,
    List<String> clipAgainst = const [],
  }) {
    return GlobeRegion(
      id: id,
      name: name,
      polygons: normalizePolygons(polygons),
      borderColor: borderColor,
      borderWidth: borderWidth,
      fillColor: fillColor,
      highlightColor: highlightColor,
      isVisible: isVisible,
      clipAgainst: clipAgainst,
    );
  }

  /// Normalizes dynamic polygon input into standard 4-level coordinates:
  /// `[polygon][ring][point][lon, lat]`.
  static List<List<List<List<double>>>> normalizePolygons(dynamic input) {
    if (input == null || input is! List || input.isEmpty) {
      return const [];
    }
    final first = input.first;
    if (first is! List || first.isEmpty) {
      return const [];
    }
    final second = first.first;
    if (second is! List || second.isEmpty) {
      return const [];
    }
    final third = second.first;
    if (third is num) {
      // 3-level list: [ring/polygon][point][lon, lat] -> wrap each ring as a single-ring polygon
      return input
          .map<List<List<List<double>>>>((ring) => [
                (ring as List)
                    .map<List<double>>((pt) => [
                          ((pt as List)[0] as num).toDouble(),
                          (pt[1] as num).toDouble(),
                        ])
                    .toList()
              ])
          .toList();
    } else if (third is List) {
      // 4-level list: [polygon][ring][point][lon, lat]
      return input
          .map<List<List<List<double>>>>((poly) => (poly as List)
              .map<List<List<double>>>((ring) => (ring as List)
                  .map<List<double>>((pt) => [
                        ((pt as List)[0] as num).toDouble(),
                        (pt[1] as num).toDouble(),
                      ])
                  .toList())
              .toList())
          .toList();
    }
    return const [];
  }

  GlobeRegion copyWith({
    String? id,
    String? name,
    List<List<List<List<double>>>>? polygons,
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
