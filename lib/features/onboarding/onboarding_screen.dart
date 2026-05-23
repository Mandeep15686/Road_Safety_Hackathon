import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/widgets/theme_toggle.dart';
import '../../core/widgets/animations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _State();
}

class _State extends State<OnboardingScreen> {
  bool _loading = false;

  Future<void> _requestPermissions() async {
    setState(() => _loading = true);
    await [Permission.location, Permission.microphone,
           Permission.locationAlways, Permission.activityRecognition,
           Permission.phone]
        .request();
    if (mounted) context.go('/health');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const ThemeToggle(),
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const FadeInTranslate(
            delay: Duration(milliseconds: 100),
            child: Icon(Icons.shield_rounded, size: 80, color: Color(0xFFE05252)),
          ),
          const SizedBox(height: 24),
          const FadeInTranslate(
            delay: Duration(milliseconds: 200),
            child: Text('Welcome to CrashGuard',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          const FadeInTranslate(
            delay: Duration(milliseconds: 300),
            child: Text('AI-powered crash detection with automatic emergency dispatch.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7D8590))),
          ),
          const SizedBox(height: 40),
          ...[
            ('Location', 'For emergency GPS coordinates', Icons.location_on_rounded),
            ('Microphone', 'For crash audio detection', Icons.mic_rounded),
            ('Motion', 'For accelerometer-based detection', Icons.sensors_rounded),
            ('Phone', 'For direct emergency calling', Icons.phone_android_rounded),
          ].indexed.map((item) {
            final i = item.$1;
            final e = item.$2;
            return FadeInTranslate(
              delay: Duration(milliseconds: 400 + (i * 100)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Icon(e.$3, color: const Color(0xFF58A6FF), size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(e.$2, style: const TextStyle(color: Color(0xFF7D8590), fontSize: 12)),
                  ])),
                ]),
              ),
            );
          }),
          const SizedBox(height: 40),
          FadeInTranslate(
            delay: const Duration(milliseconds: 800),
            child: SizedBox(width: double.infinity,
              child: BouncingWidget(
                onTap: _loading ? null : _requestPermissions,
                child: ElevatedButton(
                  onPressed: _loading ? null : () {}, // Handled by BouncingWidget
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Grant Permissions & Continue'),
                ),
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}
