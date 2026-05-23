import 'dart:typed_data';
import '../../core/constants.dart';

class SensorVector {
  final double accelMag, gyroMag, gpsSpeed, audioAmp, jerk, lat, lng;
  final DateTime timestamp;

  const SensorVector({
    required this.accelMag, required this.gyroMag, required this.gpsSpeed,
    required this.audioAmp, required this.jerk, required this.timestamp,
    required this.lat, required this.lng,
  });

  List<double> toNormalisedList() => [
    (accelMag / AppConstants.maxAccel).clamp(0.0, 1.0),
    (gyroMag  / AppConstants.maxGyro ).clamp(0.0, 1.0),
    (gpsSpeed / AppConstants.maxSpeed).clamp(0.0, 1.0),
    (audioAmp / AppConstants.maxAudio).clamp(0.0, 1.0),
    (jerk     / AppConstants.maxJerk ).clamp(0.0, 1.0),
  ];

  Float32List toFloat32List() => Float32List.fromList(toNormalisedList());
}
