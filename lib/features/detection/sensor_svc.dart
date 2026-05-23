import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:noise_meter/noise_meter.dart';
import 'sensor_vector.dart';

class SensorService {
  final _controller = StreamController<SensorVector>.broadcast();
  double _prevAccel = 0, _gyroMag = 0, _speed = 0, _audio = 0, _lat = 0, _lng = 0;
  double _lastJerk = 0;
  StreamSubscription? _accelSub, _gyroSub, _gpsSub, _noiseSub;
  Timer? _refreshTimer;
  final _noiseMeter = NoiseMeter();

  void start() {
    // Accelerometer at high rate
    _accelSub = accelerometerEventStream().listen((e) {
      final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      // Jerk calculation (da/dt) assuming ~50Hz (0.02s interval)
      _lastJerk = (mag - _prevAccel).abs() / 0.02;
      _prevAccel = mag;
      _emit(); // Emit on every accel event for live data
    });

    // Gyroscope
    _gyroSub = gyroscopeEventStream().listen((e) {
      _gyroMag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    });

    // GPS speed - high accuracy
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((p) {
      _speed = p.speed < 0 ? 0 : p.speed;
      _lat = p.latitude;
      _lng = p.longitude;
      _emit();
    });

    // Audio level
    try {
      _noiseSub = _noiseMeter.noise.listen((e) {
        _audio = e.meanDecibel;
      });
    } catch (e) {
      // Noise meter might fail on some platforms/emulators
    }

    // Fallback timer to ensure UI updates even if sensors are quiet
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => _emit());
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(SensorVector(
      accelMag: _prevAccel,
      gyroMag: _gyroMag,
      gpsSpeed: _speed,
      audioAmp: _audio,
      lat: _lat,
      lng: _lng,
      jerk: _lastJerk,
      timestamp: DateTime.now(),
    ));
  }

  Stream<SensorVector> get stream => _controller.stream;

  void dispose() {
    _refreshTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _gpsSub?.cancel();
    _noiseSub?.cancel();
    _controller.close();
  }
}
