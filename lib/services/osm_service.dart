import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/place.dart';

class OsmService {
  static Database? _database;
  static bool _copyFailed = false;
  static String? _customDbPath;
  static bool? _hasGeometryColumn;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static void setDatabasePath(String? path) {
    _customDbPath = path;
    _database?.close();
    _database = null;
    _hasGeometryColumn = null;
  }

  static void clearDatabasePath() {
    setDatabasePath(null);
  }

  static Future<bool> _checkGeometryColumn() async {
    if (_hasGeometryColumn != null) return _hasGeometryColumn!;
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA table_info(features)');
      _hasGeometryColumn = result.any((col) => col['name'] == 'geometry_json');
    } catch (_) {
      _hasGeometryColumn = false;
    }
    return _hasGeometryColumn!;
  }

  static Future<Database> _initDatabase() async {
    String destPath;

    if (_customDbPath != null && File(_customDbPath!).existsSync()) {
      destPath = _customDbPath!;
      _hasGeometryColumn = null;
      return await openDatabase(destPath, readOnly: true);
    }

    final appDir = await getApplicationDocumentsDirectory();
    destPath = join(appDir.path, 'survival.sqlite');
    final destFile = File(destPath);

    final sourcePath = await _findSourceDb();

    // If we have a cached DB, check if source is newer (has geometry_json).
    if (await destFile.exists() && sourcePath != null) {
      try {
        final oldDb = await openDatabase(destPath, readOnly: true);
        final cols = await oldDb.rawQuery('PRAGMA table_info(features)');
        final hasOldGeom = cols.any((col) => col['name'] == 'geometry_json');
        await oldDb.close();
        if (!hasOldGeom) {
          // Source has geometry but cached copy doesn't — re-copy.
          await File(sourcePath).copy(destPath);
          _hasGeometryColumn = null;
        }
      } catch (_) {
        // If we can't check, try re-copying anyway.
        try {
          await File(sourcePath).copy(destPath);
          _hasGeometryColumn = null;
        } catch (_) {}
      }
    } else if (!await destFile.exists() && sourcePath != null) {
      try {
        await File(sourcePath).copy(destPath);
      } on PlatformException {
        _copyFailed = true;
      } catch (e) {
        if (e.toString().contains('Permission denied') ||
            e.toString().contains('PathAccessException')) {
          _copyFailed = true;
        } else {
          rethrow;
        }
      }
    } else if (sourcePath == null) {
      _copyFailed = true;
    }

    if (_copyFailed) {
      throw Exception(
        'Permission denied. Please grant "All Files Access" in Settings, '
        'then restart the app.',
      );
    }

    return await openDatabase(destPath, readOnly: true);
  }

  static bool get needsPermission => _copyFailed;

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  static Future<String?> _findSourceDb() async {
    final candidates = [
      '/storage/emulated/0/Download/survival.sqlite',
      '/storage/emulated/0/Download/PocketMedic/survival.sqlite',
    ];

    for (final path in candidates) {
      if (await File(path).exists()) return path;
    }
    return null;
  }

  static Future<List<Place>> findNearby({
    required double lat,
    required double lon,
    double radiusKm = 50.0,
    String? featureType,
    int limit = 20,
  }) async {
    final db = await database;
    final hasGeom = await _checkGeometryColumn();

    final latDelta = radiusKm / 111.0;
    final lonDelta = radiusKm / (111.0 * cos(_toRad(lat)));

    final geomCol = hasGeom ? ', geometry_json' : '';

    String query;
    List<dynamic> args;

    if (featureType != null && featureType.isNotEmpty) {
      query = '''
        SELECT id, name, type, latitude, longitude$geomCol
        FROM features
        WHERE latitude BETWEEN ? AND ?
          AND longitude BETWEEN ? AND ?
          AND type = ?
        LIMIT ?
      ''';
      args = [lat - latDelta, lat + latDelta, lon - lonDelta, lon + lonDelta, featureType, limit * 3];
    } else {
      query = '''
        SELECT id, name, type, latitude, longitude$geomCol
        FROM features
        WHERE latitude BETWEEN ? AND ?
          AND longitude BETWEEN ? AND ?
        LIMIT ?
      ''';
      args = [lat - latDelta, lat + latDelta, lon - lonDelta, lon + lonDelta, limit * 3];
    }

    final maps = await db.rawQuery(query, args);

    final places = maps.map((m) {
      final pLat = (m['latitude'] as num).toDouble();
      final pLon = (m['longitude'] as num).toDouble();
      return Place(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? 'Unknown',
        featureType: (m['type'] as String?) ?? 'unknown',
        lat: pLat,
        lon: pLon,
        distanceKm: _haversine(lat, lon, pLat, pLon),
        bearing: _bearing(lat, lon, pLat, pLon),
        geometry: hasGeom ? _parseGeometry(m['geometry_json'] as String?) : null,
      );
    }).toList();

    places.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return places.take(limit).toList();
  }

  static Future<List<Place>> findByType({
    required double lat,
    required double lon,
    required String featureType,
    double radiusKm = 50.0,
    int limit = 10,
  }) async {
    return findNearby(
      lat: lat,
      lon: lon,
      radiusKm: radiusKm,
      featureType: featureType,
      limit: limit,
    );
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
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

  static double _toRad(double deg) => deg * pi / 180.0;
  static double _toDeg(double rad) => rad * 180.0 / pi;

  static String bearingToCompass(double bearing) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[(bearing / 45).round() % 8];
  }

  static String bearingToArrow(double bearing) {
    const arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    return arrows[(bearing / 45).round() % 8];
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

  /// Find the nearest point on any trail polyline to the given position.
  /// Returns the snapped LatLng and the trail name, or null if no trails nearby.
  static Future<SnapResult?> snapToTrail({
    required double lat,
    required double lon,
    double radiusKm = 2.0,
  }) async {
    final trails = await findNearby(
      lat: lat,
      lon: lon,
      radiusKm: radiusKm,
      featureType: 'trail',
      limit: 50,
    );

    double bestDist = double.infinity;
    LatLng? bestPoint;
    String? bestTrailName;

    for (final trail in trails) {
      final geom = trail.geometry;
      if (geom == null || geom.length < 2) continue;

      for (int i = 0; i < geom.length - 1; i++) {
        final p = _closestPointOnSegment(
          lat, lon,
          geom[i].latitude, geom[i].longitude,
          geom[i + 1].latitude, geom[i + 1].longitude,
        );
        final d = _haversine(lat, lon, p.latitude, p.longitude);
        if (d < bestDist) {
          bestDist = d;
          bestPoint = p;
          bestTrailName = trail.name;
        }
      }
    }

    if (bestPoint == null || bestDist > radiusKm) return null;
    return SnapResult(point: bestPoint, trailName: bestTrailName, distanceKm: bestDist);
  }

  /// Closest point on a line segment (lat/lon) to a given point.
  static LatLng _closestPointOnSegment(
    double plat, double plon,
    double alat, double alon,
    double blat, double blon,
  ) {
    final dLat = _toRad(blat - alat);
    final dLon = _toRad(blon - alon);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(alat)) * cos(_toRad(blat)) * sin(dLon / 2) * sin(dLon / 2);
    final segLen = 2 * atan2(sqrt(a), sqrt(1 - a)) * 6371.0;
    if (segLen < 0.001) return LatLng(alat, alon);

    final t = max(0.0, min(1.0, _projectionT(plat, plon, alat, alon, blat, blon)));
    return LatLng(alat + t * (blat - alat), alon + t * (blon - alon));
  }

  static double _projectionT(
    double plat, double plon,
    double alat, double alon,
    double blat, double blon,
  ) {
    final dlat = blat - alat;
    final dlon = blon - alon;
    final pdlat = plat - alat;
    final pdlon = plon - alon;
    final dot = pdlat * dlat + pdlon * dlon;
    final len2 = dlat * dlat + dlon * dlon;
    if (len2 == 0) return 0;
    return dot / len2;
  }
}

class SnapResult {
  final LatLng point;
  final String? trailName;
  final double distanceKm;

  const SnapResult({
    required this.point,
    this.trailName,
    required this.distanceKm,
  });
}
