import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/widgets/animations.dart';

class DispatchingScreen extends ConsumerStatefulWidget {
  const DispatchingScreen({super.key});
  @override ConsumerState<DispatchingScreen> createState() => _State();
}

class _State extends ConsumerState<DispatchingScreen> {
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _dispatch();
  }

  Future<void> _dispatch() async {
    try {
      // LocalDispatchService: saves to Hive + dials emergency number
      final result = await ref.read(dispatchServiceProvider).send();
      if (mounted) {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.pushReplacement('/confirmation', extra: result.alertId);
      }
    } catch (e) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0A0C0F),
    body: Center(child: _error
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            const FadeInTranslate(
              delay: Duration(milliseconds: 100),
              child: Icon(Icons.warning_rounded, size: 64, color: Color(0xFFE05252)),
            ),
            const SizedBox(height: 16),
            const FadeInTranslate(
              delay: Duration(milliseconds: 200),
              child: Text('Dispatch failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                child: ElevatedButton(onPressed: () {}, // Handled by BouncingWidget
                    child: const Text('Back to Home')),
              ),
            ),
          ])
        : const Column(mainAxisSize: MainAxisSize.min, children: [
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
          ]),
    ),
  );
}
