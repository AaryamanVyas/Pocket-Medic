import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_tokens.dart';
import '../models/place.dart';
import '../services/osm_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<Place> _hospitals = [];
  List<Place> _police = [];
  bool _loading = true;

  static const _defaultLat = 13.0827;
  static const _defaultLon = 80.2707;

  @override
  void initState() {
    super.initState();
    _loadEmergencyPlaces();
  }

  Future<void> _loadEmergencyPlaces() async {
    try {
      double lat = _defaultLat;
      double lon = _defaultLon;

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            );
            lat = pos.latitude;
            lon = pos.longitude;
          }
        }
      } catch (_) {}

      final hospitals = await OsmService.findByType(
        lat: lat, lon: lon, featureType: 'hospital', radiusKm: 50, limit: 5,
      );
      final police = await OsmService.findByType(
        lat: lat, lon: lon, featureType: 'police', radiusKm: 50, limit: 5,
      );
      setState(() {
        _hospitals = hospitals;
        _police = police;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Actions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            Icons.call,
            'Call emergency helpline',
            '112 / 108',
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: '112');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Nearest Hospitals',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppTokens.accent))
          else if (_hospitals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hospitals found. Place survival.sqlite in Downloads.',
                  style: TextStyle(fontFamily: 'Inter', color: AppTokens.text),
                ),
              ),
            )
          else
            ..._hospitals.map((h) => _placeTile(h)),
          const SizedBox(height: 16),
          const Text(
            'Nearest Police',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          if (_police.isEmpty && !_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No police stations found nearby.',
                  style: TextStyle(fontFamily: 'Inter', color: AppTokens.text),
                ),
              ),
            )
          else
            ..._police.map((p) => _placeTile(p)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTokens.accent),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title tapped (UI stub).')),
          );
        },
      ),
    );
  }

  Widget _placeTile(Place place) {
    final dist = place.distanceKm;
    final distText = dist != null
        ? dist < 1
            ? '${(dist * 1000).round()} m'
            : '${dist.toStringAsFixed(1)} km'
        : '';

    final bearing = place.bearing;
    final compassText = bearing != null
        ? '${OsmService.bearingToArrow(bearing)} ${OsmService.bearingToCompass(bearing)}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.local_hospital, color: AppTokens.accent),
          title: Text(
            place.name,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            bearing != null
                ? '$compassText • ${place.featureType} • $distText'
                : '${place.featureType} • $distText',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
          ),
          trailing: TextButton(
            onPressed: () async {
              final geoUri = Uri.parse('geo:0,0?q=${place.lat},${place.lon}(${Uri.encodeComponent(place.name)})');
              final mapsUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lon}');
              if (await canLaunchUrl(geoUri)) {
                await launchUrl(geoUri);
              } else if (await canLaunchUrl(mapsUri)) {
                await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No maps app found. Install Google Maps.')),
                );
              }
            },
            child: const Text('Route'),
          ),
        ),
      ),
    );
  }
}
