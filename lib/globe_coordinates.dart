// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// Represents a point on the globe.
/// It has a latitude and a longitude.
///
/// It can be used to represent a city, a country, a landmark, etc.
class GlobeCoordinates {
  final double latitude;
  final double longitude;

  const GlobeCoordinates(this.latitude, this.longitude);

  @override
  String toString() {
    return 'GlobeCoordinates{latitude: $latitude, longitude: $longitude}';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory GlobeCoordinates.fromMap(Map<String, dynamic> map) {
    return GlobeCoordinates(
      map['latitude'] as double,
      map['longitude'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory GlobeCoordinates.fromJson(String source) =>
      GlobeCoordinates.fromMap(json.decode(source) as Map<String, dynamic>);

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
