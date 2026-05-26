import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'services/local_notification_service.dart';

void main() async {
  // 1. Mandatory Flutter Init
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('CrashGuard: Launching...');

  // 2. Run App Immediately to dismiss native splash ASAP
  runApp(const ProviderScope(child: CrashGuardApp()));

  // 3. Background Services Initialization (Non-blocking)
  initBackgroundServicesAsync();
}

Future<void> initBackgroundServicesAsync() async {
  try {
    // Basic Hive Init (just the path)
    await Hive.initFlutter();
    
    // Services
    await LocalNotificationService.init();
    
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
    debugPrint('CrashGuard: Async Services Ready');
  } catch (e) {
    debugPrint('CrashGuard: Async Init Error: $e');
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
