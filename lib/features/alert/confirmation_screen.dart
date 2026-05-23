import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/theme_toggle.dart';
import '../../core/widgets/animations.dart';

class ConfirmationScreen extends StatelessWidget {
  final String alertId;
  const ConfirmationScreen({super.key, this.alertId = 'N/A'});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const ThemeToggle(),
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FadeInTranslate(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFF3FB950).withValues(alpha: .12), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF3FB950)),
            ),
          ),
          const SizedBox(height: 32),
          const FadeInTranslate(
            delay: Duration(milliseconds: 200),
            child: Text('Help is on the way',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          const FadeInTranslate(
            delay: Duration(milliseconds: 300),
            child: Text('Emergency services have been notified.\nStay calm and stay put.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7D8590), fontSize: 15)),
          ),
          const SizedBox(height: 32),
          FadeInTranslate(
            delay: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.all(16), width: double.infinity,
              decoration: BoxDecoration(
                  color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF21262D))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Alert ID', style: TextStyle(color: Color(0xFF7D8590), fontSize: 12)),
                const SizedBox(height: 4),
                SelectableText(alertId,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              ]),
            ),
          ),
          const Spacer(),
          FadeInTranslate(
            delay: const Duration(milliseconds: 500),
            child: SizedBox(width: double.infinity,
              child: BouncingWidget(
                onTap: () => context.go('/home'),
                child: ElevatedButton(
                  onPressed: () {}, // Handled by BouncingWidget
                  child: const Text('Back to Home'),
                ),
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}
