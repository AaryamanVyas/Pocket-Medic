import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/navigation_service.dart';
import '../theme/app_tokens.dart';

class NavigationScreen extends StatefulWidget {
  final Place place;
  final LatLng start;

  const NavigationScreen({super.key, required this.place, required this.start});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  late final NavigationRoute _route;
  late final LatLng _destination;

  @override
  void initState() {
    super.initState();
    _destination = LatLng(widget.place.lat, widget.place.lon);
    _route = NavigationService.buildRoute(start: widget.start, end: _destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            onPressed: () => _mapController.move(widget.start, 15),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.start,
                initialZoom: 14,
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
                  polylines: [
                    Polyline(
                      points: _route.points,
                      color: AppTokens.accent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: widget.start,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 3)),
                      ),
                    ),
                  ),
                  Marker(
                    point: _destination,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTokens.accent,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 3)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox.shrink(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(top: BorderSide(color: AppTokens.border, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route to ${widget.place.name}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Distance: ${NavigationService.formatDistance(_route.totalDistanceKm)}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                ),
                const SizedBox(height: 12),
                ..._route.steps.take(4).map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            _arrowForBearing(step.bearing),
                            style: const TextStyle(fontSize: 18, color: AppTokens.accent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${step.instruction} • ${NavigationService.formatDistance(step.distanceMeters / 1000)}',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _arrowForBearing(double bearing) {
    const arrows = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'];
    return arrows[(bearing / 45).round() % 8];
  }
}
