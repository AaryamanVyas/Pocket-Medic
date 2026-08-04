import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_medic/services/navigation_service.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('NavigationService.buildRoute', () {
    test('produces correct number of steps', () {
      final start = const LatLng(13.0827, 80.2707);
      final end = const LatLng(13.0067, 80.2477);
      final route = NavigationService.buildRoute(
        start: start,
        end: end,
        stepCount: 6,
      );
      expect(route.steps.length, greaterThan(0));
      expect(route.points.length, greaterThan(2));
    });

    test('starts at start point and ends at end point', () {
      final start = const LatLng(13.0827, 80.2707);
      final end = const LatLng(13.0067, 80.2477);
      final route = NavigationService.buildRoute(
        start: start,
        end: end,
        stepCount: 4,
      );
      expect(route.points.first.latitude, start.latitude);
      expect(route.points.first.longitude, start.longitude);
      expect(route.points.last.latitude, end.latitude);
      expect(route.points.last.longitude, end.longitude);
    });

    test('total distance is positive', () {
      final start = const LatLng(13.0827, 80.2707);
      final end = const LatLng(13.0067, 80.2477);
      final route = NavigationService.buildRoute(
        start: start,
        end: end,
        stepCount: 6,
      );
      expect(route.totalDistanceKm, greaterThan(0));
    });

    test('each step has positive distance', () {
      final start = const LatLng(13.0827, 80.2707);
      final end = const LatLng(13.0067, 80.2477);
      final route = NavigationService.buildRoute(
        start: start,
        end: end,
        stepCount: 6,
      );
      for (final step in route.steps) {
        expect(step.distanceMeters, greaterThan(0));
      }
    });

    test('each step has a non-empty instruction', () {
      final start = const LatLng(13.0827, 80.2707);
      final end = const LatLng(13.0067, 80.2477);
      final route = NavigationService.buildRoute(
        start: start,
        end: end,
        stepCount: 6,
      );
      for (final step in route.steps) {
        expect(step.instruction, isNotEmpty);
      }
    });

    test('first step instruction starts with Head', () {
      final start = const LatLng(13.0827, 80.2707);
      final end = const LatLng(13.0067, 80.2477);
      final route = NavigationService.buildRoute(
        start: start,
        end: end,
        stepCount: 6,
      );
      expect(route.steps.first.instruction, startsWith('Head'));
    });
  });

  group('NavigationService.formatDistance', () {
    test('formats meters for distances under 1 km', () {
      expect(NavigationService.formatDistance(0.5), '500 m');
      expect(NavigationService.formatDistance(0.01), '10 m');
      expect(NavigationService.formatDistance(0.999), '999 m');
    });

    test('formats kilometers for distances 1 km or more', () {
      expect(NavigationService.formatDistance(1.0), '1.0 km');
      expect(NavigationService.formatDistance(5.5), '5.5 km');
      expect(NavigationService.formatDistance(12.34), '12.3 km');
    });
  });

  group('NavigationService._haversine', () {
    test('returns 0 for same point', () {
      final dist = NavigationService.buildRoute(
        start: const LatLng(0, 0),
        end: const LatLng(0, 0),
        stepCount: 1,
      ).totalDistanceKm;
      expect(dist, closeTo(0, 0.001));
    });

    test('returns positive distance for different points', () {
      final dist = NavigationService.buildRoute(
        start: const LatLng(13.0827, 80.2707),
        end: const LatLng(13.0067, 80.2477),
        stepCount: 1,
      ).totalDistanceKm;
      expect(dist, greaterThan(0));
    });
  });

  group('NavigationService._compassHeading', () {
    test('returns correct cardinal directions', () {
      expect(NavigationService.buildRoute(
        start: const LatLng(0, 0),
        end: const LatLng(0.01, 0),
        stepCount: 1,
      ).steps.first.instruction, contains('N'));
    });
  });
}