import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/constants.dart';
import '../../services/local_dispatch_service.dart';
import '../../services/local_event_log_service.dart';

class CountdownNotifier extends StateNotifier<int> {
  Timer? _timer;
  final LocalDispatchService _dispatch;
  final LocalEventLogService _eventLog;
  final _player = AudioPlayer();
  DispatchResult? lastResult;

  CountdownNotifier(this._dispatch, this._eventLog)
      : super(AppConstants.countdownSecs);

  void start() {
    if (_timer != null) return;
    _vibrate();
    _player.play(AssetSource('sounds/alert.mp3')).catchError((_) {});
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state <= 1) {
        _timer?.cancel(); _timer = null; state = 0;
        _runDispatch();
      } else {
        state--;
        if (state % 10 == 0) _vibrate();
      }
    });
  }

  void cancel() {
    _timer?.cancel(); _timer = null;
    state = AppConstants.countdownSecs;
    Vibration.cancel();
    _player.stop();
    _eventLog.logEvent(label: 'DISMISSED', confidence: 0.0, speedKmh: 0.0);
  }

  void triggerSOS() {
    _timer?.cancel(); _timer = null;
    state = 0;
    _runDispatch();
  }

  void _runDispatch() {
    Vibration.cancel();
    _player.stop();
    _dispatch.send().then((r) {
      lastResult = r;
      debugPrint('[Countdown] Dispatch done: alertId=${r.alertId} called=${r.called}');
    });
  }

  void _vibrate() => Vibration.vibrate(pattern: [0, 500, 200, 500]);

  @override
  void dispose() { _timer?.cancel(); _player.dispose(); super.dispose(); }
}
