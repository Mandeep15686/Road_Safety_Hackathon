import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../features/nearby/place_model.dart';

/// Fetches nearby emergency & vehicle services from OpenStreetMap Overpass API.
/// Completely FREE — no API key required.
class NearbyService {
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const int radiusMeters = 5000; // 5 km search radius

  // ── Get current GPS position ─────────────────────────────────────────────
  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied. Enable in device Settings.');
    }

    // Try high-accuracy first, fall back to last known position
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw Exception('Could not get location. Please check GPS signal.');
    }
  }

  // ── Main fetch: queries Overpass for all required categories ─────────────
  Future<List<NearbyPlace>> fetchNearby() async {
    final pos = await _getPosition();
    final lat = pos.latitude;
    final lng = pos.longitude;

    // Overpass QL — covers all 6 hackathon-required categories
    final query = '''
[out:json][timeout:25];
(
  node["amenity"~"hospital|clinic|doctors|pharmacy"](around:$radiusMeters,$lat,$lng);
  way["amenity"~"hospital|clinic"](around:$radiusMeters,$lat,$lng);
  node["amenity"="police"](around:$radiusMeters,$lat,$lng);
  way["amenity"="police"](around:$radiusMeters,$lat,$lng);
  node["amenity"="fire_station"](around:$radiusMeters,$lat,$lng);
  node["emergency"="ambulance_station"](around:$radiusMeters,$lat,$lng);
  node["shop"="tyres"](around:$radiusMeters,$lat,$lng);
  node["service:vehicle:tyres"="yes"](around:$radiusMeters,$lat,$lng);
  node["shop"~"car|car_repair|vehicle|car_parts"](around:$radiusMeters,$lat,$lng);
  way["shop"~"car|car_repair"](around:$radiusMeters,$lat,$lng);
  node["service"="towing"](around:$radiusMeters,$lat,$lng);
  node["amenity"="car_rental"](around:$radiusMeters,$lat,$lng);
);
out center;
''';

    final response = await http.post(
      Uri.parse(_overpassUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'CrashGuardApp/1.0 (com.crashguard.app)',
      },
      body: {'data': query},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Overpass API error (${response.statusCode}). Check internet.');
    }

    final data   = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List<dynamic>? ?? []);

    final places = <NearbyPlace>[];
    for (final el in elements) {
      try {
        final place = NearbyPlace.fromOverpassElement(
            el as Map<String, dynamic>, lat, lng);
        // Filter unnamed, zero-coord, and "other" with no phone
        if (place.name != 'Unnamed' && place.lat != 0 && place.lng != 0) {
          places.add(place);
        }
      } catch (_) {
        // Skip malformed elements silently
      }
    }

    // Sort nearest first
    places.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return places;
  }

  /// Returns just the user's current GPS position (used by map screen).
  Future<Position> getCurrentPosition() => _getPosition();
}
