class Place {
  final int? id;
  final String name;
  final String featureType;
  final double lat;
  final double lon;
  final double? distanceKm;
  final double? bearing;

  const Place({
    this.id,
    required this.name,
    required this.featureType,
    required this.lat,
    required this.lon,
    this.distanceKm,
    this.bearing,
  });

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Unknown',
      featureType: map['feature_type'] as String? ?? 'unknown',
      lat: (map['lat'] as num).toDouble(),
      lon: (map['lon'] as num).toDouble(),
      distanceKm: map['distance_km'] as double?,
      bearing: map['bearing'] as double?,
    );
  }
}
