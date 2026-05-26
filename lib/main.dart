import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'core/constants.dart';
import 'features/detection/sensor_svc.dart';
import 'features/detection/tflite_svc.dart';
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
    // 1. Initialize Notifications & Create the Channel
    await LocalNotificationService.init();
    debugPrint('CrashGuard: Notification Channel Created');
    
    // 2. Configure Background Service
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'crash_guard_channel',
        initialNotificationTitle: 'CrashGuard Active',
        initialNotificationContent: 'Monitoring for accidents in background',
        foregroundServiceNotificationId: 999,
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
  // Ensure background service is truly isolated and initialized
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Initialize Detection Services in Background
  final tflite = TFLiteService();
  final sensors = SensorService();

  try {
    await tflite.load();
    sensors.start();
    debugPrint('CrashGuard: Background Detection Started');
  } catch (e) {
    debugPrint('CrashGuard: Background Init Error: $e');
  }

  sensors.stream.listen((vector) {
    final confidence = tflite.infer(vector);
    
    if (confidence > AppConstants.threshold) {
      debugPrint('CrashGuard: Background CRASH DETECTED! Confidence: $confidence');
      
      // Notify the UI layer if it is running
      service.invoke('crash_detected', {
        'confidence': confidence,
        'lat': vector.lat,
        'lng': vector.lng,
      });

      // Update notification for immediate user feedback
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: '⚠️ CRASH DETECTED',
          content: 'Tap to open CrashGuard and verify your safety.',
        );
      }
    }
  });

  // Keep the service alive and periodic status update
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'CrashGuard Active',
          content: 'Monitoring for accidents in background…',
        );
      }
    }
  });
}
