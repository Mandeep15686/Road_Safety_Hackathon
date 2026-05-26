import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import 'place_model.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  static const _colors = <String, Color>{
    'hospital':  Color(0xFF58A6FF),
    'police':    Color(0xFFD29922),
    'ambulance': Color(0xFFE05252),
    'towing':    Color(0xFF8B949E),
    'puncture':  Color(0xFF3FB950),
    'showroom':  Color(0xFFBC8CFF),
    'other':     Color(0xFF7D8590),
  };

  static const _icons = <String, IconData>{
    'hospital':  Icons.local_hospital_rounded,
    'police':    Icons.local_police_rounded,
    'ambulance': Icons.emergency_rounded,
    'towing':    Icons.car_repair_rounded,
    'puncture':  Icons.tire_repair_rounded,
    'showroom':  Icons.directions_car_rounded,
    'other':     Icons.place_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyAsync = ref.watch(nearbyPlacesProvider);
    final userLat     = ref.watch(latitudeProvider);
    final userLng     = ref.watch(longitudeProvider);

    // Fall back to centre of India if GPS not yet acquired
    final center = (userLat == 0 && userLng == 0)
        ? const LatLng(20.5937, 78.9629)
        : LatLng(userLat, userLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Map'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          // Legend
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showLegend(context),
          ),
        ],
      ),
      body: nearbyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text(e.toString())),
        data:    (places) => FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom:   13.0,
            minZoom:       5,
            maxZoom:       18,
          ),
          children: [
            // ── Base tile layer (OpenStreetMap — no API key) ──────────────
            TileLayer(
              urlTemplate:        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.yourteam.crashguard',
            ),

            // ── Place markers ─────────────────────────────────────────────
            MarkerLayer(
              markers: [
                // User position
                if (userLat != 0 && userLng != 0)
                  Marker(
                    point:  LatLng(userLat, userLng),
                    width:  44,
                    height: 44,
                    child:  _UserMarker(),
                  ),
                // Service markers
                ...places.map((p) => Marker(
                      point:  LatLng(p.lat, p.lng),
                      width:  40,
                      height: 40,
                      child:  GestureDetector(
                        onTap: () => _showPlaceSheet(context, p),
                        child: _PlaceMarker(
                          color: _colors[p.category] ?? _colors['other']!,
                          icon:  _icons[p.category]  ?? _icons['other']!,
                        ),
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet on marker tap ─────────────────────────────────────────────
  void _showPlaceSheet(BuildContext context, NearbyPlace p) {
    final color = _colors[p.category] ?? const Color(0xFF7D8590);
    final icon  = _icons[p.category]  ?? Icons.place_rounded;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding:    const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '${p.distanceKm.toStringAsFixed(1)} km away',
                      style: TextStyle(
                          color: color, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                )),
              ]),
              if (p.address != null) ...[
                const SizedBox(height: 8),
                Text(p.address!,
                    style: const TextStyle(
                        color: Color(0xFF7D8590), fontSize: 12)),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1'
                          '&destination=${p.lat},${p.lng}&travelmode=driving');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    icon:  const Icon(Icons.directions_rounded, size: 16),
                    label: const Text('Directions'),
                  ),
                ),
                if (p.phone != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await launchUrl(Uri(scheme: 'tel', path: p.phone));
                      },
                      icon:  const Icon(Icons.call_rounded, size: 16),
                      label: Text(p.phone!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3FB950),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 8),
            ]),
      ),
    );
  }

  // ── Legend bottom sheet ───────────────────────────────────────────────────
  void _showLegend(BuildContext context) {
    final items = [
      ('Hospital / Clinic',  const Color(0xFF58A6FF), Icons.local_hospital_rounded),
      ('Police Station',     const Color(0xFFD29922), Icons.local_police_rounded),
      ('Ambulance / Fire',   const Color(0xFFE05252), Icons.emergency_rounded),
      ('Towing / Rescue',    const Color(0xFF8B949E), Icons.car_repair_rounded),
      ('Puncture Shop',      const Color(0xFF3FB950), Icons.tire_repair_rounded),
      ('Car Showroom',       const Color(0xFFBC8CFF), Icons.directions_car_rounded),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Map Legend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: item.$2, shape: BoxShape.circle),
                      child: Icon(item.$3, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(item.$1,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ]),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Marker widgets ──────────────────────────────────────────────────────────
class _UserMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:  Colors.blue.withOpacity(0.15),
          shape:  BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 2.5),
        ),
        child: const Icon(Icons.my_location_rounded,
            color: Colors.blue, size: 22),
      );
}

class _PlaceMarker extends StatelessWidget {
  final Color    color;
  final IconData icon;
  const _PlaceMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:  color,
          shape:  BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color:       color.withOpacity(0.4),
                blurRadius:  6,
                spreadRadius: 1),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      );
}
