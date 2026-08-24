import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FieldSearchBar extends StatelessWidget {
  const FieldSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: dark ? .52 : .62),
      ),
    );

    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .12 : .045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: .72),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: scheme.surface,
          contentPadding: EdgeInsets.zero,
          prefixIconConstraints: const BoxConstraints.tightFor(
            width: 50,
            height: 52,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.primaryDark,
              size: 19,
            ),
          ),
          suffixIconConstraints: const BoxConstraints.tightFor(
            width: 46,
            height: 52,
          ),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: controller.text.isEmpty
                  ? const SizedBox(key: ValueKey('empty'))
                  : IconButton(
                      key: const ValueKey('clear'),
                      onPressed: onClear,
                      tooltip: clearTooltip,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
            ),
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
