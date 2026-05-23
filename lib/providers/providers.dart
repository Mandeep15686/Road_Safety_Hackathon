import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/detection/sensor_svc.dart';
import '../features/detection/tflite_svc.dart';
import '../features/detection/sensor_vector.dart';
import '../features/alert/countdown_notifier.dart';
import '../services/local_dispatch_service.dart';
import '../services/local_emergency_service.dart';
import '../services/local_event_log_service.dart';
import '../services/local_health_service.dart';
import '../services/local_alert_history_service.dart';
import '../core/constants.dart';

// ── Detection services ──────────────────────────────────────────────────────
final sensorServiceProvider = Provider<SensorService>((ref) {
  final s = SensorService()..start();
  ref.onDispose(s.dispose);
  return s;
});

final tfliteServiceProvider = Provider<TFLiteService>((ref) {
  final s = TFLiteService();
  ref.onDispose(s.dispose);
  return s;
});

// ── Sensor streams ──────────────────────────────────────────────────────────
final sensorStreamProvider = StreamProvider<SensorVector>((ref) =>
    ref.watch(sensorServiceProvider).stream);

final confidenceProvider = Provider<double>((ref) {
  final vec = ref.watch(sensorStreamProvider).value;
  if (vec == null) return 0.0;
  final score = ref.read(tfliteServiceProvider).infer(vec);
  // Update dispatch service with latest confidence
  ref.read(dispatchServiceProvider).updateConfidence(score);
  return score;
});

final crashDetectedProvider = Provider<bool>((ref) =>
    ref.watch(confidenceProvider) > AppConstants.threshold);

final speedKmhProvider = Provider<double>((ref) =>
    (ref.watch(sensorStreamProvider).value?.gpsSpeed ?? 0.0) * 3.6);

final accelMagProvider = Provider<double>((ref) =>
    ref.watch(sensorStreamProvider).value?.accelMag ?? 0.0);

final gyroMagProvider = Provider<double>((ref) =>
    ref.watch(sensorStreamProvider).value?.gyroMag ?? 0.0);

final audioLevelProvider = Provider<double>((ref) =>
    ref.watch(sensorStreamProvider).value?.audioAmp ?? 0.0);

final latitudeProvider = Provider<double>((ref) =>
    ref.watch(sensorStreamProvider).value?.lat ?? 0.0);

final longitudeProvider = Provider<double>((ref) =>
    ref.watch(sensorStreamProvider).value?.lng ?? 0.0);

// ── Local services (replaces all backend calls) ─────────────────────────────
final dispatchServiceProvider =
    Provider<LocalDispatchService>((ref) => LocalDispatchService());

final emergencyHelplineServiceProvider =
    Provider<LocalEmergencyService>((ref) => LocalEmergencyService());

final eventLogServiceProvider =
    Provider<LocalEventLogService>((ref) => LocalEventLogService());

final healthServiceProvider =
    Provider<LocalHealthService>((ref) => LocalHealthService());

final alertHistoryServiceProvider =
    Provider<LocalAlertHistoryService>((ref) => LocalAlertHistoryService());

// ── Theme State ─────────────────────────────────────────────────────────────
final themeProvider = StateNotifierProvider<AppThemeNotifier, ThemeMode>((ref) {
  return AppThemeNotifier();
});

/// Tracks the tap position for the circular reveal animation
final themeSwitchOffsetProvider = StateProvider<Offset?>((ref) => null);

class AppThemeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode_preference';
  SharedPreferences? _prefs;

  AppThemeNotifier() : super(ThemeMode.system) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedMode = _prefs?.getString(_key);
    if (savedMode != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedMode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _prefs?.setString(_key, mode.toString());
  }

  void toggle() {
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else if (state == ThemeMode.light) {
      setTheme(ThemeMode.system);
    } else {
      setTheme(ThemeMode.dark);
    }
  }
}

// ── Emergency Helplines (fully offline) ─────────────────────────────────────
final emergencyHelplinesProvider = FutureProvider<List<EmergencyHelpline>>((ref) =>
    ref.read(emergencyHelplineServiceProvider).getEmergencyHelplines());

// ── Countdown ────────────────────────────────────────────────────────────────
final countdownProvider =
    StateNotifierProvider<CountdownNotifier, int>((ref) =>
        CountdownNotifier(ref.read(dispatchServiceProvider),
                          ref.read(eventLogServiceProvider)));
