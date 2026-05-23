import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/widgets/animations.dart';

class CountdownScreen extends ConsumerWidget {
  const CountdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secs = ref.watch(countdownProvider);

    // Navigate when reaches 0
    ref.listen(countdownProvider, (_, next) {
      if (next == 0 && context.mounted) context.pushReplacement('/dispatching');
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A0505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const FadeInTranslate(
              delay: Duration(milliseconds: 100),
              child: Icon(Icons.warning_rounded, size: 64, color: Color(0xFFE05252)),
            ),
            const SizedBox(height: 24),
            const FadeInTranslate(
              delay: Duration(milliseconds: 200),
              child: Text('ACCIDENT DETECTED',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Color(0xFFE05252), letterSpacing: .1)),
            ),
            const SizedBox(height: 12),
            const FadeInTranslate(
              delay: Duration(milliseconds: 300),
              child: Text('Emergency services will be called in',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7D8590), fontSize: 15)),
            ),
            const SizedBox(height: 32),
            // Countdown circle
            FadeInTranslate(
              delay: const Duration(milliseconds: 400),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: secs / 30.0),
                duration: const Duration(milliseconds: 500),
                builder: (_, v, __) => Stack(alignment: Alignment.center, children: [
                  SizedBox(width: 180, height: 180,
                      child: CircularProgressIndicator(
                          value: v, strokeWidth: 6,
                          color: const Color(0xFFE05252),
                          backgroundColor: const Color(0xFF21262D))),
                  Text('$secs',
                      style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ]),
              ),
            ),
            const SizedBox(height: 48),
            FadeInTranslate(
              delay: const Duration(milliseconds: 500),
              child: SizedBox(width: double.infinity,
                child: BouncingWidget(
                  onTap: () { 
                    ref.read(countdownProvider.notifier).cancel(); 
                    context.pop(); 
                  },
                  child: ElevatedButton.icon(
                    onPressed: () {}, // Handled by BouncingWidget
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('CANCEL — I AM SAFE', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21262D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(60)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const FadeInTranslate(
              delay: Duration(milliseconds: 600),
              child: Text('Tap Cancel if you are not in danger',
                  style: TextStyle(color: Color(0xFF7D8590), fontSize: 12)),
            ),
          ]),
        ),
      ),
    );
  }
}
