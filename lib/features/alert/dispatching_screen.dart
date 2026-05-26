import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/widgets/animations.dart';

class DispatchingScreen extends ConsumerWidget {
  const DispatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dispatchState = ref.watch(dispatchResultProvider);

    // Listen for completion to navigate
    ref.listen(dispatchResultProvider, (previous, next) {
      if (next != null && next is AsyncData) {
        final result = next.value;
        if (result != null) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (context.mounted) {
              context.pushReplacement('/confirmation', extra: result.alertId);
            }
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0F),
      body: Center(
        child: dispatchState?.when(
          data: (result) => _buildLoadingState(), // Still loading transition
          error: (err, stack) => _buildErrorState(context),
          loading: () => _buildLoadingState(),
        ) ?? _buildLoadingState(),
      ),
    );
  }

  Widget _buildLoadingState() => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FadeInTranslate(
        delay: Duration(milliseconds: 100),
        child: SizedBox(
          width: 64, height: 64,
          child: CircularProgressIndicator(
              strokeWidth: 3, color: Color(0xFFE05252)),
        ),
      ),
      SizedBox(height: 28),
      FadeInTranslate(
        delay: Duration(milliseconds: 200),
        child: Text('Calling emergency services…',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      SizedBox(height: 8),
      FadeInTranslate(
        delay: Duration(milliseconds: 300),
        child: Text('Dialling 112 on your phone',
            style: TextStyle(color: Color(0xFF7D8590))),
      ),
      SizedBox(height: 4),
      FadeInTranslate(
        delay: Duration(milliseconds: 400),
        child: Text('Alert saved on device',
            style: TextStyle(color: Color(0xFF3FB950), fontSize: 12)),
      ),
    ],
  );

  Widget _buildErrorState(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const FadeInTranslate(
        delay: Duration(milliseconds: 100),
        child: Icon(Icons.warning_rounded, size: 64, color: Color(0xFFE05252)),
      ),
      const SizedBox(height: 16),
      const FadeInTranslate(
        delay: Duration(milliseconds: 200),
        child: Text('Dispatch failed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 8),
      const FadeInTranslate(
        delay: Duration(milliseconds: 300),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text('Alert saved locally. Please call 112 or 108 manually.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7D8590))),
        ),
      ),
      const SizedBox(height: 24),
      FadeInTranslate(
        delay: const Duration(milliseconds: 400),
        child: BouncingWidget(
          onTap: () => context.go('/home'),
          child: ElevatedButton(
              onPressed: () {}, // Handled by BouncingWidget
              child: const Text('Back to Home')),
        ),
      ),
    ],
  );
}
