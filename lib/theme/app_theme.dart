import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF22A96F);
  static const primaryDark = Color(0xFF16885B);
  static const background = Color(0xFFF4F7F5);
  static const darkBackground = Color(0xFF0D1512);
  static const darkSurface = Color(0xFF141E1A);
  static const danger = Color(0xFFE45151);
}

class AppTheme {
  static ThemeData get light => _theme(
    brightness: Brightness.light,
    background: AppColors.background,
    surface: Colors.white,
    text: const Color(0xFF17231E),
    border: const Color(0xFFE4E9E6),
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    text: const Color(0xFFEEF5F1),
    border: const Color(0xFF304139),
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color border,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
          surface: surface,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          error: AppColors.danger,
          surface: surface,
          onSurface: text,
        );
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: border),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Arial',
      textTheme: ThemeData(brightness: brightness).textTheme
          .apply(bodyColor: text, displayColor: text, fontFamily: 'Arial'),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF8FAF9)
            : const Color(0xFF17231E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: outline,
        border: outline,
        focusedBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
