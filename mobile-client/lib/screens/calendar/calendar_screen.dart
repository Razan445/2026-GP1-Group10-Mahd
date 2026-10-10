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
      time: const TimeOfDay(hour: 10, minute: 30),
      icon: Icons.vaccines_outlined,
    ),
    _Appointment(
      title: 'موعد متابعة',
      date: DateTime(2026, 10, 18),
      time: const TimeOfDay(hour: 16, minute: 0),
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
      ..sort((a, b) {
        final dateComparison = a.date.compareTo(b.date);

        if (dateComparison != 0) {
          return dateComparison;
        }

        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;

        return aMinutes.compareTo(bMinutes);
      });
  }

  Future<void> _showAppointmentDialog({
    _Appointment? appointment,
  }) async {
    final titleController = TextEditingController(
      text: appointment?.title ?? '',
    );

    DateTime selectedDate =
        appointment?.date ??
        _selectedDate ??
        DateTime(
          _visibleMonth.year,
          _visibleMonth.month,
          1,
        );

    TimeOfDay selectedTime =
        appointment?.time ?? TimeOfDay.now();

    bool showTitleError = false;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: AppColors.cardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  appointment == null
                      ? 'إضافة موعد'
                      : 'تعديل الموعد',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: 'اسم الموعد',
                          hintText: 'مثال: موعد تطعيم',
                          errorText: showTitleError
                              ? 'اكتبي اسم الموعد'
                              : null,
                          filled: true,
                          fillColor: AppColors.backgroundCream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (showTitleError) {
                            setDialogState(() {
                              showTitleError = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _DialogPickerTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'التاريخ',
                        value: _formatDate(selectedDate),
                        onTap: () async {
                          final pickedDate =
                              await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );

                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _DialogPickerTile(
                        icon: Icons.access_time_rounded,
                        label: 'الوقت',
                        value: _formatTime(selectedTime),
                        onTap: () async {
                          final pickedTime =
                              await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );

                          if (pickedTime != null) {
                            setDialogState(() {
                              selectedTime = pickedTime;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: Text(
                      'إلغاء',
                      style: AppTextStyles.featureDesc.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) {
                        setDialogState(() {
                          showTitleError = true;
                        });

                        return;
                      }

                      Navigator.of(dialogContext).pop(true);
                    },
                    child: Text(
                      appointment == null ? 'إضافة' : 'حفظ',
                      style: AppTextStyles.featureDesc.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (shouldSave != true || !mounted) {
      titleController.dispose();
      return;
    }

    final updatedAppointment = _Appointment(
      title: titleController.text.trim(),
      date: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      ),
      time: selectedTime,
      icon:
          appointment?.icon ??
          Icons.event_note_outlined,
    );

    setState(() {
      if (appointment == null) {
        _appointments.add(updatedAppointment);
      } else {
        final appointmentIndex =
            _appointments.indexOf(appointment);

        if (appointmentIndex != -1) {
          _appointments[appointmentIndex] =
              updatedAppointment;
        }
      }

      _visibleMonth = DateTime(
        selectedDate.year,
        selectedDate.month,
        1,
      );

      _selectedDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });

    titleController.dispose();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appointment == null
              ? 'تمت إضافة الموعد'
              : 'تم تعديل الموعد',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Future<void> _deleteAppointment(
    _Appointment appointment,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'حذف الموعد',
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'هل أنت متأكدة من حذف "${appointment.title}"؟',
              style: AppTextStyles.featureDesc.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: Text(
                  'إلغاء',
                  style: AppTextStyles.featureDesc.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: Text(
                  'حذف',
                  style: AppTextStyles.featureDesc.copyWith(
                    color: AppColors.alert,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _appointments.remove(appointment);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حذف الموعد',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final monthName = _arabicMonths[date.month - 1];

    return '${date.day} $monthName ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final period = time.hour < 12 ? 'ص' : 'م';

    int hour = time.hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute $period';
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

                Row(
                  children: [
                    Text(
                      'المواعيد القادمة',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        _showAppointmentDialog();
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'إضافة',
                        style: AppTextStyles.featureDesc.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (_appointmentsForVisibleMonth.isEmpty)
                  const _NoAppointmentsCard()
                else
                  ..._appointmentsForVisibleMonth.map(
                    (appointment) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: _AppointmentCard(
                        icon: appointment.icon,
                        title: appointment.title,
                        date: _formatDate(appointment.date),
                        time: _formatTime(appointment.time),
                        onEdit: () {
                          _showAppointmentDialog(
                            appointment: appointment,
                          );
                        },
                        onDelete: () {
                          _deleteAppointment(appointment);
                        },
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
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
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
                        style:
                            AppTextStyles.featureDesc.copyWith(
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
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount:
                leadingEmptyCells + numberOfDays,
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

              final day =
                  index - leadingEmptyCells + 1;

              final isSelected =
                  selectedDate != null &&
                  selectedDate!.year ==
                      visibleMonth.year &&
                  selectedDate!.month ==
                      visibleMonth.month &&
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
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
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
  final TimeOfDay time;
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AppointmentCard({
    required this.icon,
    required this.title,
    required this.date,
    required this.time,
    required this.onEdit,
    required this.onDelete,
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                  style:
                      AppTextStyles.featureDesc.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            tooltip: '',
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            color: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'تعديل',
                      style:
                          AppTextStyles.featureDesc.copyWith(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: AppColors.alert,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'حذف',
                      style:
                          AppTextStyles.featureDesc.copyWith(
                        fontSize: 12,
                        color: AppColors.alert,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Appointment dialog picker ─────────────────────────────────────

class _DialogPickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DialogPickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundCream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 19,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        AppTextStyles.featureDesc.copyWith(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style:
                        AppTextStyles.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
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