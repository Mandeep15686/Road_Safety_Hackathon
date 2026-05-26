import 'dart:math';

/// Represents a nearby emergency or vehicle service place
/// fetched from OpenStreetMap Overpass API and cached in Hive.
class NearbyPlace {
  final String id;
  final String name;
  final String category; // hospital | police | ambulance | towing | puncture | showroom | other
  final double lat;
  final double lng;
  final double distanceKm;
  final String? phone;
  final String? address;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.phone,
    this.address,
  });

  // ── Factory: parse one Overpass API element ──────────────────────────────
  factory NearbyPlace.fromOverpassElement(
    Map<String, dynamic> el,
    double userLat,
    double userLng,
  ) {
    final tags = Map<String, dynamic>.from(el['tags'] as Map? ?? {});

    // Overpass returns lat/lon for nodes; ways return a "center" object
    double lat = 0, lng = 0;
    if (el['type'] == 'node') {
      lat = (el['lat'] as num).toDouble();
      lng = (el['lon'] as num).toDouble();
    } else if (el['center'] != null) {
      lat = (el['center']['lat'] as num).toDouble();
      lng = (el['center']['lon'] as num).toDouble();
    }

    return NearbyPlace(
      id:          el['id'].toString(),
      name:        (tags['name'] ?? tags['name:en'] ?? 'Unnamed').toString(),
      category:    _categoryFromTags(tags),
      lat:         lat,
      lng:         lng,
      distanceKm:  haversine(userLat, userLng, lat, lng),
      phone:       (tags['phone'] ?? tags['contact:phone'])?.toString(),
      address:     _buildAddress(tags),
    );
  }

  // ── Category detection from OSM tags ───────────────────────────────────
  static String _categoryFromTags(Map<String, dynamic> t) {
    final amenity   = t['amenity']?.toString()  ?? '';
    final shop      = t['shop']?.toString()     ?? '';
    final emergency = t['emergency']?.toString() ?? '';
    final service   = t['service']?.toString()  ?? '';

    if (['hospital', 'clinic', 'doctors', 'pharmacy'].contains(amenity)) {
      return 'hospital';
    }
    if (amenity == 'police') return 'police';
    if (amenity == 'fire_station' || emergency == 'ambulance_station') {
      return 'ambulance';
    }
    if (shop == 'tyres' || t['service:vehicle:tyres']?.toString() == 'yes') {
      return 'puncture';
    }
    if (['car', 'car_repair', 'vehicle', 'car_parts'].contains(shop)) {
      return 'showroom';
    }
    if (service == 'towing' || amenity == 'car_rental') return 'towing';
    return 'other';
  }

  // ── Build a readable address string from OSM addr: tags ─────────────────
  static String? _buildAddress(Map<String, dynamic> t) {
    final parts = <String>[
      if (t['addr:housenumber'] != null) t['addr:housenumber'].toString(),
      if (t['addr:street']      != null) t['addr:street'].toString(),
      if (t['addr:city']        != null) t['addr:city'].toString(),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  // ── Haversine distance formula (returns km) ──────────────────────────────
  static double haversine(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // ── JSON serialisation (for Hive caching) ───────────────────────────────
  Map<String, dynamic> toJson() => {
        'id':          id,
        'name':        name,
        'category':    category,
        'lat':         lat,
        'lng':         lng,
        'distanceKm':  distanceKm,
        'phone':       phone,
        'address':     address,
      };

  factory NearbyPlace.fromJson(Map<String, dynamic> j) => NearbyPlace(
        id:          j['id'] as String,
        name:        j['name'] as String,
        category:    j['category'] as String,
        lat:         (j['lat'] as num).toDouble(),
        lng:         (j['lng'] as num).toDouble(),
        distanceKm:  (j['distanceKm'] as num).toDouble(),
        phone:       j['phone'] as String?,
        address:     j['address'] as String?,
      );
}
