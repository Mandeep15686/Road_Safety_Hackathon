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
      debugPrint('Splash: Loading TFLite...');
      // Load TFLite with a timeout to prevent hanging
      await ref.read(tfliteServiceProvider).load().timeout(
        const Duration(seconds: 4),
        onTimeout: () => debugPrint('Splash: TFLite load timed out'),
      );
    } catch (e) {
      debugPrint('Splash: TFLite Error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    try {
      final hasProfile = Hive.box<HealthProfile>(AppConstants.boxHealth)
          .get('profile') != null;
      context.go(hasProfile ? '/home' : '/onboarding');
    } catch (e) {
      debugPrint('Splash: Navigation Error: $e');
      context.go('/onboarding'); // Fallback
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
        const Text('AI-powered emergency detection',
            style: TextStyle(color: Color(0xFF7D8590), fontSize: 14)),
        const SizedBox(height: 40),
        const SizedBox(width: 28, height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFE05252))),
      ])),
    ),
  );
}
