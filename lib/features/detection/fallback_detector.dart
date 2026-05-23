import '../../core/constants.dart';
import 'sensor_vector.dart';

/// Rule-based fallback used when TFLite model fails to load.
class FallbackDetector {
  bool detect(SensorVector v) {
    return v.accelMag > AppConstants.accelGate * AppConstants.maxAccel * 0.6 &&
           v.jerk     > 20.0 &&
           v.gpsSpeed > 2.0; // not just a dropped phone
  }
}
