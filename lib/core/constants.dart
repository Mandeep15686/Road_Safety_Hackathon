/// App-wide constants — fully offline, no server required.
class AppConstants {
  AppConstants._();

  // Detection thresholds
  static const double threshold   = 0.75;
  static const double accelGate   = 3.0;    // m/s²
  static const int    countdownSecs = 30;

  // Emergency number — change to 112 or 108 for production
  static const String emergencyNumber = '112';

  // Normalisation denominators — MUST match model training
  static const double maxAccel  = 20.0;
  static const double maxGyro   = 10.0;
  static const double maxSpeed  = 55.6;
  static const double maxAudio  = 120.0;
  static const double maxJerk   = 50.0;

  // Hive box names
  static const String boxHealth  = 'health_profile';
  static const String boxLog     = 'detection_log';
  static const String boxAlerts  = 'alert_records'; // new local alert store
  static const String boxSettings = 'app_settings';
}
