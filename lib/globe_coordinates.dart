// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// Represents the coordinates of a point on the globe.
class GlobeCoordinates {
  final double latitude;
  final double longitude;

  /// The [GlobeCoordinates] class provides methods to convert the coordinates
  /// to a map, JSON, and a string representation. It also supports copying
  /// the coordinates with optional new latitude and longitude values.
  ///
  /// The [latitude] and [longitude] parameters represent the coordinates of the point on the globe.
  ///
  /// Example usage:
  /// ```dart
  /// GlobeCoordinates(
  /// latitude: 0,
  /// longitude: 0,
  /// );
  /// ```
  const GlobeCoordinates(this.latitude, this.longitude);

  /// Returns a string representation of the [GlobeCoordinates] object.
  @override
  String toString() {
    return 'GlobeCoordinates{latitude: $latitude, longitude: $longitude}';
  }

  /// Converts the [GlobeCoordinates] object to a map.
  ///
  /// The map contains the latitude and longitude as key-value pairs.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Creates a [GlobeCoordinates] object from a map.
  ///
  /// The map should contain the latitude and longitude as key-value pairs.
  factory GlobeCoordinates.fromMap(Map<String, dynamic> map) {
    return GlobeCoordinates(
      map['latitude'] as double,
      map['longitude'] as double,
    );
  }

  /// Converts the [GlobeCoordinates] object to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a [GlobeCoordinates] object from a JSON string.
  ///
  /// The JSON string should contain the latitude and longitude as key-value pairs.
  factory GlobeCoordinates.fromJson(String source) =>
      GlobeCoordinates.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Creates a copy of the [GlobeCoordinates] object with optional new latitude and longitude values.
  ///
  /// If [latitude] or [longitude] is provided, the corresponding value will be updated in the new object.
  GlobeCoordinates copyWith({
    double? latitude,
    double? longitude,
  }) {
    return GlobeCoordinates(
      latitude ?? this.latitude,
      longitude ?? this.longitude,
    );
  }
}
