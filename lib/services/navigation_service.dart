import 'dart:math';
import 'package:latlong2/latlong.dart';

class NavigationStep {
  final String instruction;
  final double distanceMeters;
  final double bearing;

  const NavigationStep({
    required this.instruction,
    required this.distanceMeters,
    required this.bearing,
  });
}

class NavigationRoute {
  final List<LatLng> points;
  final List<NavigationStep> steps;
  final double totalDistanceKm;

  const NavigationRoute({
    required this.points,
    required this.steps,
    required this.totalDistanceKm,
  });
}

class NavigationService {
  static NavigationRoute buildRoute({
    required LatLng start,
    required LatLng end,
    int stepCount = 6,
  }) {
    final points = <LatLng>[start];
    final totalDistanceKm = _haversine(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    for (var i = 1; i < stepCount; i++) {
      final ratio = i / stepCount;
      final lat = start.latitude + (end.latitude - start.latitude) * ratio;
      final lon = start.longitude + (end.longitude - start.longitude) * ratio;
      points.add(LatLng(lat, lon));
    }

    points.add(end);

    final steps = <NavigationStep>[];
    var previousBearing = _bearing(
      start.latitude,
      start.longitude,
      points[1].latitude,
      points[1].longitude,
    );

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final bearing = _bearing(current.latitude, current.longitude, next.latitude, next.longitude);
      final distanceMeters = _haversine(
            current.latitude,
            current.longitude,
            next.latitude,
            next.longitude,
          ) *
          1000;

      final turnDelta = _normalizeBearing(bearing - previousBearing);
      final instruction = i == 0
          ? 'Head ${_compassHeading(bearing)} toward the destination'
          : turnDelta.abs() < 20
              ? 'Continue ${_compassHeading(bearing)}'
              : turnDelta > 0
                  ? 'Turn right toward ${_compassHeading(bearing)}'
                  : 'Turn left toward ${_compassHeading(bearing)}';

      steps.add(NavigationStep(
        instruction: instruction,
        distanceMeters: distanceMeters,
        bearing: bearing,
      ));
      previousBearing = bearing;
    }

    return NavigationRoute(
      points: points,
      steps: steps,
      totalDistanceKm: totalDistanceKm,
    );
  }

  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final latDelta = _toRad(lat2 - lat1);
    final lonDelta = _toRad(lon2 - lon1);
    final a = sin(latDelta / 2) * sin(latDelta / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(lonDelta / 2) * sin(lonDelta / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _bearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRad(lon2 - lon1);
    final y = sin(dLon) * cos(_toRad(lat2));
    final x = cos(_toRad(lat1)) * sin(_toRad(lat2)) -
        sin(_toRad(lat1)) * cos(_toRad(lat2)) * cos(dLon);
    return (_toDeg(atan2(y, x)) + 360) % 360;
  }

  static double _normalizeBearing(double bearing) {
    var normalized = bearing % 360;
    if (normalized > 180) normalized -= 360;
    if (normalized < -180) normalized += 360;
    return normalized;
  }

  static String _compassHeading(double bearing) {
    const headings = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return headings[(bearing / 45).round() % 8];
  }

  static double _toRad(double deg) => deg * pi / 180.0;
  static double _toDeg(double rad) => rad * 180.0 / pi;
}
