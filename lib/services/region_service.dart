import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'osm_service.dart';

class RegionInfo {
  final String id;
  final String name;
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;
  final int poiSizeMb;
  final int routingSizeMb;
  final int totalSizeMb;
  final String osmDate;

  const RegionInfo({
    required this.id,
    required this.name,
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
    this.poiSizeMb = 0,
    this.routingSizeMb = 0,
    this.totalSizeMb = 0,
    this.osmDate = '',
  });

  factory RegionInfo.fromJson(Map<String, dynamic> json) {
    return RegionInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      minLat: (json['bounds'][1] as num).toDouble(),
      minLon: (json['bounds'][0] as num).toDouble(),
      maxLat: (json['bounds'][3] as num).toDouble(),
      maxLon: (json['bounds'][2] as num).toDouble(),
      poiSizeMb: json['poi_size_mb'] as int? ?? 0,
      routingSizeMb: json['routing_size_mb'] as int? ?? 0,
      totalSizeMb: json['total_size_mb'] as int? ?? 0,
      osmDate: json['osm_date'] as String? ?? '',
    );
  }

  double get centerLat => (minLat + maxLat) / 2;
  double get centerLon => (minLon + maxLon) / 2;
}

class RegionService {
  static List<RegionInfo>? _catalog;
  static final Set<String> _downloadedRegions = {};
  static String? _activeRegionId;

  static const _builtinRegions = [
    RegionInfo(
      id: 'southern_zone',
      name: 'Southern India',
      minLat: 8.0, minLon: 72.0, maxLat: 20.0, maxLon: 88.0,
      poiSizeMb: 117,
      totalSizeMb: 117,
    ),
  ];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('downloaded_regions') ?? [];
    _downloadedRegions.addAll(saved);
    _activeRegionId = prefs.getString('active_region');

    try {
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/pocket-medic/maps/main/catalog.json'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        _catalog = json.map((r) => RegionInfo.fromJson(r)).toList();
      }
    } catch (_) {}

    if (_catalog == null || _catalog!.isEmpty) {
      _catalog = _builtinRegions;
    }

    if (_activeRegionId != null) {
      await setActiveRegion(_activeRegionId!, persist: false);
    }
  }

  static List<RegionInfo> get availableRegions => _catalog ?? _builtinRegions;
  static String? get activeRegionId => _activeRegionId;

  static bool isRegionDownloaded(String regionId) {
    return _downloadedRegions.contains(regionId);
  }

  static Future<String> getRegionDbPath(String regionId) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/regions/$regionId/survival.sqlite';
  }

  static Future<bool> downloadRegion(
    RegionInfo region, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final regionDir = Directory('${dir.path}/regions/${region.id}');
      await regionDir.create(recursive: true);

      final dbPath = '${regionDir.path}/survival.sqlite';
      if (await File(dbPath).exists()) {
        _downloadedRegions.add(region.id);
        await _saveDownloaded();
        await setActiveRegion(region.id, persist: true);
        return true;
      }

      final url = 'https://raw.githubusercontent.com/pocket-medic/maps/main/${region.id}/survival.sqlite';
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) return false;

      final contentLength = response.contentLength ?? 0;
      int received = 0;
      final sink = File(dbPath).openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress?.call(received / contentLength);
        }
      }
      await sink.close();

      _downloadedRegions.add(region.id);
      await _saveDownloaded();
      await setActiveRegion(region.id, persist: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _saveDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('downloaded_regions', _downloadedRegions.toList());
  }

  static Future<void> setActiveRegion(String regionId, {bool persist = true}) async {
    final dbPath = await getRegionDbPath(regionId);
    if (await File(dbPath).exists()) {
      _activeRegionId = regionId;
      OsmService.setDatabasePath(dbPath);
      if (persist) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_region', regionId);
      }
    }
  }

  static Future<void> deleteRegion(String regionId) async {
    final dir = await getApplicationDocumentsDirectory();
    final regionDir = Directory('${dir.path}/regions/$regionId');
    if (await regionDir.exists()) {
      await regionDir.delete(recursive: true);
    }
    _downloadedRegions.remove(regionId);
    await _saveDownloaded();
    if (_activeRegionId == regionId) {
      _activeRegionId = null;
      OsmService.clearDatabasePath();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_region');
    }
  }
}
