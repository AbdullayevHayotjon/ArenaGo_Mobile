import 'dart:math' as math;

import 'package:flutter/material.dart';

class FloatingFootball extends StatefulWidget {
  const FloatingFootball({
    super.key,
    this.size = 84,
    this.padding = 14,
    this.backgroundColor = const Color(0x1AFFFFFF),
    this.shadowColor = const Color(0x4474EDB5),
    this.shadowBlurRadius = 35,
  });

  final double size;
  final double padding;
  final Color backgroundColor;
  final Color shadowColor;
  final double shadowBlurRadius;

  @override
  State<FloatingFootball> createState() => _FloatingFootballState();
}

class _FloatingFootballState extends State<FloatingFootball>
    with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  List<AnimationController> get _controllers => [_float, _spin];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final controller in _controllers) {
      if (MediaQuery.of(context).disableAnimations) {
        controller
          ..stop()
          ..value = 0;
      } else if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(_controllers),
      builder: (context, child) {
        final floatPhase = math.sin(math.pi * _float.value);
        return Transform.translate(
          offset: Offset(0, -9 * floatPhase),
          child: Transform.scale(
            scale: 1 + (.04 * floatPhase),
            child: Transform.rotate(
              angle: _spin.value * (350 / 360) * math.pi * 2,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(widget.padding),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              blurRadius: widget.shadowBlurRadius,
            ),
          ],
        ),
        child: Image.asset('assets/images/logo.png'),
      ),
    );
  }
}
