import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/theme/nexora_theme.dart';

void main() {
  test('AMOLED uses true black and Aurora violet accent', () {
    final theme = NexoraTheme.amoled;
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, NexoraColors.bg);
    expect(theme.colorScheme.primary, NexoraColors.violet);
    expect(theme.colorScheme.surface, NexoraColors.surface);
  });

  test('light and pink AMOLED themes use the design tokens', () {
    expect(NexoraTheme.light.brightness, Brightness.light);
    expect(NexoraTheme.light.scaffoldBackgroundColor, const Color(0xFFF4F4F8));
    expect(NexoraTheme.pinkAmoled.colorScheme.primary, NexoraColors.pink);
    expect(NexoraTheme.pinkAmoled.scaffoldBackgroundColor, NexoraColors.bg);
  });

  test('surface hierarchy and spacing tokens stay distinct', () {
    expect(NexoraColors.surface, const Color(0xFF0B0B10));
    expect(NexoraColors.surfaceRaised, const Color(0xFF14141C));
    expect(NexoraColors.hairline, const Color(0x1AFFFFFF));
    expect(NexoraSpacing.screen, 16);
    expect(NexoraRadius.sheet, 28);
  });

  test('motion tokens keep the shared Aurora timing scale', () {
    expect(NexoraMotion.fast, const Duration(milliseconds: 160));
    expect(NexoraMotion.standard, const Duration(milliseconds: 240));
    expect(NexoraMotion.emphasized, const Duration(milliseconds: 320));
  });

  group('normalizeNexoraTheme', () {
    test('keeps all supported theme values', () {
      for (final value in ['amoled', 'light', 'pink_amoled', 'custom']) {
        expect(normalizeNexoraTheme(value), value);
      }
    });
    test('falls back safely for null or unknown values', () {
      expect(normalizeNexoraTheme(null), 'amoled');
      expect(normalizeNexoraTheme('neon'), 'amoled');
      expect(normalizeNexoraTheme(''), 'amoled');
    });
  });
}
