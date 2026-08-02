import 'dart:convert';
import 'package:latlong2/latlong.dart';

class Place {
  final int? id;
  final String name;
  final String featureType;
  final double lat;
  final double lon;
  final double? distanceKm;
  final double? bearing;
  final List<LatLng>? geometry;

  const Place({
    this.id,
    required this.name,
    required this.featureType,
    required this.lat,
    required this.lon,
    this.distanceKm,
    this.bearing,
    this.geometry,
  });

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Unknown',
      featureType: map['type'] as String? ?? 'unknown',
      lat: (map['latitude'] as num).toDouble(),
      lon: (map['longitude'] as num).toDouble(),
      distanceKm: map['distance_km'] as double?,
      bearing: map['bearing'] as double?,
      geometry: _parseGeometry(map['geometry_json'] as String?),
    );
  }

  static List<LatLng>? _parseGeometry(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr) as List;
      if (decoded.isEmpty) return null;
      return decoded.map<LatLng>((p) {
        final pair = p as List;
        return LatLng(
          (pair[0] as num).toDouble(),
          (pair[1] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }
}
