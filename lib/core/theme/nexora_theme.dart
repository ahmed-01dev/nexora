import 'package:flutter/material.dart';

/// NEXORA visual system. AMOLED is the default; alternatives are opt-in.
const supportedNexoraThemes = <String>{'amoled', 'light', 'pink_amoled'};

String normalizeNexoraTheme(String? value) =>
    supportedNexoraThemes.contains(value) ? value! : 'amoled';

abstract final class NexoraColors {
  static const black = Color(0xFF000000);
  static const deep = Color(0xFF050505);
  static const surface = Color(0xFF101010);
  static const elevated = Color(0xFF171717);
  static const raised = Color(0xFF202020);
  static const white = Color(0xFFFFFFFF);
  static const secondaryText = Color(0xFFA1A1AA);
  static const mutedText = Color(0xFF71717A);
  static const border = Color(0xFF292929);
  static const silver = Color(0xFFC0C0C0);
  static const pink = Color(0xFFFF4FA3);
}

abstract final class NexoraTheme {
  static ThemeData get amoled => _build(
        brightness: Brightness.dark,
        background: NexoraColors.black,
        surface: NexoraColors.surface,
        accent: NexoraColors.white,
        onAccent: NexoraColors.black,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: const Color(0xFFF7F7F8),
        surface: NexoraColors.white,
        accent: const Color(0xFF111111),
        onAccent: NexoraColors.white,
      );

  static ThemeData get pinkAmoled => _build(
        brightness: Brightness.dark,
        background: NexoraColors.black,
        surface: NexoraColors.surface,
        accent: NexoraColors.pink,
        onAccent: NexoraColors.black,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color accent,
    required Color onAccent,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: dark ? NexoraColors.silver : const Color(0xFF555555),
      surface: surface,
      error: const Color(0xFFFF5B65),
    );
    final border = dark ? NexoraColors.border : const Color(0xFFE5E5E7);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: dark ? NexoraColors.white : const Color(0xFF111111),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: dark ? NexoraColors.mutedText : const Color(0xFF777777)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? NexoraColors.deep : NexoraColors.white,
        indicatorColor: dark ? NexoraColors.raised : const Color(0xFFEAEAEA),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          fontSize: 11,
          color: dark ? NexoraColors.white : const Color(0xFF111111),
        )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
    );
  }
}
