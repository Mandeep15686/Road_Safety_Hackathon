import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../features/health/health_model.dart';

/// Logs every detection event to local Hive storage.
/// Replaces POST /event backend call.
class LocalEventLogService {
  Future<void> logEvent({
    required String label,
    required double confidence,
    required double speedKmh,
    double lat = 0.0,
    double lng = 0.0,
  }) async {
    final box = Hive.box<DetectionLog>(AppConstants.boxLog);
    await box.add(DetectionLog(
      id: const Uuid().v4(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      label: label,
      confidence: confidence,
      lat: lat,
      lng: lng,
      synced: true,
    ));
  }

  /// Returns all saved logs sorted newest first.
  List<DetectionLog> getAllLogs() {
    return Hive.box<DetectionLog>(AppConstants.boxLog)
        .values
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Returns count of accidents detected.
  int get accidentCount => Hive.box<DetectionLog>(AppConstants.boxLog)
      .values
      .where((l) => l.label == 'ACCIDENT')
      .length;
}
