import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ArenaLogo extends StatelessWidget {
  const ArenaLogo({
    super.key,
    this.light = false,
    this.size = 42,
    this.animate = false,
  });

  final bool light;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        animate
            ? _GentleRotatingMark(size: size)
            : Image.asset('assets/images/logo.png', width: size, height: size),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            text: 'Arena',
            children: const [
              TextSpan(
                text: 'Go',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          style: TextStyle(
            color: light
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontSize: size * .55,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _GentleRotatingMark extends StatefulWidget {
  const _GentleRotatingMark({required this.size});

  final double size;

  @override
  State<_GentleRotatingMark> createState() => _GentleRotatingMarkState();
}

class _GentleRotatingMarkState extends State<_GentleRotatingMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _rotation
        ..stop()
        ..value = 0;
    } else if (!_rotation.isAnimating) {
      _rotation.repeat();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotation,
      child: Image.asset(
        'assets/images/logo.png',
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
