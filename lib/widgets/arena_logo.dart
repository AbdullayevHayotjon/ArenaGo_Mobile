import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ArenaLogo extends StatelessWidget {
  const ArenaLogo({super.key, this.light = false, this.size = 42});
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', width: size, height: size),
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
