/// Converts Egyptian mobile input or an international E.164 number to E.164.
/// Returns null for malformed or unsupported input.
String? normalizeNexoraPhone(String raw) {
  var value = raw.trim().replaceAll(RegExp(r'[\s()\-]'), '');
  if (value.startsWith('00')) value = '+${value.substring(2)}';
  if (value.startsWith('+')) {
    final digits = value.substring(1);
    if (!RegExp(r'^[1-9]\d{7,14}$').hasMatch(digits)) return null;
    return '+$digits';
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('01')) {
    return '+20${digits.substring(1)}';
  }
  if (digits.length == 10 && digits.startsWith('1')) {
    return '+20$digits';
  }
  if (digits.length == 12 && digits.startsWith('20')) {
    return '+$digits';
  }
  return null;
}
