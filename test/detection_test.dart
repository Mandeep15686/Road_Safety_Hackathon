import 'package:flutter_test/flutter_test.dart';
import 'package:crash_guard/features/detection/sensor_vector.dart';
import 'package:crash_guard/features/detection/fallback_detector.dart';

void main() {
  group('SensorVector normalisation', () {
    test('clamps all values to [0, 1]', () {
      final vec = SensorVector(accelMag: 999, gyroMag: 999, gpsSpeed: 999,
          audioAmp: 999999, jerk: 999, timestamp: DateTime.now(), lat: 0, lng: 0);
      for (final v in vec.toNormalisedList()) {
        expect(v, lessThanOrEqualTo(1.0));
        expect(v, greaterThanOrEqualTo(0.0));
      }
    });

    test('produces 5 values', () {
      final vec = SensorVector(accelMag: 5, gyroMag: 2, gpsSpeed: 15,
          audioAmp: 1000, jerk: 10, timestamp: DateTime.now(), lat: 0, lng: 0);
      expect(vec.toNormalisedList().length, equals(5));
    });
  });

  group('FallbackDetector', () {
    final det = FallbackDetector();

    test('detects high-accel moving crash', () {
      final vec = SensorVector(accelMag: 60, gyroMag: 5, gpsSpeed: 20,
          audioAmp: 5000, jerk: 40, timestamp: DateTime.now(), lat: 0, lng: 0);
      expect(det.detect(vec), isTrue);
    });

    test('ignores static phone drop (speed=0)', () {
      final vec = SensorVector(accelMag: 60, gyroMag: 5, gpsSpeed: 0,
          audioAmp: 100, jerk: 40, timestamp: DateTime.now(), lat: 0, lng: 0);
      expect(det.detect(vec), isFalse);
    });

    test('ignores low-jerk bump', () {
      final vec = SensorVector(accelMag: 60, gyroMag: 5, gpsSpeed: 20,
          audioAmp: 100, jerk: 5, timestamp: DateTime.now(), lat: 0, lng: 0);
      expect(det.detect(vec), isFalse);
    });
  });
}
