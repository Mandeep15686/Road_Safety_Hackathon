import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper that adds a subtle scale animation when pressed,
/// along with haptic feedback and a ripple effect.
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final bool enableHaptic;
  final BorderRadius? borderRadius;

  const BouncingWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
    this.enableHaptic = true,
    this.borderRadius,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: widget.onTap != null ? () {} : null, // Handled by Up/Down
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrapper that fades in and slides up its child when it appears.
class FadeInTranslate extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset offset;

  const FadeInTranslate({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 20),
  });

  @override
  State<FadeInTranslate> createState() => _FadeInTranslateState();
}

class _FadeInTranslateState extends State<FadeInTranslate> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeOut)),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A clipper for the circular reveal animation.
class CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double fraction;

  CircularRevealClipper({required this.center, required this.fraction});

  @override
  Path getClip(Size size) {
    // Calculate the maximum possible radius (to any corner)
    final double maxRadius = _calcMaxRadius(size, center);
    final double radius = maxRadius * fraction;

    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  double _calcMaxRadius(Size size, Offset center) {
    final double w = size.width;
    final double h = size.height;

    // Distances to corners
    final d1 = sqrt(pow(center.dx, 2) + pow(center.dy, 2));
    final d2 = sqrt(pow(w - center.dx, 2) + pow(center.dy, 2));
    final d3 = sqrt(pow(center.dx, 2) + pow(h - center.dy, 2));
    final d4 = sqrt(pow(w - center.dx, 2) + pow(h - center.dy, 2));

    return max(max(d1, d2), max(d3, d4));
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}
