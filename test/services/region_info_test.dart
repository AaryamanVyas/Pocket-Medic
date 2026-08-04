import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_medic/services/region_service.dart';

void main() {
  group('RegionInfo', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'test_region',
        'name': 'Test Region',
        'bounds': [72.0, 8.0, 88.0, 20.0],
        'poi_size_mb': 117,
        'routing_size_mb': 50,
        'total_size_mb': 167,
        'osm_date': '2025-01-15',
      };
      final region = RegionInfo.fromJson(json);
      expect(region.id, 'test_region');
      expect(region.name, 'Test Region');
      expect(region.minLat, 8.0);
      expect(region.minLon, 72.0);
      expect(region.maxLat, 20.0);
      expect(region.maxLon, 88.0);
      expect(region.poiSizeMb, 117);
      expect(region.routingSizeMb, 50);
      expect(region.totalSizeMb, 167);
      expect(region.osmDate, '2025-01-15');
    });

    test('centerLat and centerLon compute correctly', () {
      final region = RegionInfo(
        id: 'test',
        name: 'Test',
        minLat: 8.0,
        minLon: 72.0,
        maxLat: 20.0,
        maxLon: 88.0,
      );
      expect(region.centerLat, 14.0);
      expect(region.centerLon, 80.0);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'minimal',
        'name': 'Minimal Region',
        'bounds': [72.0, 8.0, 88.0, 20.0],
      };
      final region = RegionInfo.fromJson(json);
      expect(region.poiSizeMb, 0);
      expect(region.routingSizeMb, 0);
      expect(region.totalSizeMb, 0);
      expect(region.osmDate, '');
    });

    test('fromJson handles empty osmDate', () {
      final json = {
        'id': 'test',
        'name': 'Test',
        'bounds': [0.0, 0.0, 1.0, 1.0],
        'osm_date': '',
      };
      final region = RegionInfo.fromJson(json);
      expect(region.osmDate, '');
    });
  });
}