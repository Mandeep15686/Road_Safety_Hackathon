import 'package:flutter/material.dart';

/// Simple offline status banner — no longer controls dispatch logic.
/// App works 100% offline regardless of network state.
class OfflineReadyBanner extends StatelessWidget {
  final Widget child;
  const OfflineReadyBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child; // always passes through
}

/// Shows a persistent "Works Offline" chip on screens that need it.
class OfflineChip extends StatelessWidget {
  const OfflineChip({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF3FB950).withValues(alpha: .1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF3FB950).withValues(alpha: .3)),
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.offline_bolt_rounded, size: 12, color: Color(0xFF3FB950)),
      SizedBox(width: 4),
      Text('Works Offline',
          style: TextStyle(fontSize: 11, color: Color(0xFF3FB950),
              fontWeight: FontWeight.w500)),
    ]),
  );
}
