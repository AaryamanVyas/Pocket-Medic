import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_tokens.dart';
import '../models/place.dart';
import '../services/osm_service.dart';
import 'navigation_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Place> _places = [];
  LatLng? _userPosition;
  bool _loading = true;
  String? _error;
  String? _selectedType;
  SnapResult? _snapResult;

  static const _defaultCenter = LatLng(13.0827, 80.2707);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {}

      if (pos != null) {
        _userPosition = LatLng(pos.latitude, pos.longitude);
      }

      final center = _userPosition ?? _defaultCenter;
      final places = await OsmService.findNearby(
        lat: center.latitude,
        lon: center.longitude,
        radiusKm: 50.0,
        featureType: _selectedType,
        limit: 100,
      );

      setState(() {
        _places = places;
        _loading = false;
      });

      // Try to snap user to nearest trail
      if (_userPosition != null) {
        final snap = await OsmService.snapToTrail(
          lat: _userPosition!.latitude,
          lon: _userPosition!.longitude,
          radiusKm: 0.5,
        );
        if (mounted && snap != null) {
          setState(() => _snapResult = snap);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _markerColor(String type) {
    switch (type) {
      case 'hospital':
      case 'clinic':
        return const Color(0xFFDC2626);
      case 'pharmacy':
        return const Color(0xFF7C3AED);
      case 'police':
      case 'fire_station':
        return const Color(0xFF2563EB);
      case 'spring':
      case 'river':
      case 'stream':
      case 'lake':
        return const Color(0xFF0284C7);
      case 'campsite':
      case 'shelter':
        return const Color(0xFF16A34A);
      case 'village':
      case 'town':
      case 'city':
        return const Color(0xFF9333EA);
      case 'trail':
        return const Color(0xFFCA8A04);
      default:
        return AppTokens.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _userPosition ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) {
              setState(() => _selectedType = type);
              _init();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All types')),
              const PopupMenuItem(value: 'hospital', child: Text('Hospitals')),
              const PopupMenuItem(value: 'clinic', child: Text('Clinics')),
              const PopupMenuItem(value: 'pharmacy', child: Text('Pharmacies')),
              const PopupMenuItem(value: 'police', child: Text('Police')),
              const PopupMenuItem(value: 'fire_station', child: Text('Fire stations')),
              const PopupMenuItem(value: 'spring', child: Text('Springs')),
              const PopupMenuItem(value: 'river', child: Text('Rivers')),
              const PopupMenuItem(value: 'campsite', child: Text('Campsites')),
              const PopupMenuItem(value: 'shelter', child: Text('Shelters')),
              const PopupMenuItem(value: 'trail', child: Text('Trails')),
              const PopupMenuItem(value: 'village', child: Text('Villages')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_userPosition != null) {
                _mapController.move(_userPosition!, 14);
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTokens.accent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTokens.text),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Inter', color: AppTokens.text),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _init,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: _userPosition != null ? 13 : 6,
                        minZoom: 3,
                        maxZoom: 18,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.pocket_medic',
                          maxZoom: 19,
                        ),
                        PolylineLayer(
                          polylines: _buildPolylines(),
                        ),
                        MarkerLayer(markers: _buildMarkers()),
                        if (_userPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _userPosition!,
                                width: 24,
                                height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_snapResult != null)
                                Marker(
                                  point: _snapResult!.point,
                                  width: 20,
                                  height: 20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.route, color: Colors.white, size: 10),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    if (_snapResult != null && _snapResult!.trailName != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.route, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'On trail: ${_snapResult!.trailName} (${(_snapResult!.distanceKm * 1000).round()}m)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: _userPosition == null
          ? null
          : FloatingActionButton.small(
              onPressed: () => _mapController.move(_userPosition!, _mapController.camera.zoom),
              backgroundColor: AppTokens.accent,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
    );
  }

  List<Marker> _buildMarkers() {
    return _places.map((place) {
      final color = _markerColor(place.featureType);
      final dist = place.distanceKm;
      final distText = dist != null
          ? dist < 1
              ? '${(dist * 1000).round()}m'
              : '${dist.toStringAsFixed(1)}km'
          : '';

      return Marker(
        point: LatLng(place.lat, place.lon),
        width: 140,
        height: 52,
        child: GestureDetector(
          onTap: () => _showPlaceSheet(place),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconForType(place.featureType), color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        distText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 2,
                height: 6,
                color: color,
              ),
              Icon(Icons.circle, size: 8, color: color),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];
    for (final place in _places) {
      final geom = place.geometry;
      if (geom == null || geom.length < 2) continue;
      final color = _markerColor(place.featureType);
      polylines.add(
        Polyline(
          points: geom,
          color: color.withValues(alpha: 0.7),
          strokeWidth: place.featureType == 'trail' ? 3.0 : 2.0,
        ),
      );
    }
    return polylines;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'hospital':
      case 'clinic':
        return Icons.local_hospital;
      case 'pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'police':
        return Icons.local_police_outlined;
      case 'fire_station':
        return Icons.fire_truck_outlined;
      case 'spring':
      case 'river':
      case 'stream':
      case 'lake':
        return Icons.water_drop_outlined;
      case 'campsite':
        return Icons.cabin_outlined;
      case 'shelter':
        return Icons.home_outlined;
      case 'trail':
        return Icons.route;
      default:
        return Icons.place_outlined;
    }
  }

  void _showPlaceSheet(Place place) {
    final bearing = place.bearing;
    final compassText = bearing != null
        ? '${OsmService.bearingToArrow(bearing)} ${OsmService.bearingToCompass(bearing)}'
        : '';

    final dist = place.distanceKm;
    final distText = dist != null
        ? dist < 1
            ? '${(dist * 1000).round()} m'
            : '${dist.toStringAsFixed(1)} km'
        : '';

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForType(place.featureType), color: AppTokens.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bearing != null
                  ? '$compassText • ${place.featureType} • $distText'
                  : '${place.featureType} • $distText',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppTokens.accent),
                    onPressed: () {
                      Navigator.pop(context);
                      _mapController.move(LatLng(place.lat, place.lon), 16);
                    },
                    icon: const Icon(Icons.center_focus_strong, size: 18),
                    label: const Text('Center', style: TextStyle(fontFamily: 'Inter')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (_userPosition != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NavigationScreen(
                              place: place,
                              start: _userPosition!,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Route', style: TextStyle(fontFamily: 'Inter')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
