import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import 'animations.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    final key = GlobalKey();

    IconData getIcon() {
      switch (mode) {
        case ThemeMode.dark: return Icons.light_mode_rounded;
        case ThemeMode.light: return Icons.brightness_auto_rounded;
        case ThemeMode.system: return Icons.dark_mode_rounded;
      }
    }

    String getTooltip() {
      switch (mode) {
        case ThemeMode.dark: return 'Switch to light mode';
        case ThemeMode.light: return 'Switch to system mode';
        case ThemeMode.system: return 'Switch to dark mode';
      }
    }

    return BouncingWidget(
      key: key,
      onTap: () {
        // Capture button position for animation
        final RenderBox box = key.currentContext?.findRenderObject() as RenderBox;
        final Offset position = box.localToGlobal(Offset.zero);
        final center = Offset(position.dx + box.size.width / 2, position.dy + box.size.height / 2);
        
        ref.read(themeSwitchOffsetProvider.notifier).state = center;
        ref.read(themeProvider.notifier).toggle();
      },
      child: IconButton(
        icon: Icon(getIcon()),
        onPressed: null, // Handled by BouncingWidget
        tooltip: getTooltip(),
      ),
    );
  }
}
