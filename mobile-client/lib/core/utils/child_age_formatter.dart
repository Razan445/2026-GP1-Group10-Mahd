import 'dart:math' as math;

import 'arabic_number_formatter.dart';

/// Formats the child's chronological age from the saved date of birth.
/// Recompute from DateTime.now(); do not persist an age that will become stale.
/// Prematurity-adjusted age must not be inferred from birth date alone.
class ChildAgeFormatter {
  ChildAgeFormatter._();

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _monthAnniversary(DateTime birth, int months) {
    final firstOfMonth = DateTime(birth.year, birth.month + months, 1);
    final finalDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    return DateTime(
      firstOfMonth.year,
      firstOfMonth.month,
      math.min(birth.day, finalDay),
    );
  }

  /// Whole calendar months, recognizing a month-end birthday on its final day.
  /// Negative indicates that the stored birthday is in the future.
  static int completedMonths(DateTime dateOfBirth, DateTime now) {
    final birth = _dateOnly(dateOfBirth);
    final today = _dateOnly(now);
    if (birth.isAfter(today)) return -1;
    var result = (today.year - birth.year) * 12 + today.month - birth.month;
    if (_monthAnniversary(birth, result).isAfter(today)) result--;
    return result;
  }

  static String _years(int value) {
    if (value == 1) return 'سنة';
    if (value == 2) return 'سنتان';
    if (value >= 3 && value <= 10) {
      return '${ArabicNumberFormatter.formatInt(value)} سنوات';
    }
    return '${ArabicNumberFormatter.formatInt(value)} سنة';
  }

  static String _months(int value) {
    if (value == 1) return 'شهر';
    if (value == 2) return 'شهران';
    if (value >= 3 && value <= 10) {
      return '${ArabicNumberFormatter.formatInt(value)} أشهر';
    }
    return '${ArabicNumberFormatter.formatInt(value)} شهرًا';
  }

  static String _days(int value) {
    if (value == 1) return 'يوم';
    if (value == 2) return 'يومان';
    if (value >= 3 && value <= 10) {
      return '${ArabicNumberFormatter.formatInt(value)} أيام';
    }
    return '${ArabicNumberFormatter.formatInt(value)} يومًا';
  }

  /// Useful for research-stage headings; excludes remaining days on purpose.
  static String formatMonthsOnly(int totalMonths) {
    if (totalMonths < 0) return 'غير محدد';
    if (totalMonths == 0) return 'أقل من شهر';
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    final pieces = <String>[];
    if (years > 0) pieces.add(_years(years));
    if (months > 0) pieces.add(_months(months));
    return pieces.join(' و');
  }

  /// Exact completed calendar years, months, and days, e.g. سنة و٦ أشهر و٣ أيام.
  static String format(DateTime dateOfBirth, DateTime now) {
    final birth = _dateOnly(dateOfBirth);
    final today = _dateOnly(now);
    final wholeMonths = completedMonths(birth, today);
    if (wholeMonths < 0) return 'تاريخ الميلاد غير صالح';
    final anniversary = _monthAnniversary(birth, wholeMonths);
    final remainingDays = today.difference(anniversary).inDays;
    final years = wholeMonths ~/ 12;
    final months = wholeMonths % 12;
    final parts = <String>[];
    if (years > 0) parts.add(_years(years));
    if (months > 0) parts.add(_months(months));
    if (remainingDays > 0) parts.add(_days(remainingDays));
    if (parts.isEmpty) return 'يوم الولادة';
    if (parts.length == 1 && years == 1) return 'سنة واحدة';
    if (parts.length == 1 && months == 1) return 'شهر واحد';
    return parts.join(' و');
  }
}
