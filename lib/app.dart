import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'providers/providers.dart';
import 'features/splash/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/alert/countdown_screen.dart';
import 'features/alert/dispatching_screen.dart';
import 'features/alert/confirmation_screen.dart';
import 'features/health/health_screen.dart';
import 'features/emergency/emergency_screen.dart';
import 'features/documents/documents_screen.dart';
import 'core/widgets/main_wrapper.dart';
import 'core/widgets/animations.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/countdown',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CountdownScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/dispatching',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DispatchingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/confirmation',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ConfirmationScreen(alertId: state.extra as String? ?? 'N/A'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => MainWrapper(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/health',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HealthProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/emergency',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const EmergencyScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/documents',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DocumentsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
    ),
  ],
);

class CrashGuardApp extends ConsumerWidget {
  const CrashGuardApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'CrashGuard',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ThemeRevealWrapper(child: child!);
      },
    );
  }
}

/// A wrapper that performs a circular reveal animation when the theme changes.
class ThemeRevealWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const ThemeRevealWrapper({super.key, required this.child});

  @override
  ConsumerState<ThemeRevealWrapper> createState() => _ThemeRevealWrapperState();
}

class _ThemeRevealWrapperState extends ConsumerState<ThemeRevealWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Widget? _bgChild;
  ThemeMode? _prevTheme;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final offset = ref.watch(themeSwitchOffsetProvider);

    // If theme changed and we have an offset, animate
    if (_prevTheme != null && _prevTheme != currentTheme && offset != null) {
      _bgChild = _bgChild ?? widget.child; // Keep previous child as background
      _controller.reset();
      _controller.forward().then((_) {
        setState(() {
          _bgChild = null; // Clean up background
          ref.read(themeSwitchOffsetProvider.notifier).state = null; // Clear offset
        });
      });
    }
    _prevTheme = currentTheme;

    return Stack(
      children: [
        if (_bgChild != null) _bgChild!,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_bgChild == null) return child!;
            return ClipPath(
              clipper: CircularRevealClipper(
                center: offset ?? Offset.zero,
                fraction: _controller.value,
              ),
              child: child,
            );
          },
          child: widget.child,
        ),
      ],
    );
  }
}
