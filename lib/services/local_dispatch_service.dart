import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../features/health/health_model.dart';

/// Fully offline emergency dispatch.
/// No backend server needed — calls emergency number directly via phone dialer.
class LocalDispatchService {
  final double _lastConfidence = 0.90;

  /// Main dispatch — saves alert locally + dials emergency number.
  Future<DispatchResult> send({double? confidence}) async {
    final alertId = const Uuid().v4();
    Position? pos;

    try {
      pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }

    final health =
        Hive.box<HealthProfile>(AppConstants.boxHealth).get('profile');

    final finalConfidence = confidence ?? _lastConfidence;

    // ── Save alert locally to Hive ──
    final alert = AlertRecord(
      id: alertId,
      latitude: pos?.latitude ?? 0.0,
      longitude: pos?.longitude ?? 0.0,
      confidence: finalConfidence,
      healthId: health?.deviceId ?? 'unknown',
      emergencyNum: AppConstants.emergencyNumber,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: 'dispatched',
    );
    await Hive.box<AlertRecord>(AppConstants.boxAlerts).add(alert);

    // ── Log event to detection log ──
    await Hive.box<DetectionLog>(AppConstants.boxLog).add(DetectionLog(
      id: alertId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      label: 'ACCIDENT',
      confidence: finalConfidence,
      lat: pos?.latitude ?? 0.0,
      lng: pos?.longitude ?? 0.0,
      synced: true, // no server to sync to
    ));

    // ── Dial emergency number ──
    final called = await _dialEmergency();

    debugPrint('[LocalDispatch] Alert saved. ID=$alertId called=$called');
    return DispatchResult(alertId: alertId, called: called, success: true);
  }

  Future<bool> _dialEmergency() async {
    final uri = Uri(scheme: 'tel', path: AppConstants.emergencyNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {
      debugPrint('[LocalDispatch] Could not dial: $e');
    }
    return false;
  }
}

class DispatchResult {
  final String alertId;
  final bool called;
  final bool success;
  const DispatchResult(
      {required this.alertId, required this.called, required this.success});
}
