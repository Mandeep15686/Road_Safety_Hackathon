import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../core/widgets/connectivity_banner.dart';
import '../../core/widgets/theme_toggle.dart';
import '../../core/widgets/animations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _countdownStarted = false;
  late ScrollController _scrollController;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showBackToTop) {
        setState(() => _showBackToTop = show);
      }
    });

    // Listen for crash events from the background service
    FlutterBackgroundService().on('crash_detected').listen((event) {
      if (mounted && !_countdownStarted) {
        debugPrint('HomeScreen: Received crash event from background');
        setState(() => _countdownStarted = true);
        ref.read(countdownProvider.notifier).start();
        context.push('/countdown');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    // Simulate a reload or trigger a provider refresh
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidence = ref.watch(confidenceProvider);
    final speed      = ref.watch(speedKmhProvider);
    final lat        = ref.watch(latitudeProvider);
    final lng        = ref.watch(longitudeProvider);

    ref.listen(crashDetectedProvider, (_, crashed) {
      if (crashed && !_countdownStarted) {
        setState(() => _countdownStarted = true);
        ref.read(countdownProvider.notifier).start();
        context.push('/countdown');
      }
      if (!crashed) {
        setState(() => _countdownStarted = false);
      }
    });

    return Scaffold(
      floatingActionButton: _showBackToTop
          ? FadeInTranslate(
              offset: const Offset(0, 10),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFFE05252),
                onPressed: () {
                  _scrollController.animateTo(0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic);
                },
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFFE05252),
        displacement: 80,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              pinned: true,
              stretch: true,
              centerTitle: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: const ThemeToggle(),
              actions: const [Padding(padding: EdgeInsets.only(right: 12), child: OfflineChip())],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text('CrashGuard',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontWeight: FontWeight.bold)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFE05252).withValues(alpha: 0.1),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeInTranslate(
                    delay: const Duration(milliseconds: 100),
                    child: _StatusChip(confidence: confidence),
                  ),
                  const SizedBox(height: 20),
                  FadeInTranslate(
                    delay: const Duration(milliseconds: 200),
                    child: BouncingWidget(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // Optional: trigger immediately on tap if desired, 
                        // but SOS is currently long-press only.
                        // We'll leave this to provide haptic/ripple on tap.
                      },
                      child: GestureDetector(
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          ref.read(countdownProvider.notifier).triggerSOS();
                          context.push('/dispatching');
                        },
                        child: Container(
                          width: double.infinity, height: 64,
                          decoration: BoxDecoration(color: const Color(0xFFE05252),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(
                                  color: const Color(0xFFE05252).withValues(alpha: .4),
                                  blurRadius: 20, spreadRadius: 2)]),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('SOS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Hold 2 seconds', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ]),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInTranslate(
                    delay: const Duration(milliseconds: 300),
                    child: Row(children: [
                      Expanded(child: BouncingWidget(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Live speed monitoring active')),
                          );
                        },
                        child: _StatCard(label: 'Speed',
                            value: speed.toStringAsFixed(0),
                            unit: 'km/h', icon: Icons.speed_rounded, color: const Color(0xFF58A6FF)),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: BouncingWidget(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI confidence score')),
                          );
                        },
                        child: _StatCard(label: 'Confidence',
                            value: (confidence * 100).toStringAsFixed(1),
                            unit: '%', icon: Icons.psychology_rounded,
                            color: _confColor(confidence)),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  const FadeInTranslate(
                    delay: Duration(milliseconds: 400),
                    child: _DetectionStatusBlock(),
                  ),
                  const SizedBox(height: 14),
                  const FadeInTranslate(
                    delay: Duration(milliseconds: 500),
                    child: Row(children: [
                      Expanded(child: _QuickCallBtn(label: 'Ambulance', num: '108', color: Color(0xFF58A6FF))),
                      SizedBox(width: 10),
                      Expanded(child: _QuickCallBtn(label: 'Police/Fire', num: '112', color: Color(0xFFD29922))),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  FadeInTranslate(
                    delay: const Duration(milliseconds: 600),
                    child: _SensorDataBlock(lat: lat, lng: lng),
                  ),
                  const SizedBox(height: 14),
                  FadeInTranslate(
                    delay: const Duration(milliseconds: 700),
                    child: _buildEmergencyMedicalCard(context),
                  ),
                  const SizedBox(height: 40), // Extra space at bottom
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Color _confColor(double c) => c > 0.75 ? const Color(0xFFE05252)
      : c > 0.4 ? const Color(0xFFD29922) : const Color(0xFF3FB950);

  Widget _buildEmergencyMedicalCard(BuildContext context) {
    return Hero(
      tag: 'medical_info_card',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFE05252).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE05252).withValues(alpha: 0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.medical_services_rounded, color: Color(0xFFE05252), size: 20),
                SizedBox(width: 8),
                Text('Emergency Medical Card', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE05252))),
              ]),
              const SizedBox(height: 12),
              const Text('Fill your vital medical info for responders to see during an accident.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7D8590))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: BouncingWidget(
                  onTap: () => context.push('/health'),
                  child: ElevatedButton(
                    onPressed: () {}, // Handled by BouncingWidget
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE05252),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Manage Medical Info', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectionStatusBlock extends StatelessWidget {
  const _DetectionStatusBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.circle, size: 10, color: Color(0xFF3FB950)),
          SizedBox(width: 6),
          Text('Detection active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
        SizedBox(height: 4),
        Text('TFLite on-device · 50 Hz · No internet needed',
            style: TextStyle(color: Color(0xFF7D8590), fontSize: 12)),
      ]),
    );
  }
}

class _SensorDataBlock extends StatelessWidget {
  final double lat, lng;
  const _SensorDataBlock({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Live Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _sensorItem('Latitude', lat.toStringAsFixed(6), Icons.location_on_rounded)),
          Expanded(child: _sensorItem('Longitude', lng.toStringAsFixed(6), Icons.explore_rounded)),
        ]),
      ]),
    );
  }

  Widget _sensorItem(String label, String value, IconData icon) => Column(children: [
    Icon(icon, size: 16, color: const Color(0xFF7D8590)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
    Text(label, style: const TextStyle(color: Color(0xFF7D8590), fontSize: 10)),
  ]);
}

class _QuickCallBtn extends StatelessWidget {
  final String label, num; final Color color;
  const _QuickCallBtn({required this.label, required this.num, required this.color});
  @override
  Widget build(BuildContext context) => BouncingWidget(
    onTap: () {
      HapticFeedback.mediumImpact();
      launchUrl(Uri(scheme: 'tel', path: num));
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: .3))),
      child: Column(children: [
        Icon(Icons.call_rounded, color: color, size: 18),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        Text(num, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final double confidence;
  const _StatusChip({required this.confidence});
  @override
  Widget build(BuildContext context) {
    final isCrash = confidence > 0.75;
    final col = isCrash ? const Color(0xFFE05252) : const Color(0xFF3FB950);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: col.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(30), border: Border.all(color: col.withValues(alpha: .4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isCrash ? Icons.warning_rounded : Icons.check_circle_rounded, size: 18, color: col),
        const SizedBox(width: 8),
        Text(isCrash ? 'CRASH DETECTED' : 'MONITORING',
            style: TextStyle(fontWeight: FontWeight.bold, color: col)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, unit; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.unit, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFF7D8590), fontSize: 12))]),
      const SizedBox(height: 8),
      RichText(text: TextSpan(children: [
        TextSpan(text: value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        TextSpan(text: ' $unit', style: const TextStyle(fontSize: 13, color: Color(0xFF7D8590))),
      ])),
    ]),
  );
}
