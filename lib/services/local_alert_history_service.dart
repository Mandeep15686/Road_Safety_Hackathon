import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../features/health/health_model.dart';

/// Reads dispatched alert history from local Hive.
/// Replaces any backend alert history endpoint.
class LocalAlertHistoryService {
  List<AlertRecord> getAll() {
    return Hive.box<AlertRecord>(AppConstants.boxAlerts)
        .values
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  AlertRecord? getLatest() {
    final all = getAll();
    return all.isEmpty ? null : all.first;
  }

  int get totalCount =>
      Hive.box<AlertRecord>(AppConstants.boxAlerts).length;
}
