import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/place.dart';

class OsmService {
  static Database? _database;
  static bool _copyFailed = false;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    final destPath = join(appDir.path, 'survival.sqlite');
    final destFile = File(destPath);

    if (!await destFile.exists()) {
      final assetPath = await _findSourceDb();
      if (assetPath != null) {
        try {
          await File(assetPath).copy(destPath);
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
      } else {
        _copyFailed = true;
      }
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

    final latDelta = radiusKm / 111.0;
    final lonDelta = radiusKm / (111.0 * cos(_toRad(lat)));

    String query;
    List<dynamic> args;

    if (featureType != null && featureType.isNotEmpty) {
      query = '''
        SELECT id, name, type, latitude, longitude
        FROM features
        WHERE latitude BETWEEN ? AND ?
          AND longitude BETWEEN ? AND ?
          AND type = ?
        LIMIT ?
      ''';
      args = [lat - latDelta, lat + latDelta, lon - lonDelta, lon + lonDelta, featureType, limit * 3];
    } else {
      query = '''
        SELECT id, name, type, latitude, longitude
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

  static double _toRad(double deg) => deg * pi / 180.0;
}
