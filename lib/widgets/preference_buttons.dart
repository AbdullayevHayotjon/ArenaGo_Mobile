import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';

class PreferenceButtons extends StatelessWidget {
  const PreferenceButtons({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PreferenceButton(
          tooltip: controller.strings.t('theme'),
          onTap: controller.toggleTheme,
          child: Icon(
            controller.themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        _PreferenceButton(
          tooltip: controller.strings.t('language'),
          onTap: controller.toggleLanguage,
          child: Text(
            controller.language.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _PreferenceButton extends StatelessWidget {
  const _PreferenceButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: .45),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 42, height: 42, child: Center(child: child)),
        ),
      ),
    );
  }
}
