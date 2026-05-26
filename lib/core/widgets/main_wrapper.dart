import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainWrapper extends StatefulWidget {
  final Widget child;
  const MainWrapper({super.key, required this.child});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/nearby')) {
      return 1;
    }
    if (location.startsWith('/sos')) {
      return 2;
    }
    if (location.startsWith('/firstaid')) {
      return 3;
    }
    // Emergency / Documents / Health all fall under "More" tab
    if (location.startsWith('/emergency') ||
        location.startsWith('/documents') ||
        location.startsWith('/health')) {
      return 4;
    }
    return 0;
  }

  void _onPageChanged(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/nearby');
        break;
      case 2:
        context.go('/sos');
        break;
      case 3:
        context.go('/firstaid');
        break;
      case 4:
        context.go('/emergency');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: widget.child,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_rounded),
            label:        'Home',
          ),
          NavigationDestination(
            icon:         Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place_rounded),
            label:        'Nearby',
          ),
          NavigationDestination(
            icon:         Icon(Icons.emergency_share_outlined),
            selectedIcon: Icon(Icons.emergency_share_rounded),
            label:        'SOS',
          ),
          NavigationDestination(
            icon:         Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services_rounded),
            label:        'First Aid',
          ),
          NavigationDestination(
            icon:         Icon(Icons.menu_rounded),
            selectedIcon: Icon(Icons.menu_rounded),
            label:        'More',
          ),
        ],
        onDestinationSelected: (i) => _onPageChanged(i, context),
      ),
    );
  }
}
