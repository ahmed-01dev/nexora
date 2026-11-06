class NexoraEmailAuthValidation {
  const NexoraEmailAuthValidation._();

  static String? email(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)) {
      return 'اكتب بريدًا إلكترونيًا صحيحًا';
    }
    return null;
  }

  static String? password(String? value, {required bool registering}) {
    final password = value ?? '';
    if (password.isEmpty) return 'اكتب كلمة المرور';
    if (registering) {
      if (password.length < 12) return 'استخدم 12 حرفًا على الأقل';
      if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
          !RegExp(r'\d').hasMatch(password)) {
        return 'أضف حرفًا إنجليزيًا ورقمًا على الأقل';
      }
    } else if (password.length < 8) {
      return 'كلمة المرور غير صحيحة';
    }
    return null;
  }

  static String? displayName(String? value) {
    if ((value ?? '').trim().length < 2) {
      return 'اكتب اسمًا من حرفين على الأقل';
    }
    return null;
  }
}
