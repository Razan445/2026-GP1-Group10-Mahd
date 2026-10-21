/// Shared form validators for the Mahd app.
class Validators {
  Validators._();

  static final RegExp _arabicNameRegex =
      RegExp(r'^[\u0621-\u064A\u064B-\u0652\u0640]+(\s+[\u0621-\u064A\u064B-\u0652\u0640]+)*$');

  /// Full name: Arabic letters and spaces only (English names are not
  /// supported because the app is Arabic-only).
  static String? arabicFullName(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) {
      return 'الاسم مطلوب';
    }

    if (v.length < 2) {
      return 'الاسم قصير جدًا';
    }

    if (v.length > 50) {
      return 'الاسم يجب ألا يتجاوز ٥٠ حرفًا';
    }

    if (!_arabicNameRegex.hasMatch(v)) {
      return 'يرجى كتابة الاسم باللغة العربية فقط';
    }

    return null;
  }

  /// Password: at least 8 characters including an uppercase letter,
  /// a lowercase letter, a number and a special character.
  static String? password(String? value) {
    final v = value ?? '';

    if (v.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }

    if (v.length < 8) {
      return 'كلمة المرور يجب أن تكون ٨ أحرف على الأقل';
    }

    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'يجب أن تحتوي على حرف إنجليزي كبير واحد على الأقل';
    }

    if (!RegExp(r'[a-z]').hasMatch(v)) {
      return 'يجب أن تحتوي على حرف إنجليزي صغير واحد على الأقل';
    }

    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return 'يجب أن تحتوي على رقم واحد على الأقل';
    }

    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
      return 'يجب أن تحتوي على رمز خاص واحد على الأقل (مثل ! @ #)';
    }

    return null;
  }
}
