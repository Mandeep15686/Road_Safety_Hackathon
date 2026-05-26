import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../core/widgets/animations.dart';
import '../../core/country_emergency.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Share GPS location via the system share sheet ─────────────────────────
  Future<void> _shareLocation(double lat, double lng) async {
    HapticFeedback.heavyImpact();
    if (lat == 0 && lng == 0) {
      _showSnack('Getting location… try again in a moment.');
      return;
    }
    final mapsUrl = 'https://www.google.com/maps?q=$lat,$lng';
    await Share.share(
      '🚨 EMERGENCY — I was in a road accident!\n\n'
      'My location: $mapsUrl\n\n'
      'Coordinates: $lat, $lng\n\n'
      'Please call emergency services or come immediately.',
      subject: 'EMERGENCY — Accident Alert',
    );
  }

  // ── WhatsApp direct share ─────────────────────────────────────────────────
  Future<void> _whatsApp(double lat, double lng) async {
    HapticFeedback.mediumImpact();
    final msg = Uri.encodeComponent(
        '🚨 EMERGENCY! I was in a road accident.\n'
        'My location: https://www.google.com/maps?q=$lat,$lng\n'
        'Please call emergency services immediately!');
    final uri = Uri.parse('whatsapp://send?text=$msg');
    if (!await launchUrl(uri)) {
      await launchUrl(Uri.parse('https://wa.me/?text=$msg'));
    }
  }

  // ── Direct call with haptic + visual feedback ─────────────────────────────
  Future<void> _callNumber(String number) async {
    HapticFeedback.heavyImpact();
    setState(() => _isCalling = true);
    final ok = await FlutterPhoneDirectCaller.callNumber(number);
    if (ok == null || !ok) {
      await launchUrl(Uri(scheme: 'tel', path: number));
    }
    if (mounted) setState(() => _isCalling = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final lat = ref.watch(latitudeProvider);
    final lng = ref.watch(longitudeProvider);

    // In production: derive country from reverse geocoding.
    // For now use India as default (matches target audience).
    const country = CountryEmergency(
      countryCode: 'IN', countryName: 'India',
      police: '100', ambulance: '108', fire: '101', general: '112',
    );

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            centerTitle: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'SOS',
                style: TextStyle(
                  color:      Theme.of(context).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize:   20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFE05252).withOpacity(0.08),
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

                // ── BIG SOS BUTTON ──────────────────────────────────────
                FadeInTranslate(
                  child: Center(
                    child: ScaleTransition(
                      scale: _pulseAnim,
                      child: GestureDetector(
                        onTap: () => _callNumber(country.general),
                        child: Container(
                          width:  200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCalling
                                ? const Color(0xFFE05252).withOpacity(0.6)
                                : const Color(0xFFE05252),
                            boxShadow: [
                              BoxShadow(
                                color:       const Color(0xFFE05252).withOpacity(0.35),
                                blurRadius:  32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isCalling
                                      ? Icons.phone_in_talk_rounded
                                      : Icons.emergency_rounded,
                                  color: Colors.white,
                                  size:  56,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isCalling ? 'CALLING…' : 'TAP FOR SOS',
                                  style: const TextStyle(
                                    color:      Colors.white,
                                    fontSize:   16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  country.general,
                                  style: const TextStyle(
                                      color:    Colors.white70,
                                      fontSize: 14),
                                ),
                              ]),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── GPS location display ──────────────────────────────────
                if (lat != 0 && lng != 0) ...[
                  FadeInTranslate(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color:        const Color(0xFF3FB950).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border:       Border.all(
                            color: const Color(0xFF3FB950).withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_on_rounded,
                            color: Color(0xFF3FB950), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace'),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Share location ────────────────────────────────────────
                FadeInTranslate(
                  delay: const Duration(milliseconds: 150),
                  child: _ActionTile(
                    icon:     Icons.share_rounded,
                    color:    const Color(0xFF58A6FF),
                    title:    'Share My Location',
                    subtitle: 'Sends GPS link via any messaging app',
                    onTap:    () => _shareLocation(lat, lng),
                  ),
                ),
                const SizedBox(height: 10),

                FadeInTranslate(
                  delay: const Duration(milliseconds: 190),
                  child: _ActionTile(
                    icon:     Icons.chat_rounded,
                    color:    const Color(0xFF25D366),
                    title:    'Share via WhatsApp',
                    subtitle: 'Send accident alert to contacts',
                    onTap:    () => _whatsApp(lat, lng),
                  ),
                ),

                const SizedBox(height: 20),
                const _SectionLabel('Direct Emergency Calls'),
                const SizedBox(height: 10),

                // ── Quick-dial tiles ──────────────────────────────────────
                FadeInTranslate(
                  delay: const Duration(milliseconds: 230),
                  child: _ActionTile(
                    icon:     Icons.emergency_rounded,
                    color:    const Color(0xFFE05252),
                    title:    'General Emergency (${country.general})',
                    subtitle: 'All emergency services',
                    onTap:    () => _callNumber(country.general),
                  ),
                ),
                const SizedBox(height: 10),

                FadeInTranslate(
                  delay: const Duration(milliseconds: 260),
                  child: _ActionTile(
                    icon:     Icons.local_hospital_rounded,
                    color:    const Color(0xFFD29922),
                    title:    'Ambulance (${country.ambulance})',
                    subtitle: 'Medical emergency',
                    onTap:    () => _callNumber(country.ambulance),
                  ),
                ),
                const SizedBox(height: 10),

                FadeInTranslate(
                  delay: const Duration(milliseconds: 290),
                  child: _ActionTile(
                    icon:     Icons.local_police_rounded,
                    color:    const Color(0xFF8B949E),
                    title:    'Police (${country.police})',
                    subtitle: 'Accident / crime report',
                    onTap:    () => _callNumber(country.police),
                  ),
                ),
                const SizedBox(height: 10),

                FadeInTranslate(
                  delay: const Duration(milliseconds: 320),
                  child: _ActionTile(
                    icon:     Icons.add_road_rounded,
                    color:    const Color(0xFFBC8CFF),
                    title:    'Highway Helpline (1033)',
                    subtitle: 'National Highways / road accident',
                    onTap:    () => _callNumber('1033'),
                  ),
                ),
                const SizedBox(height: 10),

                FadeInTranslate(
                  delay: const Duration(milliseconds: 350),
                  child: _ActionTile(
                    icon:     Icons.directions_car_rounded,
                    color:    const Color(0xFF3FB950),
                    title:    'Vehicle Rescue (1073)',
                    subtitle: 'Road accident vehicle rescue',
                    onTap:    () => _callNumber('1073'),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable action tile ───────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(children: [
          Container(
            padding:    const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF7D8590))),
              ])),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey[400], size: 20),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      Color(0xFF7D8590),
            letterSpacing: 0.5),
      );
}
