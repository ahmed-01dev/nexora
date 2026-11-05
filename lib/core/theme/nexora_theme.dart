import 'package:flutter/material.dart';

/// NEXORA — Aurora Glass visual language.
const supportedNexoraThemes = <String>{'amoled', 'light', 'pink_amoled'};
String normalizeNexoraTheme(String? value) =>
    supportedNexoraThemes.contains(value) ? value! : 'amoled';

abstract final class NexoraColors {
  static const black = Color(0xFF070B16);
  static const deep = Color(0xFF090F20);
  static const surface = Color(0xFF111B30);
  static const elevated = Color(0xFF17243D);
  static const raised = Color(0xFF203451);
  static const white = Color(0xFFF4F8FF);
  static const secondaryText = Color(0xFFA9B8D0);
  static const mutedText = Color(0xFF71839F);
  static const border = Color(0x33B7D9FF);
  static const silver = Color(0xFF9DDCFF);
  static const pink = Color(0xFFFF68C8);
  static const cyan = Color(0xFF62D8FF);
  static const violet = Color(0xFF8B7CFF);
}

abstract final class NexoraTheme {
  static ThemeData get amoled => _build(
    brightness: Brightness.dark,
    background: NexoraColors.black,
    surface: NexoraColors.surface,
    accent: NexoraColors.cyan,
    onAccent: const Color(0xFF071321),
  );
  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: const Color(0xFFF1F5FC),
    surface: const Color(0xFFE8EFF9),
    accent: const Color(0xFF087EA4),
    onAccent: Colors.white,
  );
  static ThemeData get pinkAmoled => _build(
    brightness: Brightness.dark,
    background: NexoraColors.black,
    surface: NexoraColors.surface,
    accent: NexoraColors.pink,
    onAccent: const Color(0xFF190B19),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color accent,
    required Color onAccent,
  }) {
    final dark = brightness == Brightness.dark;
    final border = dark ? NexoraColors.border : const Color(0xFFD5E0F0);
    final foreground = dark ? NexoraColors.white : const Color(0xFF101A2B);
    final muted = dark ? NexoraColors.secondaryText : const Color(0xFF66758C);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: dark ? NexoraColors.violet : const Color(0xFF6556C8),
      surface: surface,
      error: const Color(0xFFFF647C),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      splashColor: accent.withValues(alpha: .10),
      highlightColor: accent.withValues(alpha: .06),
      appBarTheme: AppBarTheme(
        backgroundColor: background.withValues(alpha: .72),
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: foreground, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
      cardTheme: CardThemeData(
        color: surface.withValues(alpha: dark ? .76 : .92),
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF14223A).withValues(alpha: .82) : Colors.white.withValues(alpha: .9),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide(color: accent, width: 1.7)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xE6101B30) : const Color(0xEFFFFFFF),
        indicatorColor: accent.withValues(alpha: .18),
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? accent : muted,
          size: 23,
        )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
          fontSize: 10,
          color: states.contains(WidgetState.selected) ? foreground : muted,
        )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(52, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: accent)),
      chipTheme: ChipThemeData(
        backgroundColor: surface.withValues(alpha: .78),
        selectedColor: accent.withValues(alpha: .2),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
      iconTheme: IconThemeData(color: muted),
      textTheme: Typography.material2021().white.apply(bodyColor: foreground, displayColor: foreground),
    );
  }
}
