import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/theme/nexora_theme.dart';

void main() {
  test('AMOLED is true black with white primary accent', () {
    final theme = NexoraTheme.amoled;
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(theme.colorScheme.primary, const Color(0xFFFFFFFF));
  });

  test('light and optional pink themes are available', () {
    expect(NexoraTheme.light.brightness, Brightness.light);
    expect(NexoraTheme.pinkAmoled.colorScheme.primary, NexoraColors.pink);
  });
}
