import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';


class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _visibleMonth = DateTime(2026, 10, 1);
  DateTime? _selectedDate = DateTime(2026, 10, 5);

  final List<_Appointment> _appointments = [
    _Appointment(
      title: 'موعد تطعيم',
      date: DateTime(2026, 10, 5),
      time: '10:30 ص',
      icon: Icons.vaccines_outlined,
    ),
    _Appointment(
      title: 'موعد متابعة',
      date: DateTime(2026, 10, 18),
      time: '4:00 م',
      icon: Icons.medical_services_outlined,
    ),
  ];

  static const List<String> _arabicMonths = [
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

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month - 1,
        1,
      );

      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + 1,
        1,
      );

      _selectedDate = null;
    });
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDate = DateTime(
        _visibleMonth.year,
        _visibleMonth.month,
        day,
      );
    });
  }

  bool _hasAppointment(int day) {
    return _appointments.any(
      (appointment) =>
          appointment.date.year == _visibleMonth.year &&
          appointment.date.month == _visibleMonth.month &&
          appointment.date.day == day,
    );
  }

  List<_Appointment> get _appointmentsForVisibleMonth {
    return _appointments
        .where(
          (appointment) =>
              appointment.date.year == _visibleMonth.year &&
              appointment.date.month == _visibleMonth.month,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CalendarHeader(),

                const SizedBox(height: 22),

                _MonthCard(
                  visibleMonth: _visibleMonth,
                  selectedDate: _selectedDate,
                  monthName:
                      _arabicMonths[_visibleMonth.month - 1],
                  hasAppointment: _hasAppointment,
                  onDaySelected: _selectDay,
                  onPreviousMonth: _previousMonth,
                  onNextMonth: _nextMonth,
                ),

                const SizedBox(height: 26),

                Text(
                  'المواعيد القادمة',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                if (_appointmentsForVisibleMonth.isEmpty)
                  const _NoAppointmentsCard()
                else
                  ..._appointmentsForVisibleMonth.map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AppointmentCard(
                        icon: appointment.icon,
                        title: appointment.title,
                        date: _formatDate(appointment.date),
                        time: appointment.time,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final monthName = _arabicMonths[date.month - 1];

    return '${date.day} $monthName ${date.year}';
  }
}

// ── Header ────────────────────────────────────────────────────────

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: AppColors.primary,
            ),
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
        ),

        const Spacer(),

        Text(
          'التقويم',
          style: AppTextStyles.cardTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
// ── Monthly calendar ──────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final String monthName;

  final bool Function(int day) hasAppointment;
  final ValueChanged<int> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _MonthCard({
    required this.visibleMonth,
    required this.selectedDate,
    required this.monthName,
    required this.hasAppointment,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    );

    final numberOfDays = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;

    final leadingEmptyCells = firstDay.weekday % 7;

    const weekDays = [
      'أحد',
      'اثن',
      'ثلا',
      'أرب',
      'خمي',
      'جمع',
      'سبت',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D785037),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MonthArrow(
                icon: Icons.chevron_right_rounded,
                onTap: onPreviousMonth,
              ),

              Text(
                '$monthName ${visibleMonth.year}',
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              _MonthArrow(
                icon: Icons.chevron_left_rounded,
                onTap: onNextMonth,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: weekDays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: AppTextStyles.featureDesc.copyWith(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyCells + numberOfDays,
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

              final isSelected =
                  selectedDate != null &&
                  selectedDate!.year == visibleMonth.year &&
                  selectedDate!.month == visibleMonth.month &&
                  selectedDate!.day == day;

              return _CalendarDay(
                day: day,
                isSelected: isSelected,
                hasEvent: hasAppointment(day),
                onTap: () => onDaySelected(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Month arrow ───────────────────────────────────────────────────

class _MonthArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthArrow({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 21,
        ),
      ),
    );
  }
}

// ── Calendar day ──────────────────────────────────────────────────

class _CalendarDay extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool hasEvent;
  final VoidCallback onTap;

  const _CalendarDay({
    required this.day,
    required this.isSelected,
    required this.hasEvent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: AppTextStyles.featureDesc.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),

            if (hasEvent)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Appointment data ──────────────────────────────────────────────

class _Appointment {
  final String title;
  final DateTime date;
  final String time;
  final IconData icon;

  const _Appointment({
    required this.title,
    required this.date,
    required this.time,
    required this.icon,
  });
}

// ── Appointment card ──────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String time;

  const _AppointmentCard({
    required this.icon,
    required this.title,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D785037),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$date • $time',
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty appointments state ──────────────────────────────────────

class _NoAppointmentsCard extends StatelessWidget {
  const _NoAppointmentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'لا توجد مواعيد في هذا الشهر',
            style: AppTextStyles.featureDesc.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}