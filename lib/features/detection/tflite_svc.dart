import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'sensor_vector.dart';
import 'fallback_detector.dart';

class TFLiteService {
  Interpreter? _interp;
  final _fallback = FallbackDetector();
  bool get isLoaded => _interp != null;

  Future<void> load() async {
    try {
      _interp = await Interpreter.fromAsset('assets/crash_model.tflite');
      
      // Verify API & Model compatibility (especially for ^0.12.1 updates)
      final inputShape = _interp!.getInputTensors()[0].shape.toString();
      final outputShape = _interp!.getOutputTensors()[0].shape.toString();

      if (inputShape != '[1, 5]' || outputShape != '[1, 1]') {
        debugPrint('TFLite Model shape mismatch! Input: $inputShape (expected [1, 5]), '
            'Output: $outputShape (expected [1, 1]). Fallback will be used.');
        _interp?.close();
        _interp = null;
        return;
      }

      debugPrint('TFLite loaded. Input: ${_interp!.getInputTensors()} '
          'Output: ${_interp!.getOutputTensors()}');
    } catch (e) {
      debugPrint('TFLite load error: $e — fallback detector will be used');
    }
  }

  double infer(SensorVector v) {
    if (_interp == null) {
      return _fallback.detect(v) ? 0.90 : 0.05;
    }
    try {
      final input  = [v.toFloat32List()]; // shape [1, 5]
      final output = [List.filled(1, 0.0)]; // shape [1, 1]
      _interp!.run(input, output);
      return output[0][0].clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('TFLite inference error: $e — using fallback');
      return _fallback.detect(v) ? 0.90 : 0.05;
    }
  }

  void dispose() => _interp?.close();
}
