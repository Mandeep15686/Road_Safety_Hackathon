import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../features/health/health_model.dart';

/// Manages health profile entirely in local Hive storage.
/// Replaces GET/POST /health backend calls.
class LocalHealthService {
  HealthProfile? getProfile() =>
      Hive.box<HealthProfile>(AppConstants.boxHealth).get('profile');

  Future<void> saveProfile(HealthProfile profile) async =>
      Hive.box<HealthProfile>(AppConstants.boxHealth).put('profile', profile);

  bool get hasProfile => getProfile() != null;
}
