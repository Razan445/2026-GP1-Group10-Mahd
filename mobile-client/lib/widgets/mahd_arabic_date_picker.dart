import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/arabic_number_formatter.dart';

// Shared Arabic Gregorian calendar picker reused by calendar and child screens.
const List<String> _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String _formatMahdDate(DateTime date) {
  return '${ArabicNumberFormatter.formatInt(date.day)} '
      '${_arabicMonths[date.month - 1]} '
      '${ArabicNumberFormatter.formatInt(date.year)}';
}

Future<DateTime?> showMahdArabicDatePicker({
  required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime selectedDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );

    DateTime visibleMonth = DateTime(
      initialDate.year,
      initialDate.month,
      1,
    );

    bool isSameDay(DateTime first, DateTime second) {
      return first.year == second.year &&
          first.month == second.month &&
          first.day == second.day;
    }

    bool isDisabled(DateTime date) {
      final normalized = DateTime(date.year, date.month, date.day);
      final minDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
      final maxDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
      return normalized.isBefore(minDate) || normalized.isAfter(maxDate);
    }

    return showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final now = DateTime.now();
              final firstDay = DateTime(
                visibleMonth.year,
                visibleMonth.month,
                1,
              );
              final daysInMonth = DateTime(
                visibleMonth.year,
                visibleMonth.month + 1,
                0,
              ).day;
              final leadingEmptyCells = firstDay.weekday % 7;
              final monthName = _arabicMonths[visibleMonth.month - 1];

              const weekDays = [
                'أحد',
                'اثن',
                'ثلا',
                'أرب',
                'خمي',
                'جمع',
                'سبت',
              ];

              final firstAllowedMonth = DateTime(
                firstDate.year,
                firstDate.month,
                1,
              );
              final lastAllowedMonth = DateTime(
                lastDate.year,
                lastDate.month,
                1,
              );
              final previousMonth = DateTime(
                visibleMonth.year,
                visibleMonth.month - 1,
                1,
              );
              final nextMonth = DateTime(
                visibleMonth.year,
                visibleMonth.month + 1,
                1,
              );
              final canGoPrevious = !previousMonth.isBefore(firstAllowedMonth);
              final canGoNext = !nextMonth.isAfter(lastAllowedMonth);

              return Dialog(
                backgroundColor: AppColors.cardSurface,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'اختيار التاريخ',
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'إغلاق',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary,
                                size: 21,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCream,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _formatMahdDate(selectedDate),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.screenTitle.copyWith(
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'الشهر السابق',
                              onPressed: canGoPrevious
                                  ? () {
                                      setDialogState(() {
                                        visibleMonth = previousMonth;
                                      });
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '$monthName ${ArabicNumberFormatter.formatInt(visibleMonth.year)}',
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              tooltip: 'الشهر التالي',
                              onPressed: canGoNext
                                  ? () {
                                      setDialogState(() {
                                        visibleMonth = nextMonth;
                                      });
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: weekDays
                              .map(
                                (day) => Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: AppTextStyles.featureDesc.copyWith(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: leadingEmptyCells + daysInMonth,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                          itemBuilder: (context, index) {
                            if (index < leadingEmptyCells) {
                              return const SizedBox.shrink();
                            }

                            final day = index - leadingEmptyCells + 1;
                            final date = DateTime(
                              visibleMonth.year,
                              visibleMonth.month,
                              day,
                            );
                            final disabled = isDisabled(date);
                            final selected = isSameDay(date, selectedDate);
                            final today = isSameDay(date, now);

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: disabled
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        selectedDate = date;
                                      });
                                    },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : (today
                                          ? AppColors.iconBg
                                          : Colors.transparent),
                                  borderRadius: BorderRadius.circular(12),
                                  border: today && !selected
                                      ? Border.all(
                                          color: AppColors.primary,
                                          width: 1.2,
                                        )
                                      : null,
                                ),
                                child: Text(
                                  ArabicNumberFormatter.formatInt(day),
                                  style: AppTextStyles.featureDesc.copyWith(
                                    fontSize: 12,
                                    fontWeight: selected || today
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: disabled
                                        ? AppColors.textSecondary.withValues(
                                            alpha: 0.35,
                                          )
                                        : selected
                                            ? Colors.white
                                            : today
                                                ? AppColors.primaryDark
                                                : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(
                                    color: AppColors.borderBeige,
                                  ),
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'إلغاء',
                                  style: AppTextStyles.buttonTextDark.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(selectedDate);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'تأكيد',
                                  style: AppTextStyles.buttonText.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
