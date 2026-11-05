import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/features/settings/appearance_settings_screen.dart';

void main() {
  group('parseNexoraAccent', () {
    test('parses six-digit RGB values with or without a hash', () {
      expect(parseNexoraAccent('#7C5CFF')!.value, 0xFF7C5CFF);
      expect(parseNexoraAccent('3DD9FF')!.value, 0xFF3DD9FF);
    });

    test('rejects malformed or unsupported color strings', () {
      expect(parseNexoraAccent(null), isNull);
      expect(parseNexoraAccent(''), isNull);
      expect(parseNexoraAccent('#FFF'), isNull);
      expect(parseNexoraAccent('GGGGGG'), isNull);
      expect(parseNexoraAccent('#12345678'), isNull);
    });
  });

  test('serializes accent colors as uppercase RGB hex', () {
    expect(nexoraColorToHex(const Color(0xFF7C5CFF)), '#7C5CFF');
    expect(nexoraColorToHex(const Color(0xFF000000)), '#000000');
  });
}
