import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/nearby/place_model.dart';
import '../core/constants.dart';

/// Caches Overpass API results in the existing Hive boxSettings box.
/// Provides offline fallback so nearby services work with zero signal.
class NearbyCacheService {
  // Keys inside boxSettings
  static const _keyPlaces    = 'nearby_places_cache';
  static const _keyTimestamp = 'nearby_cache_ts';
  static const _keyLat       = 'nearby_cache_lat';
  static const _keyLng       = 'nearby_cache_lng';

  // Cache is "fresh" for 30 minutes; re-fetch if user moves >2 km
  static const _maxAgeMinutes = 30;
  static const _maxDistKm     = 2.0;

  Box get _box => Hive.box(AppConstants.boxSettings);

  // ── Save results to Hive ─────────────────────────────────────────────────
  Future<void> save(
      List<NearbyPlace> places, double lat, double lng) async {
    final json = jsonEncode(places.map((p) => p.toJson()).toList());
    await _box.put(_keyPlaces,    json);
    await _box.put(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
    await _box.put(_keyLat,       lat);
    await _box.put(_keyLng,       lng);
  }

  /// Returns cached data only if it is still fresh AND close to current GPS.
  /// Returns null if cache is stale or user has moved too far.
  List<NearbyPlace>? loadFresh(double currentLat, double currentLng) {
    final ts = _box.get(_keyTimestamp) as int?;
    if (ts == null) return null;

    // Age check
    final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
    if (ageMs > _maxAgeMinutes * 60 * 1000) return null;

    // Distance check — re-fetch if moved significantly
    final cachedLat = _box.get(_keyLat) as double?;
    final cachedLng = _box.get(_keyLng) as double?;
    if (cachedLat != null && cachedLng != null) {
      final dist = NearbyPlace.haversine(
          currentLat, currentLng, cachedLat, cachedLng);
      if (dist > _maxDistKm) return null;
    }

    return _parse();
  }

  /// True if ANY cached data exists (even stale) — used for offline fallback.
  bool hasAnyCache() => _box.containsKey(_keyPlaces);

  /// Returns stale cached data (offline fallback — shown with a warning banner).
  List<NearbyPlace> loadStale() => _parse() ?? [];

  List<NearbyPlace>? _parse() {
    final raw = _box.get(_keyPlaces) as String?;
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => NearbyPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Returns the timestamp of cached data as a human-readable string.
  String? cacheAgeLabel() {
    final ts = _box.get(_keyTimestamp) as int?;
    if (ts == null) return null;
    final dt  = DateTime.fromMillisecondsSinceEpoch(ts);
    final age = DateTime.now().difference(dt);
    if (age.inMinutes < 1)  return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24)   return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }
}
