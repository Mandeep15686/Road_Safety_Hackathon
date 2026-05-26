import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../providers/providers.dart';
import '../health/health_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
    _boot();
  }

  Future<void> _boot() async {
    try {
      // 1. Hive Initialization
      setState(() => _status = 'Loading database...');
      await Hive.initFlutter();
      
      // Register adapters (only if not already registered)
      _registerIfAbsent(0, () => Hive.registerAdapter(HealthProfileAdapter()));
      _registerIfAbsent(1, () => Hive.registerAdapter(DetectionLogAdapter()));
      _registerIfAbsent(2, () => Hive.registerAdapter(AlertQueueItemAdapter()));
      _registerIfAbsent(3, () => Hive.registerAdapter(AlertRecordAdapter()));

      // Open boxes with a collective timeout
      await Future.wait([
        Hive.openBox(AppConstants.boxSettings),
        Hive.openBox<HealthProfile>(AppConstants.boxHealth),
        Hive.openBox<DetectionLog>(AppConstants.boxLog),
        Hive.openBox<AlertQueueItem>(AppConstants.boxQueue),
        Hive.openBox<AlertRecord>(AppConstants.boxAlerts),
      ]).timeout(const Duration(seconds: 10));

      // 2. TFLite Initialization
      setState(() => _status = 'Loading AI model...');
      await ref.read(tfliteServiceProvider).load().timeout(
        const Duration(seconds: 5),
        onTimeout: () => debugPrint('Splash: TFLite load timed out'),
      );
      
    } catch (e) {
      debugPrint('Splash: Boot Error: $e');
      setState(() => _status = 'Continuing startup...');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    try {
      final box = Hive.box<HealthProfile>(AppConstants.boxHealth);
      final hasProfile = box.isOpen && box.get('profile') != null;
      context.go(hasProfile ? '/home' : '/onboarding');
    } catch (e) {
      debugPrint('Splash: Navigation Error: $e');
      context.go('/onboarding'); // Fallback
    }
  }

  void _registerIfAbsent(int typeId, void Function() register) {
    if (!Hive.isAdapterRegistered(typeId)) {
      register();
    }
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FadeTransition(
      opacity: _fade,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE05252).withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_rounded, size: 72, color: Color(0xFFE05252)),
        ),
        const SizedBox(height: 24),
        const Text('CrashGuard',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_status,
            style: const TextStyle(color: Color(0xFF7D8590), fontSize: 14)),
        const SizedBox(height: 40),
        const SizedBox(width: 28, height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFE05252))),
      ])),
    ),
  );
}
