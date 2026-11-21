class ArabicNumberFormatter {
  ArabicNumberFormatter._();

  static const Map<String, String> _arabicDigits = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  /// Converts Western digits (0-9) to Arabic digits (٠-٩).
  ///
  /// Example:
  ///  "24°م"       -> "٢٤°م"
  ///  "45%"        -> "٤٥%"
  ///  "07/11/2026" -> "٠٧/١١/٢٠٢٦"
  static String toArabic(String value) {
    var result = value;

    _arabicDigits.forEach((western, arabic) {
      result = result.replaceAll(western, arabic);
    });

    return result;
  }

  /// Converts Western digits to Arabic digits and replaces
  /// the Western percent sign with the Arabic percent sign.
  ///
  /// Example:
  ///  "45%" -> "٤٥٪"
  static String toArabicPercentage(String value) {
    return toArabic(value).replaceAll('%', '٪');
  }

  /// Formats an integer using Arabic digits.
  ///
  /// Example:
  ///  18 -> "١٨"
  static String formatInt(int value) {
    return toArabic(value.toString());
  }

  /// Formats a decimal number using Arabic digits.
  ///
  /// Example:
  ///  5.8 -> "٥.٨"
  static String formatDouble(
    double value, {
    int? fractionDigits,
  }) {
    final text = fractionDigits == null
        ? value.toString()
        : value.toStringAsFixed(fractionDigits);

    return toArabic(text);
  }

  /// Formats a DateTime as DD/MM/YYYY using Arabic digits.
  ///
  /// Example:
  ///  07/11/2026 -> ٠٧/١١/٢٠٢٦
  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return toArabic('$day/$month/$year');
  }

  /// Formats a duration as MM:SS using Arabic digits.
  ///
  /// Example:
  ///  05:23 -> ٠٥:٢٣
  static String formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return toArabic('$minutes:$seconds');
  }

  /// Formats a time from DateTime using Arabic digits.
  ///
  /// Example:
  ///  10:42 ص -> ١٠:٤٢ ص
  static String formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'م' : 'ص';

    return toArabic('$hour:$minute $period');
  }
}
