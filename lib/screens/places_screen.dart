import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_tokens.dart';
import '../models/place.dart';
import '../services/osm_service.dart';

class PlacesLocatorScreen extends StatefulWidget {
  const PlacesLocatorScreen({super.key});

  @override
  State<PlacesLocatorScreen> createState() => _PlacesLocatorScreenState();
}

class _PlacesLocatorScreenState extends State<PlacesLocatorScreen> {
  List<Place> _places = [];
  bool _loading = true;
  String? _error;
  String? _selectedType;

  static const _defaultLat = 13.0827;
  static const _defaultLon = 80.2707;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pos = await _getCurrentPosition();
      final lat = pos?.latitude ?? _defaultLat;
      final lon = pos?.longitude ?? _defaultLon;

      final places = await OsmService.findNearby(
        lat: lat,
        lon: lon,
        radiusKm: 50.0,
        featureType: _selectedType,
        limit: 20,
      );
      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places (offline)'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) {
              setState(() => _selectedType = type);
              _loadPlaces();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All types')),
              const PopupMenuItem(value: 'hospital', child: Text('Hospitals')),
              const PopupMenuItem(value: 'clinic', child: Text('Clinics')),
              const PopupMenuItem(value: 'pharmacy', child: Text('Pharmacies')),
              const PopupMenuItem(value: 'police', child: Text('Police')),
              const PopupMenuItem(value: 'fire_station', child: Text('Fire stations')),
              const PopupMenuItem(value: 'town', child: Text('Towns')),
              const PopupMenuItem(value: 'village', child: Text('Villages')),
              const PopupMenuItem(value: 'city', child: Text('Cities')),
              const PopupMenuItem(value: 'spring', child: Text('Springs')),
              const PopupMenuItem(value: 'river', child: Text('Rivers')),
              const PopupMenuItem(value: 'campsite', child: Text('Campsites')),
              const PopupMenuItem(value: 'shelter', child: Text('Shelters')),
            ],
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
                        const Text(
                          'Could not load places',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTokens.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppTokens.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Place survival.sqlite in your Downloads folder.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            color: AppTokens.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _places.isEmpty
                  ? const Center(
                      child: Text(
                        'No places found nearby.',
                        style: TextStyle(fontFamily: 'Inter', color: AppTokens.text),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPlaces,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _places.length,
                        itemBuilder: (_, index) {
                          final place = _places[index];
                          return _PlaceCard(place: place);
                        },
                      ),
                    ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;

  const _PlaceCard({required this.place});

  IconData _iconForType(String type) {
    switch (type) {
      case 'hospital':
        return Icons.local_hospital;
      case 'clinic':
        return Icons.medical_services_outlined;
      case 'pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'police':
        return Icons.local_police_outlined;
      case 'fire_station':
        return Icons.fire_truck_outlined;
      case 'town':
      case 'city':
        return Icons.location_city_outlined;
      case 'village':
        return Icons.cottage_outlined;
      case 'spring':
      case 'river':
      case 'stream':
      case 'lake':
        return Icons.water_drop_outlined;
      case 'campsite':
        return Icons.cabin_outlined;
      case 'shelter':
        return Icons.home_outlined;
      case 'road':
      case 'trail':
        return Icons.route;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dist = place.distanceKm;
    final distText = dist != null
        ? dist < 1
            ? '${(dist * 1000).round()} m'
            : '${dist.toStringAsFixed(1)} km'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(_iconForType(place.featureType), color: AppTokens.accent),
          title: Text(
            place.name,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${place.featureType} • $distText'),
          trailing: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Route to ${place.name} (stub).')),
              );
            },
            child: const Text('Route'),
          ),
        ),
      ),
    );
  }
}
