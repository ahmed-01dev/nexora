/// Converts Egyptian mobile input or an international E.164 number to E.164.
/// Returns null for malformed or unsupported input.
String? normalizeNexoraPhone(String raw) {
  var value = raw.trim().replaceAllMapped(
    RegExp(r'[٠-٩۰-۹]'),
    (match) {
      final codePoint = match.group(0)!.runes.single;
      final digit = codePoint >= 0x0660 && codePoint <= 0x0669
          ? codePoint - 0x0660
          : codePoint - 0x06F0;
      return String.fromCharCode(0x30 + digit);
    },
  );

  // Permit common visual separators, but never silently strip letters or
  // misplaced symbols from a phone number.
  value = value.replaceAll(RegExp(r'[\s().-]'), '');
  if (value.startsWith('00')) value = '+${value.substring(2)}';

  if (value.startsWith('+')) {
    final digits = value.substring(1);
    if (!RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(digits)) return null;
    return '+$digits';
  }

  if (!RegExp(r'^[0-9]+$').hasMatch(value)) return null;
  if (value.length == 11 && value.startsWith('01')) {
    return '+20${value.substring(1)}';
  }
  if (value.length == 10 && value.startsWith('1')) {
    return '+20$value';
  }
  if (value.length == 12 && value.startsWith('20')) {
    return '+$value';
  }
  return null;
}
/// Normalizes a six-digit OTP entered with Arabic, Persian, or ASCII digits.
String? normalizeNexoraOtp(String raw) {
  final value = raw.trim().replaceAllMapped(
    RegExp(r'[٠-٩۰-۹]'),
    (match) {
      final codePoint = match.group(0)!.runes.single;
      final digit = codePoint >= 0x0660 && codePoint <= 0x0669
          ? codePoint - 0x0660
          : codePoint - 0x06F0;
      return String.fromCharCode(0x30 + digit);
    },
  );
  return RegExp(r'^\d{6}$').hasMatch(value) ? value : null;
}
