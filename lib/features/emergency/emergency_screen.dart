import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../services/local_emergency_service.dart';
import '../../core/widgets/theme_toggle.dart';
import '../../core/widgets/animations.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(emergencyHelplinesProvider);
    await ref.read(emergencyHelplinesProvider.future);
  }

  Future<void> _callNumber(String number) async {
    HapticFeedback.mediumImpact();
    final bool? res = await FlutterPhoneDirectCaller.callNumber(number);
    if (res == null || !res) {
      await launchUrl(Uri(scheme: 'tel', path: number));
    }
  }

  @override
  Widget build(BuildContext context) {
    final helplines = ref.watch(emergencyHelplinesProvider);
    return Scaffold(
      floatingActionButton: _showBackToTop
          ? FadeInTranslate(
              offset: const Offset(0, 10),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFF58A6FF),
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
        color: const Color(0xFF58A6FF),
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(emergencyHelplinesProvider);
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text('Emergency Helplines',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontWeight: FontWeight.bold)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF58A6FF).withValues(alpha: 0.1),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeInTranslate(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  child: const Row(children: [
                    Icon(Icons.offline_bolt_rounded, size: 14, color: Color(0xFF3FB950)),
                    SizedBox(width: 6),
                    Text('National helpline numbers — Fully offline',
                        style: TextStyle(fontSize: 11, color: Color(0xFF7D8590))),
                  ]),
                ),
              ),
            ),
            helplines.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $e'))),
              data: (list) => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final service = list[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FadeInTranslate(
                          delay: Duration(milliseconds: 150 + (i * 50)),
                          child: BouncingWidget(
                            onTap: () => _callNumber(service.phone),
                            child: _EmergencyCard(service: service),
                          ),
                        ),
                      );
                    },
                    childCount: list.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final EmergencyHelpline service;
  const _EmergencyCard({required this.service});

  static const _icons = {
    'emergency': Icons.emergency_rounded,
    'police':    Icons.local_police_rounded,
    'fire':      Icons.local_fire_department_rounded,
    'medical':   Icons.local_hospital_rounded,
    'road':      Icons.add_road_rounded,
    'disaster':  Icons.warning_amber_rounded,
    'women':     Icons.woman_rounded,
    'child':     Icons.child_care_rounded,
    'railway':   Icons.train_rounded,
    'senior':    Icons.elderly_rounded,
    'health':    Icons.health_and_safety_rounded,
  };
  
  static const _colors = {
    'emergency': Color(0xFFE05252),
    'police':    Color(0xFFD29922),
    'fire':      Color(0xFFE05252),
    'medical':   Color(0xFF58A6FF),
    'road':      Color(0xFF8B949E),
    'disaster':  Color(0xFFD29922),
    'women':     Color(0xFFF692CE),
    'child':     Color(0xFF3FB950),
    'railway':   Color(0xFF58A6FF),
    'senior':    Color(0xFFD29922),
    'health':    Color(0xFF3FB950),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[service.type] ?? Colors.grey;
    final isMainEmergency = service.type == 'emergency';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMainEmergency 
            ? const Color(0xFFE05252).withValues(alpha: 0.3) 
            : Theme.of(context).dividerColor,
          width: isMainEmergency ? 2 : 1,
        )),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
          child: Icon(_icons[service.type] ?? Icons.phone_callback_rounded,
              color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(service.name,
              style: TextStyle(
                fontWeight: isMainEmergency ? FontWeight.bold : FontWeight.w600, 
                fontSize: 14,
                color: isMainEmergency ? const Color(0xFFE05252) : null,
              )),
          const SizedBox(height: 3),
          const Text('National Helpline',
              style: TextStyle(color: Color(0xFF7D8590), fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3FB950).withValues(alpha: .12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3FB950).withValues(alpha: .3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.call_rounded, size: 16, color: Color(0xFF3FB950)),
            const SizedBox(width: 4),
            Text(service.phone,
                style: const TextStyle(
                    color: Color(0xFF3FB950), fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
}
