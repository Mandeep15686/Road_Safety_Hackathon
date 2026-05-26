import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../providers/providers.dart';
import '../../core/widgets/animations.dart';
import 'place_model.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  String _selectedCategory = 'all';
  final _scrollController = ScrollController();
  bool _showFab = false;

  // ── Category metadata ─────────────────────────────────────────────────────
  static const _categories = [
    {'key': 'all',       'label': 'All',       'icon': Icons.apps_rounded},
    {'key': 'hospital',  'label': 'Hospital',  'icon': Icons.local_hospital_rounded},
    {'key': 'police',    'label': 'Police',    'icon': Icons.local_police_rounded},
    {'key': 'ambulance', 'label': 'Ambulance', 'icon': Icons.emergency_rounded},
    {'key': 'towing',    'label': 'Towing',    'icon': Icons.car_repair_rounded},
    {'key': 'puncture',  'label': 'Puncture',  'icon': Icons.tire_repair_rounded},
    {'key': 'showroom',  'label': 'Showroom',  'icon': Icons.directions_car_rounded},
  ];

  static const _colors = <String, Color>{
    'hospital':  Color(0xFF58A6FF),
    'police':    Color(0xFFD29922),
    'ambulance': Color(0xFFE05252),
    'towing':    Color(0xFF8B949E),
    'puncture':  Color(0xFF3FB950),
    'showroom':  Color(0xFFBC8CFF),
    'other':     Color(0xFF7D8590),
  };

  static const _icons = <String, IconData>{
    'hospital':  Icons.local_hospital_rounded,
    'police':    Icons.local_police_rounded,
    'ambulance': Icons.emergency_rounded,
    'towing':    Icons.car_repair_rounded,
    'puncture':  Icons.tire_repair_rounded,
    'showroom':  Icons.directions_car_rounded,
    'other':     Icons.place_rounded,
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showFab) setState(() => _showFab = show);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _call(String number) async {
    HapticFeedback.mediumImpact();
    final ok = await FlutterPhoneDirectCaller.callNumber(number);
    if (ok == null || !ok) {
      await launchUrl(Uri(scheme: 'tel', path: number));
    }
  }

  Future<void> _directions(NearbyPlace p) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}&travelmode=driving');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final nearbyAsync = ref.watch(nearbyPlacesProvider);

    return Scaffold(
      floatingActionButton: _showFab
          ? FadeInTranslate(
              offset: const Offset(0, 12),
              child: FloatingActionButton.small(
                backgroundColor: const Color(0xFF58A6FF),
                onPressed: () => _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              ),
            )
          : null,
      body: RefreshIndicator(
        color: const Color(0xFF58A6FF),
        displacement: 80,
        onRefresh: () {
          HapticFeedback.mediumImpact();
          ref.invalidate(nearbyPlacesProvider);
          return ref.read(nearbyPlacesProvider.future);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── App bar ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              stretch: true,
              centerTitle: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              actions: [
                IconButton(
                  icon: const Icon(Icons.map_rounded),
                  tooltip: 'Map view',
                  onPressed: () => context.push('/map'),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(nearbyPlacesProvider);
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Nearby Services',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF58A6FF).withOpacity(0.08),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Category filter chips ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _CategoryFilter(
                selected: _selectedCategory,
                categories: _categories,
                onSelect: (k) => setState(() => _selectedCategory = k),
              ),
            ),

            // ── Results ────────────────────────────────────────────────────
            nearbyAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(nearbyPlacesProvider),
                ),
              ),
              data: (places) {
                final filtered = _selectedCategory == 'all'
                    ? places
                    : places
                        .where((p) => p.category == _selectedCategory)
                        .toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyView(category: _selectedCategory),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final p = filtered[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FadeInTranslate(
                            delay: Duration(milliseconds: 80 + i * 40),
                            child: _NearbyCard(
                              place:        p,
                              color:        _colors[p.category] ?? _colors['other']!,
                              icon:         _icons[p.category]  ?? _icons['other']!,
                              onCall:       p.phone != null ? () => _call(p.phone!) : null,
                              onDirections: () => _directions(p),
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category filter chips ────────────────────────────────────────────────────
class _CategoryFilter extends StatelessWidget {
  final String selected;
  final List<Map<String, dynamic>> categories;
  final void Function(String) onSelect;

  const _CategoryFilter(
      {required this.selected,
      required this.categories,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat        = categories[i];
          final isSelected = selected == cat['key'];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(cat['key'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF58A6FF)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF58A6FF)
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 14,
                  color: isSelected ? Colors.white : const Color(0xFF7D8590),
                ),
                const SizedBox(width: 4),
                Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : const Color(0xFF7D8590),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Single result card ────────────────────────────────────────────────────────
class _NearbyCard extends StatelessWidget {
  final NearbyPlace  place;
  final Color        color;
  final IconData     icon;
  final VoidCallback? onCall;
  final VoidCallback  onDirections;

  const _NearbyCard({
    required this.place,
    required this.color,
    required this.icon,
    required this.onCall,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ────────────────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                place.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (place.address != null) ...[
                const SizedBox(height: 2),
                Text(
                  place.address!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7D8590)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ]),
          ),
          // Distance badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${place.distanceKm.toStringAsFixed(1)} km',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ]),

        const SizedBox(height: 10),

        // ── Action buttons ────────────────────────────────────────────────
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDirections,
              icon:  const Icon(Icons.directions_rounded, size: 14),
              label: const Text('Directions', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (onCall != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon:  const Icon(Icons.call_rounded, size: 14),
                label: Text(
                  place.phone!,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3FB950),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

// ── Empty + error states ───────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final String category;
  const _EmptyView({required this.category});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No ${category == 'all' ? 'services' : '$category services'} found within 5 km',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7D8590)),
          ),
        ]),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message.contains('denied')
                  ? 'Location permission required.\nGo to Settings → Apps → CrashGuard → Permissions.'
                  : 'Could not load services.\nShowing cached data if available.\n\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7D8590), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ]),
        ),
      );
}
