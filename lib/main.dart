import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'core/constants.dart';
import 'features/health/health_model.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('CrashGuard: Initializing...');

  // 1. Hive Essential Init (Must happen before runApp for theme/state)
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(HealthProfileAdapter());
    Hive.registerAdapter(DetectionLogAdapter());
    Hive.registerAdapter(AlertQueueItemAdapter());
    Hive.registerAdapter(AlertRecordAdapter());
    
    // Open settings first (for theme) with timeout
    await Hive.openBox(AppConstants.boxSettings).timeout(const Duration(seconds: 5));
    
    // Open others with timeout
    await Future.wait([
      Hive.openBox<HealthProfile>(AppConstants.boxHealth),
      Hive.openBox<DetectionLog>(AppConstants.boxLog),
      Hive.openBox<AlertQueueItem>(AppConstants.boxQueue),
      Hive.openBox<AlertRecord>(AppConstants.boxAlerts),
    ]).timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('CrashGuard: Hive Init Failed: $e');
  }

  // 2. Non-blocking Init (Notifications & Background Service)
  // We don't await these here to prevent blocking the UI startup
  _initServicesAsync();

  runApp(const ProviderScope(child: CrashGuardApp()));
}

Future<void> _initServicesAsync() async {
  try {
    await LocalNotificationService.init();
    await _initBackgroundService();
    debugPrint('CrashGuard: Services Initialized');
  } catch (e) {
    debugPrint('CrashGuard: Async Init Error: $e');
  }
}

Future<void> _initBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'crash_guard_channel',
      initialNotificationTitle: 'CrashGuard',
      initialNotificationContent: 'Monitoring for accidents…',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onServiceStart,
    ),
  );
  
  if (await Permission.location.isGranted) {
    await service.startService();
  }
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
        title: 'CrashGuard Active', content: 'Monitoring for accidents…');
  }
  service.on('stopService').listen((_) => service.stopSelf());
}
