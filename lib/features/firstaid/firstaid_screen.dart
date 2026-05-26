import 'package:flutter/material.dart';
import '../../core/widgets/animations.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  int? _expanded;

  // ── Guide content — fully offline ────────────────────────────────────────
  static const _guides = [
    _Guide(
      title:   'Step 1 — Call for Help',
      urgency: 'Do this IMMEDIATELY',
      icon:    Icons.call_rounded,
      color:   Color(0xFFE05252),
      steps:   [
        'Call 112 (or your country\'s emergency number) without delay.',
        'State your exact location — street name, landmark, city.',
        'Describe the accident: number of vehicles, estimated injured persons.',
        'Stay on the line until the operator tells you to hang up.',
        'If possible, send your GPS coordinates via WhatsApp to a contact.',
      ],
    ),
    _Guide(
      title:   'Step 2 — Scene Safety',
      urgency: 'Before approaching anyone',
      icon:    Icons.warning_amber_rounded,
      color:   Color(0xFFD29922),
      steps:   [
        'Do NOT approach if you see a fuel leak, fire, or smoke.',
        'Turn off any vehicle engine if safely reachable.',
        'Switch on hazard lights; place warning triangles 50 m back.',
        'Keep bystanders at least 30 metres from the wreck.',
        'Never smoke or allow open flames near the scene.',
      ],
    ),
    _Guide(
      title:   'Step 3 — Check Consciousness',
      urgency: 'Assess each victim',
      icon:    Icons.accessibility_new_rounded,
      color:   Color(0xFF58A6FF),
      steps:   [
        'Tap the victim\'s shoulder firmly and shout their name.',
        'If unresponsive: look, listen, and feel for breathing (10 seconds).',
        'If breathing normally — place in the recovery (lateral) position.',
        'If NOT breathing — start CPR immediately (see CPR step).',
        'Check pupils: unequal or non-reactive pupils → head injury suspected.',
      ],
    ),
    _Guide(
      title:   'Step 4 — CPR',
      urgency: 'Only if not breathing & no pulse',
      icon:    Icons.favorite_rounded,
      color:   Color(0xFFE05252),
      steps:   [
        'Lay person flat on a firm surface on their back.',
        'Place the heel of your hand on the centre of the chest (lower half of breastbone).',
        'Press down 5–6 cm, 30 times at 100–120 compressions per minute.',
        'Tilt head back, lift chin, give 2 rescue breaths (1 second each).',
        'Repeat 30:2 cycle without stopping until paramedics arrive or AED available.',
      ],
    ),
    _Guide(
      title:   'Step 5 — Control Bleeding',
      urgency: 'Act fast — every second counts',
      icon:    Icons.bloodtype_rounded,
      color:   Color(0xFFE05252),
      steps:   [
        'Put on gloves; use a plastic bag if gloves unavailable.',
        'Apply firm, continuous direct pressure with a clean cloth.',
        'Do NOT remove the cloth — add more layers on top if soaked through.',
        'Elevate the injured limb above heart level if possible.',
        'Apply tourniquet only if trained and bleeding is life-threatening.',
      ],
    ),
    _Guide(
      title:   'Step 6 — Spinal Injury Precaution',
      urgency: 'Extreme caution — do not rush',
      icon:    Icons.do_not_touch_rounded,
      color:   Color(0xFF8B949E),
      steps:   [
        'Do NOT move the person unless there is immediate life danger (fire).',
        'Immobilise head, neck, and spine in the position found.',
        'Talk calmly to keep the person still and reassured.',
        'If must move: perform a log-roll with minimum 3 people.',
        'Always wait for trained paramedics to extricate from vehicle.',
      ],
    ),
    _Guide(
      title:   'Step 7 — Burns from Fire',
      urgency: 'Cool the burn immediately',
      icon:    Icons.local_fire_department_rounded,
      color:   Color(0xFFD29922),
      steps:   [
        'Move victim away from the fire source safely.',
        'Cool burn under cool (not cold/ice) running water for 20 minutes.',
        'Never apply ice, butter, toothpaste, or any cream.',
        'Remove jewellery, watches, and tight clothing near the burn.',
        'Cover loosely with cling film, a clean bag, or non-fluffy cloth.',
      ],
    ),
    _Guide(
      title:   'Step 8 — Manage Shock',
      urgency: 'Stabilise victim until help arrives',
      icon:    Icons.emergency_rounded,
      color:   Color(0xFF3FB950),
      steps:   [
        'Lay person flat; elevate legs 20–30 cm unless head, chest, or spine injury.',
        'Keep the person warm — cover with a blanket or jacket.',
        'Do NOT give food, water, or any medication orally.',
        'Talk calmly and continuously — reassurance reduces shock severity.',
        'Check breathing every minute and adjust if condition changes.',
      ],
    ),
    _Guide(
      title:   'Golden Hour Reminder',
      urgency: 'The first 60 minutes are critical',
      icon:    Icons.timer_rounded,
      color:   Color(0xFFBC8CFF),
      steps:   [
        '"Golden Hour" = the 60 minutes after trauma when rapid care saves lives.',
        'Your #1 goal: get the victim to a trauma centre within this window.',
        'Every minute of delay worsens outcomes — call emergency services first.',
        'Even if the victim says they are fine, insist on hospital evaluation.',
        'Internal bleeding and brain injury may show no immediate symptoms.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned:      true,
            stretch:     true,
            centerTitle: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'First Aid Guide',
                style: TextStyle(
                  color:      Theme.of(context).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF3FB950).withValues(alpha: 0.08),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Disclaimer banner ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin:  const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color:        const Color(0xFFE05252).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(
                    color: const Color(0xFFE05252).withValues(alpha: 0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Color(0xFFE05252)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '100% offline. Call emergency services first — '
                    'this guide is a quick reference only.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFFE05252)),
                  ),
                ),
              ]),
            ),
          ),

          // ── Guide cards ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => FadeInTranslate(
                  delay: Duration(milliseconds: 60 + i * 50),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GuideCard(
                      guide:      _guides[i],
                      isExpanded: _expanded == i,
                      onTap: () => setState(
                          () => _expanded = _expanded == i ? null : i),
                    ),
                  ),
                ),
                childCount: _guides.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _Guide {
  final String       title;
  final String       urgency;
  final IconData     icon;
  final Color        color;
  final List<String> steps;

  const _Guide({
    required this.title,
    required this.urgency,
    required this.icon,
    required this.color,
    required this.steps,
  });
}

// ── Card widget ───────────────────────────────────────────────────────────────
class _GuideCard extends StatelessWidget {
  final _Guide      guide;
  final bool        isExpanded;
  final VoidCallback onTap;

  const _GuideCard({
    required this.guide,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color:        Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(
            color: isExpanded
                ? guide.color.withValues(alpha: 0.45)
                : Theme.of(context).dividerColor,
            width: isExpanded ? 1.5 : 1.0,
          ),
        ),
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                padding:    const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        guide.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(guide.icon, color: guide.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(guide.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(guide.urgency,
                      style: TextStyle(
                          fontSize:   11,
                          color:      guide.color,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.grey[400],
              ),
            ]),
          ),

          // ── Steps (animated expand) ─────────────────────────────────────
          AnimatedCrossFade(
            duration:   const Duration(milliseconds: 220),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild:  const SizedBox.shrink(),
            secondChild: Container(
              width:   double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child:   Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  const SizedBox(height: 12),
                  ...guide.steps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:   Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width:      24,
                              height:     24,
                              decoration: BoxDecoration(
                                color: guide.color.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.bold,
                                    color:      guide.color,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                    fontSize: 12.5, height: 1.55),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
