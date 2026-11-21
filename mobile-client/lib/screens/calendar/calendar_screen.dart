import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_number_formatter.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_snack_bar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDate;

  /// Filter for appointment status: 'all', 'upcoming', 'completed'
  String _statusFilter = 'all';

  final List<_Appointment> _appointments = [];

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _remindersSubscription;

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _selectedDate = null;
    _listenToAuthentication();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _remindersSubscription?.cancel();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════
  // Firebase listeners
  // ═════════════════════════════════════════════════════════════

  void _listenToAuthentication() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        _remindersSubscription?.cancel();

        if (user == null) {
          if (!mounted) {
            return;
          }

          setState(() {
            _appointments.clear();
          });

          return;
        }

        _listenToReminders();
      },
    );
  }

  void _listenToReminders() {
    _remindersSubscription =
        FirestoreService.instance.watchReminders().listen(
      (snapshot) {
        final loadedAppointments = <_Appointment>[];

        for (final document in snapshot.docs) {
          final data = document.data();

          final dateTimeValue = data['dateTime'];

          if (dateTimeValue is! Timestamp) {
            continue;
          }

          final dateTime = dateTimeValue.toDate();

          final type = (data['type'] as String?) ?? 'other';

          final description =
              (data['description'] as String?)?.trim() ?? '';

          loadedAppointments.add(
            _Appointment(
              reminderId: document.id,
              title: (data['title'] as String?) ?? '',
              description: description,
              type: type,
              status: (data['status'] as String?) ?? 'active',
              date: DateTime(
                dateTime.year,
                dateTime.month,
                dateTime.day,
              ),
              time: TimeOfDay(
                hour: dateTime.hour,
                minute: dateTime.minute,
              ),
            ),
          );
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _appointments
            ..clear()
            ..addAll(loadedAppointments);
        });
      },
      onError: (Object error) {
        debugPrint('Error loading reminders: $error');
      },
    );
  }

  // ═════════════════════════════════════════════════════════════
  // Reminder types & visual styling
  // ═════════════════════════════════════════════════════════════

  bool _isBuiltInType(String type) {
    return type == 'vaccination' ||
        type == 'medical' ||
        type == 'care' ||
        type == 'other';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'vaccination':
        return 'تطعيم';
      case 'medical':
        return 'موعد طبي';
      case 'care':
        return 'رعاية';
      case 'other':
        return 'أخرى';
      default:
        final trimmed = type.trim();
        return trimmed.isEmpty ? 'أخرى' : trimmed;
    }
  }

  Color _accentColorForType(String type) {
    switch (type) {
      case 'vaccination':
        return AppColors.primary;
      case 'medical':
        return const Color(0xFF5B8FB9);
      case 'care':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _bgColorForType(String type) {
    switch (type) {
      case 'vaccination':
        return AppColors.iconBg;
      case 'medical':
        return const Color(0xFFEDF4F9);
      case 'care':
        return AppColors.successBg;
      default:
        return AppColors.backgroundBeige;
    }
  }

  bool _isCompleted(_Appointment appointment) {
    final normalized = appointment.status.toLowerCase().trim();
    return normalized == 'completed' || normalized == 'مكتمل';
  }

  String _relativeDateBadge(_Appointment appointment) {
    if (_isCompleted(appointment)) {
      return 'مكتمل ✓';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final target = DateTime(
      appointment.date.year,
      appointment.date.month,
      appointment.date.day,
    );

    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) {
      return 'اليوم';
    } else if (diffDays == 1) {
      return 'غدًا';
    } else if (diffDays == 2) {
      return 'بعد يومين';
    } else if (diffDays > 2 && diffDays <= 10) {
      return 'بعد ${ArabicNumberFormatter.formatInt(diffDays)} أيام';
    } else if (diffDays > 10) {
      return 'بعد ${ArabicNumberFormatter.formatInt(diffDays)} يومًا';
    } else if (diffDays == -1) {
      return 'أمس';
    } else {
      return 'فائت';
    }
  }

  // ═════════════════════════════════════════════════════════════
  // Calendar navigation & filtering
  // ═════════════════════════════════════════════════════════════

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

  void _jumpToToday() {
    final now = DateTime.now();

    setState(() {
      _visibleMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(
        now.year,
        now.month,
        now.day,
      );
    });
  }

  void _selectDay(int day) {
    final tappedDate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      day,
    );

    setState(() {
      if (_selectedDate != null &&
          _selectedDate!.year == tappedDate.year &&
          _selectedDate!.month == tappedDate.month &&
          _selectedDate!.day == tappedDate.day) {
        _selectedDate = null;
      } else {
        _selectedDate = tappedDate;
      }
    });
  }

  int _appointmentCountForDay(int day) {
    return _appointments
        .where(
          (appointment) =>
              appointment.date.year == _visibleMonth.year &&
              appointment.date.month == _visibleMonth.month &&
              appointment.date.day == day,
        )
        .length;
  }

  List<_Appointment> get _filteredAppointments {
    return _appointments.where((appointment) {
      final matchesMonth =
          appointment.date.year == _visibleMonth.year &&
              appointment.date.month == _visibleMonth.month;

      if (!matchesMonth) {
        return false;
      }

      if (_selectedDate != null &&
          appointment.date.day != _selectedDate!.day) {
        return false;
      }

      if (_statusFilter == 'upcoming' &&
          _isCompleted(appointment)) {
        return false;
      }

      if (_statusFilter == 'completed' &&
          !_isCompleted(appointment)) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final aDone = _isCompleted(a);
        final bDone = _isCompleted(b);

        if (aDone != bDone) {
          return aDone ? 1 : -1;
        }

        final dateComparison = a.date.compareTo(b.date);

        if (dateComparison != 0) {
          return dateComparison;
        }

        final aMinutes =
            a.time.hour * 60 + a.time.minute;

        final bMinutes =
            b.time.hour * 60 + b.time.minute;

        return aMinutes.compareTo(bMinutes);
      });
  }

  // ═════════════════════════════════════════════════════════════
  // Toggle completion status
  // ═════════════════════════════════════════════════════════════

  Future<void> _toggleAppointmentStatus(
    _Appointment appointment,
  ) async {
    final newStatus =
        _isCompleted(appointment)
            ? 'active'
            : 'completed';

    try {
      await FirestoreService.instance.updateReminder(
        reminderId: appointment.reminderId,
        title: appointment.title,
        description:
            appointment.description.isEmpty
                ? null
                : appointment.description,
        dateTime: DateTime(
          appointment.date.year,
          appointment.date.month,
          appointment.date.day,
          appointment.time.hour,
          appointment.time.minute,
        ),
        type: appointment.type,
        status: newStatus,
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        newStatus == 'completed'
            ? 'تم تحديد "${appointment.title}" كمكتمل ✓'
            : 'تمت إعادة "${appointment.title}" إلى المواعيد القادمة',
        type: newStatus == 'completed'
            ? AppSnackBarType.success
            : AppSnackBarType.info,
      );
    } catch (e) {
      debugPrint(
        'Error toggling reminder status: $e',
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        'تعذر تحديث حالة الموعد',
        type: AppSnackBarType.error,
      );
    }
  }

  // ═════════════════════════════════════════════════════════════
  // Add / edit reminder
  // ═════════════════════════════════════════════════════════════

  Future<void> _showAppointmentDialog({
    _Appointment? appointment,
  }) async {
    final titleController = TextEditingController(
      text: appointment?.title ?? '',
    );

    final descriptionController =
        TextEditingController(
      text: appointment?.description ?? '',
    );

    final storedType =
        appointment?.type ?? 'vaccination';

    final customTypeController =
        TextEditingController(
      text: _isBuiltInType(storedType)
          ? ''
          : storedType,
    );

    final now = DateTime.now();

    DateTime selectedDate =
        appointment?.date ??
            _selectedDate ??
            DateTime(
              _visibleMonth.year,
              _visibleMonth.month,
              _visibleMonth.year ==
                          now.year &&
                      _visibleMonth.month ==
                          now.month
                  ? now.day
                  : 1,
            );

    TimeOfDay selectedTime =
        appointment?.time ??
            const TimeOfDay(
              hour: 9,
              minute: 0,
            );

    String selectedType =
        _isBuiltInType(storedType)
            ? storedType
            : 'other';

    bool showTitleError = false;

    final shouldSave =
        await showDialog<bool>(
      context: context,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.28,
      ),
      builder: (dialogContext) {
        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              return AlertDialog(
                backgroundColor:
                    AppColors.cardSurface,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                ),
                titlePadding:
                    const EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  0,
                ),
                contentPadding:
                    const EdgeInsets.fromLTRB(
                  22,
                  14,
                  22,
                  0,
                ),
                actionsPadding:
                    const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  18,
                ),
                title: Center(
                  child: Text(
                    appointment == null
                        ? 'إضافة موعد جديد'
                        : 'تعديل الموعد',
                    style: AppTextStyles
                        .screenTitle
                        .copyWith(
                      fontSize: 18,
                    ),
                  ),
                ),
                content: SizedBox(
                  width: 370,
                  child:
                      SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'نوع الموعد',
                          style: AppTextStyles
                              .featureDesc
                              .copyWith(
                            fontSize: 11.5,
                            fontWeight:
                                FontWeight.w600,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _TypeChipOption(
                              label: 'تطعيم',
                              value:
                                  'vaccination',
                              icon: Icons
                                  .vaccines_outlined,
                              selectedValue:
                                  selectedType,
                              onSelected:
                                  (val) {
                                setDialogState(
                                  () {
                                    selectedType =
                                        val;
                                  },
                                );
                              },
                            ),
                            _TypeChipOption(
                              label:
                                  'موعد طبي',
                              value: 'medical',
                              icon: Icons
                                  .medical_services_outlined,
                              selectedValue:
                                  selectedType,
                              onSelected:
                                  (val) {
                                setDialogState(
                                  () {
                                    selectedType =
                                        val;
                                  },
                                );
                              },
                            ),
                            _TypeChipOption(
                              label: 'رعاية',
                              value: 'care',
                              icon: Icons
                                  .child_care_rounded,
                              selectedValue:
                                  selectedType,
                              onSelected:
                                  (val) {
                                setDialogState(
                                  () {
                                    selectedType =
                                        val;
                                  },
                                );
                              },
                            ),
                            _TypeChipOption(
                              label: 'أخرى',
                              value: 'other',
                              icon: Icons
                                  .event_note_outlined,
                              selectedValue:
                                  selectedType,
                              onSelected:
                                  (val) {
                                setDialogState(
                                  () {
                                    selectedType =
                                        val;
                                  },
                                );
                              },
                            ),
                          ],
                        ),

                        if (selectedType ==
                            'other') ...[
                          const SizedBox(
                            height: 12,
                          ),
                          TextField(
                            controller:
                                customTypeController,
                            textDirection:
                                TextDirection.rtl,
                            decoration:
                                InputDecoration(
                              labelText:
                                  'تسمية النوع (اختياري)',
                              hintText:
                                  'مثال: تحاليل، فيتامين د',
                              filled: true,
                              fillColor:
                                  AppColors
                                      .backgroundCream,
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      AppColors
                                          .borderLight,
                                ),
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      AppColors
                                          .borderLight,
                                ),
                              ),
                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      AppColors
                                          .primary,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 14,
                        ),

                        TextField(
                          controller:
                              titleController,
                          textDirection:
                              TextDirection.rtl,
                          decoration:
                              InputDecoration(
                            labelText:
                                'اسم الموعد',
                            hintText:
                                'مثال: تطعيم الشهرين',
                            errorText:
                                showTitleError
                                    ? 'يرجى كتابة اسم الموعد'
                                    : null,
                            filled: true,
                            fillColor:
                                AppColors
                                    .backgroundCream,
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  const BorderSide(
                                color: AppColors
                                    .borderLight,
                              ),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  const BorderSide(
                                color: AppColors
                                    .borderLight,
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    AppColors.primary,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            if (showTitleError) {
                              setDialogState(
                                () {
                                  showTitleError =
                                      false;
                                },
                              );
                            }
                          },
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        TextField(
                          controller:
                              descriptionController,
                          textDirection:
                              TextDirection.rtl,
                          minLines: 2,
                          maxLines: 3,
                          decoration:
                              InputDecoration(
                            labelText:
                                'الوصف أو الملاحظات (اختياري)',
                            hintText:
                                'أضيفي اسم المستوصف أو تفاصيل اللقاح',
                            alignLabelWithHint:
                                true,
                            filled: true,
                            fillColor:
                                AppColors
                                    .backgroundCream,
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  const BorderSide(
                                color: AppColors
                                    .borderLight,
                              ),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  const BorderSide(
                                color: AppColors
                                    .borderLight,
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _DialogPickerTile(
                          icon: Icons
                              .calendar_month_outlined,
                          label: 'التاريخ',
                          value: _formatDate(
                            selectedDate,
                          ),
                          onTap: () async {
                            final pickedDate =
                                await _showArabicDatePicker(
                              initialDate:
                                  selectedDate,
                              firstDate:
                                  DateTime(2020),
                              lastDate:
                                  DateTime(2035),
                            );

                            if (pickedDate !=
                                null) {
                              setDialogState(
                                () {
                                  selectedDate =
                                      pickedDate;
                                },
                              );
                            }
                          },
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        _DialogPickerTile(
                          icon: Icons
                              .access_time_rounded,
                          label: 'الوقت',
                          value: _formatTime(
                            selectedTime,
                          ),
                          onTap: () async {
                            final pickedTime =
                                await _showArabicTimePicker(
                              initialTime:
                                  selectedTime,
                            );

                            if (pickedTime !=
                                null) {
                              setDialogState(
                                () {
                                  selectedTime =
                                      pickedTime;
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                            ).pop(false);
                          },
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                AppColors
                                    .textPrimary,
                            side:
                                const BorderSide(
                              color: AppColors
                                  .borderBeige,
                              width: 1.2,
                            ),
                            minimumSize:
                                const Size(
                              double.infinity,
                              48,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style:
                                AppTextStyles
                                    .buttonTextDark
                                    .copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child:
                            ElevatedButton(
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                AppColors.primary,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            minimumSize:
                                const Size(
                              double.infinity,
                              48,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                          onPressed: () {
                            if (titleController
                                .text
                                .trim()
                                .isEmpty) {
                              setDialogState(
                                () {
                                  showTitleError =
                                      true;
                                },
                              );
                              return;
                            }

                            Navigator.of(
                              dialogContext,
                            ).pop(true);
                          },
                          child: Text(
                            appointment == null
                                ? 'إضافة'
                                : 'حفظ',
                            style:
                                AppTextStyles
                                    .buttonText
                                    .copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (shouldSave != true ||
        !mounted) {
      titleController.dispose();
      descriptionController.dispose();
      customTypeController.dispose();
      return;
    }

    final title =
        titleController.text.trim();

    final description =
        descriptionController.text.trim();

    final customType =
        customTypeController.text.trim();

    final resolvedType =
        selectedType == 'other' &&
                customType.isNotEmpty
            ? customType
            : selectedType;

    titleController.dispose();
    descriptionController.dispose();
    customTypeController.dispose();

    final reminderDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    try {
      if (appointment == null) {
        await FirestoreService.instance
            .createReminder(
          title: title,
          description:
              description.isEmpty
                  ? null
                  : description,
          dateTime: reminderDateTime,
          type: resolvedType,
          status: 'active',
        );
      } else {
        await FirestoreService.instance
            .updateReminder(
          reminderId:
              appointment.reminderId,
          title: title,
          description:
              description.isEmpty
                  ? null
                  : description,
          dateTime: reminderDateTime,
          type: resolvedType,
          status: appointment.status,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
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

      AppSnackBar.show(
        context,
        appointment == null
            ? 'تمت إضافة الموعد بنجاح'
            : 'تم حفظ تعديلات الموعد',
        type: AppSnackBarType.success,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Reminder save error: ${e.code} | ${e.message}',
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        'حدث خطأ أثناء حفظ الموعد',
        type: AppSnackBarType.error,
      );
    } catch (e) {
      debugPrint(
        'Reminder save error: $e',
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        'حدث خطأ أثناء حفظ الموعد',
        type: AppSnackBarType.error,
      );
    }
  }

  // ═════════════════════════════════════════════════════════════
  // Delete reminder with Confirmation + Undo
  // ═════════════════════════════════════════════════════════════

  Future<void> _deleteAppointment(
    _Appointment appointment,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.28,
      ),
      builder: (dialogContext) {
        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: AlertDialog(
            backgroundColor:
                AppColors.cardSurface,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
            ),
            titlePadding:
                const EdgeInsets.fromLTRB(
              22,
              24,
              22,
              0,
            ),
            contentPadding:
                const EdgeInsets.fromLTRB(
              22,
              10,
              22,
              0,
            ),
            actionsPadding:
                const EdgeInsets.fromLTRB(
              18,
              20,
              18,
              18,
            ),
            title: Center(
              child: Text(
                'حذف الموعد؟',
                style: AppTextStyles
                    .screenTitle
                    .copyWith(
                  fontSize: 18,
                ),
              ),
            ),
            content: Text(
              'هل أنتِ متأكدة من حذف "${appointment.title}"؟ يمكنكِ التراجع فور الحذف.',
              textAlign:
                  TextAlign.center,
              style:
                  AppTextStyles.helperText
                      .copyWith(
                fontSize: 11.5,
                height: 1.7,
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(false);
                      },
                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            AppColors
                                .textPrimary,
                        side:
                            const BorderSide(
                          color: AppColors
                              .borderBeige,
                          width: 1.2,
                        ),
                        minimumSize:
                            const Size(
                          double.infinity,
                          48,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: AppTextStyles
                            .buttonTextDark
                            .copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        ElevatedButton(
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppColors.alert,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        minimumSize:
                            const Size(
                          double.infinity,
                          48,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(true);
                      },
                      child: Text(
                        'حذف',
                        style: AppTextStyles
                            .buttonText
                            .copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete != true ||
        !mounted) {
      return;
    }

    try {
      await FirestoreService.instance
          .deleteReminder(
        reminderId:
            appointment.reminderId,
      );

      if (!mounted) {
        return;
      }

      _showUndoDeleteSnackBar(
        appointment,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Reminder delete error: ${e.code} | ${e.message}',
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        'حدث خطأ أثناء حذف الموعد',
        type: AppSnackBarType.error,
      );
    } catch (e) {
      debugPrint(
        'Reminder delete error: $e',
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        'حدث خطأ أثناء حذف الموعد',
        type: AppSnackBarType.error,
      );
    }
  }

  void _showUndoDeleteSnackBar(
    _Appointment deletedAppointment,
  ) {
    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              Colors.transparent,
          elevation: 0,
          margin:
              const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16,
          ),
          padding: EdgeInsets.zero,
          duration:
              const Duration(
            seconds: 5,
          ),
          content: Directionality(
            textDirection:
                TextDirection.rtl,
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors
                    .backgroundBeige,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color: AppColors
                      .borderBeige,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color:
                        Color(0x14785037),
                    blurRadius: 14,
                    offset:
                        Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration:
                        const BoxDecoration(
                      color:
                          AppColors.primary,
                      shape:
                          BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons
                          .restore_from_trash_rounded,
                      size: 16,
                      color:
                          Colors.white,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      'تم حذف "${deletedAppointment.title}"',
                      style:
                          AppTextStyles
                              .bodyText
                              .copyWith(
                        fontSize: 12.5,
                        fontWeight:
                            FontWeight
                                .w500,
                        color: AppColors
                            .textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      messenger
                          .hideCurrentSnackBar();

                      try {
                        await FirestoreService
                            .instance
                            .createReminder(
                          title:
                              deletedAppointment
                                  .title,
                          description:
                              deletedAppointment
                                      .description
                                      .isEmpty
                                  ? null
                                  : deletedAppointment
                                      .description,
                          dateTime:
                              DateTime(
                            deletedAppointment
                                .date.year,
                            deletedAppointment
                                .date.month,
                            deletedAppointment
                                .date.day,
                            deletedAppointment
                                .time.hour,
                            deletedAppointment
                                .time.minute,
                          ),
                          type:
                              deletedAppointment
                                  .type,
                          status:
                              deletedAppointment
                                  .status,
                        );

                        if (!mounted) {
                          return;
                        }

                        AppSnackBar.show(
                          context,
                          'تمت استعادة الموعد بنجاح',
                          type:
                              AppSnackBarType
                                  .success,
                        );
                      } catch (e) {
                        debugPrint(
                          'Undo delete error: $e',
                        );
                      }
                    },
                    child: Text(
                      'تراجع',
                      style:
                          AppTextStyles
                              .featureDesc
                              .copyWith(
                        fontSize: 12.5,
                        fontWeight:
                            FontWeight
                                .w700,
                        color:
                            AppColors.primary,
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

  // ═════════════════════════════════════════════════════════════
  // Arabic date picker
  // ═════════════════════════════════════════════════════════════

  Future<DateTime?> _showArabicDatePicker({
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
                            _formatDate(selectedDate),
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

  // ═════════════════════════════════════════════════════════════
  // Arabic time picker
  // ═════════════════════════════════════════════════════════════

  Future<TimeOfDay?> _showArabicTimePicker({
    required TimeOfDay initialTime,
  }) async {
    int selectedHour = initialTime.hourOfPeriod == 0
        ? 12
        : initialTime.hourOfPeriod;
    int selectedMinute = initialTime.minute;
    bool isAm = initialTime.period == DayPeriod.am;

    final hourController = TextEditingController(
      text: ArabicNumberFormatter.formatInt(selectedHour),
    );

    final minuteController = TextEditingController(
      text: ArabicNumberFormatter.toArabic(
        selectedMinute.toString().padLeft(2, '0'),
      ),
    );

    String? hourError;
    String? minuteError;

    int? parseArabicNumber(String value) {
      final westernValue = value
          .replaceAll('٠', '0')
          .replaceAll('١', '1')
          .replaceAll('٢', '2')
          .replaceAll('٣', '3')
          .replaceAll('٤', '4')
          .replaceAll('٥', '5')
          .replaceAll('٦', '6')
          .replaceAll('٧', '7')
          .replaceAll('٨', '8')
          .replaceAll('٩', '9')
          .trim();

      return int.tryParse(westernValue);
    }

    Future<int?> showNumberList({
      required String title,
      required int min,
      required int max,
      required int selectedValue,
      required bool padWithZero,
    }) {
      return showDialog<int>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.20),
        builder: (listContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              backgroundColor: AppColors.cardSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                  maxHeight: 440,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                      child: Row(
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'إغلاق',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.of(listContext).pop();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: AppColors.borderLight,
                    ),
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: max - min + 1,
                        itemBuilder: (context, index) {
                          final value = min + index;
                          final isSelected = value == selectedValue;
                          final displayValue = padWithZero
                              ? ArabicNumberFormatter.toArabic(
                                  value.toString().padLeft(2, '0'),
                                )
                              : ArabicNumberFormatter.formatInt(value);

                          return InkWell(
                            onTap: () {
                              Navigator.of(listContext).pop(value);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.iconBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayValue,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primaryDark
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final result = await showDialog<TimeOfDay>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              void updateHourFromText(String value) {
                final parsed = parseArabicNumber(value);

                if (parsed != null && parsed >= 1 && parsed <= 12) {
                  setDialogState(() {
                    selectedHour = parsed;
                    hourError = null;
                  });
                }
              }

              void updateMinuteFromText(String value) {
                final parsed = parseArabicNumber(value);

                if (parsed != null && parsed >= 0 && parsed <= 59) {
                  setDialogState(() {
                    selectedMinute = parsed;
                    minuteError = null;
                  });
                }
              }

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
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'اختيار الوقت',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'إغلاق',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textSecondary,
                                  size: 21,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ArabicTimeInputBox(
                                  label: 'الساعة',
                                  controller: hourController,
                                  errorText: hourError,
                                  onChanged: updateHourFromText,
                                  onPick: () async {
                                    final picked = await showNumberList(
                                      title: 'اختيار الساعة',
                                      min: 1,
                                      max: 12,
                                      selectedValue: selectedHour,
                                      padWithZero: false,
                                    );

                                    if (picked != null) {
                                      setDialogState(() {
                                        selectedHour = picked;
                                        hourController.text =
                                            ArabicNumberFormatter.formatInt(
                                          picked,
                                        );
                                        hourError = null;
                                      });
                                    }
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    top: 29,
                                  ),
                                  child: Text(
                                    ':',
                                    style: AppTextStyles.screenTitle.copyWith(
                                      fontSize: 28,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                _ArabicTimeInputBox(
                                  label: 'الدقيقة',
                                  controller: minuteController,
                                  errorText: minuteError,
                                  onChanged: updateMinuteFromText,
                                  onPick: () async {
                                    final picked = await showNumberList(
                                      title: 'اختيار الدقيقة',
                                      min: 0,
                                      max: 59,
                                      selectedValue: selectedMinute,
                                      padWithZero: true,
                                    );

                                    if (picked != null) {
                                      setDialogState(() {
                                        selectedMinute = picked;
                                        minuteController.text =
                                            ArabicNumberFormatter.toArabic(
                                          picked
                                              .toString()
                                              .padLeft(2, '0'),
                                        );
                                        minuteError = null;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ArabicPeriodButton(
                                label: 'ص',
                                isSelected: isAm,
                                onTap: () {
                                  setDialogState(() {
                                    isAm = true;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _ArabicPeriodButton(
                                label: 'م',
                                isSelected: !isAm,
                                onTap: () {
                                  setDialogState(() {
                                    isAm = false;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    side: const BorderSide(
                                      color: AppColors.borderBeige,
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'إلغاء',
                                    style:
                                        AppTextStyles.buttonTextDark.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final parsedHour = parseArabicNumber(
                                      hourController.text,
                                    );
                                    final parsedMinute = parseArabicNumber(
                                      minuteController.text,
                                    );

                                    final validHour = parsedHour != null &&
                                        parsedHour >= 1 &&
                                        parsedHour <= 12;

                                    final validMinute = parsedMinute != null &&
                                        parsedMinute >= 0 &&
                                        parsedMinute <= 59;

                                    if (!validHour || !validMinute) {
                                      setDialogState(() {
                                        hourError = validHour
                                            ? null
                                            : 'من ١ إلى ١٢';
                                        minuteError = validMinute
                                            ? null
                                            : 'من ٠٠ إلى ٥٩';
                                      });
                                      return;
                                    }

                                    selectedHour = parsedHour;
                                    selectedMinute = parsedMinute;

                                    final hour24 = isAm
                                        ? (selectedHour == 12
                                            ? 0
                                            : selectedHour)
                                        : (selectedHour == 12
                                            ? 12
                                            : selectedHour + 12);

                                    Navigator.of(dialogContext).pop(
                                      TimeOfDay(
                                        hour: hour24,
                                        minute: selectedMinute,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
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
                ),
              );
            },
          ),
        );
      },
    );

    
    return result;
  }

  // ═════════════════════════════════════════════════════════════
  // Formatting
  // ═════════════════════════════════════════════════════════════

  String _formatDate(
    DateTime date,
  ) {
    final monthName =
        _arabicMonths[
            date.month - 1];

    return '${ArabicNumberFormatter.formatInt(date.day)} '
        '$monthName '
        '${ArabicNumberFormatter.formatInt(date.year)}';
  }

  String _formatTime(
    TimeOfDay time,
  ) {
    final period =
        time.hour < 12
            ? 'ص'
            : 'م';

    int hour =
        time.hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    final minute =
        time.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return ArabicNumberFormatter.toArabic(
      '$hour:$minute $period',
    );
  }

  bool get _isViewingCurrentMonth {
    final now = DateTime.now();

    return _visibleMonth.year ==
            now.year &&
        _visibleMonth.month ==
            now.month;
  }

  // ═════════════════════════════════════════════════════════════
  // UI
  // ═════════════════════════════════════════════════════════════

  @override
  Widget build(
    BuildContext context,
  ) {
    final appointmentsList =
        _filteredAppointments;

    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            AppColors
                .backgroundCream,
        body: SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              16,
              20,
              28,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                _CalendarHeader(
                  showTodayButton:
                      !_isViewingCurrentMonth ||
                          _selectedDate !=
                              null,
                  onTodayPressed:
                      _jumpToToday,
                ),

                const SizedBox(
                  height: 18,
                ),

                _MonthCard(
                  visibleMonth:
                      _visibleMonth,
                  selectedDate:
                      _selectedDate,
                  monthName:
                      _arabicMonths[
                          _visibleMonth
                                  .month -
                              1],
                  appointmentCountForDay:
                      _appointmentCountForDay,
                  onDaySelected:
                      _selectDay,
                  onPreviousMonth:
                      _previousMonth,
                  onNextMonth:
                      _nextMonth,
                ),

                const SizedBox(
                  height: 22,
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            _selectedDate !=
                                    null
                                ? 'مواعيد ${_formatDate(_selectedDate!)}'
                                : 'مواعيد شهر ${_arabicMonths[_visibleMonth.month - 1]}',
                            style:
                                AppTextStyles
                                    .cardTitle
                                    .copyWith(
                              fontSize:
                                  17,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                          if (_selectedDate !=
                              null)
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                top: 2,
                              ),
                              child:
                                  InkWell(
                                onTap: () {
                                  setState(
                                    () {
                                      _selectedDate =
                                          null;
                                    },
                                  );
                                },
                                child:
                                    Text(
                                  'عرض جميع مواعيد الشهر ✕',
                                  style:
                                      AppTextStyles
                                          .featureDesc
                                          .copyWith(
                                    fontSize:
                                        11,
                                    color:
                                        AppColors.primary,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppColors
                                .primary,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              14,
                          vertical: 8,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                      onPressed: () {
                        _showAppointmentDialog();
                      },
                      icon:
                          const Icon(
                        Icons.add_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'إضافة موعد',
                        style:
                            AppTextStyles
                                .featureDesc
                                .copyWith(
                          fontSize: 12,
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    _StatusFilterChip(
                      label: 'الكل',
                      isSelected:
                          _statusFilter ==
                              'all',
                      onTap: () {
                        setState(
                          () {
                            _statusFilter =
                                'all';
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    _StatusFilterChip(
                      label: 'القادمة',
                      isSelected:
                          _statusFilter ==
                              'upcoming',
                      onTap: () {
                        setState(
                          () {
                            _statusFilter =
                                'upcoming';
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    _StatusFilterChip(
                      label: 'المكتملة',
                      isSelected:
                          _statusFilter ==
                              'completed',
                      onTap: () {
                        setState(
                          () {
                            _statusFilter =
                                'completed';
                          },
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(
                  height: 14,
                ),

                if (appointmentsList
                    .isEmpty)
                  _NoAppointmentsCard(
                    hasSelectedDay:
                        _selectedDate !=
                            null,
                    onShowAllMonth:
                        _selectedDate !=
                                null
                            ? () {
                                setState(
                                  () {
                                    _selectedDate =
                                        null;
                                  },
                                );
                              }
                            : null,
                    onAddAppointment:
                        () {
                      _showAppointmentDialog();
                    },
                  )
                else
                  ...appointmentsList.map(
                    (appointment) =>
                        Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        bottom: 12,
                      ),
                      child:
                          _AppointmentCard(
                        accentColor:
                            _accentColorForType(
                          appointment
                              .type,
                        ),
                        badgeBgColor:
                            _bgColorForType(
                          appointment
                              .type,
                        ),
                        title:
                            appointment
                                .title,
                        description:
                            appointment
                                .description,
                        typeLabel:
                            _typeLabel(
                          appointment
                              .type,
                        ),
                        relativeBadge:
                            _relativeDateBadge(
                          appointment,
                        ),
                        isCompleted:
                            _isCompleted(
                          appointment,
                        ),
                        date:
                            _formatDate(
                          appointment
                              .date,
                        ),
                        time:
                            _formatTime(
                          appointment
                              .time,
                        ),
                        onToggleStatus:
                            () {
                          _toggleAppointmentStatus(
                            appointment,
                          );
                        },
                        onEdit: () {
                          _showAppointmentDialog(
                            appointment:
                                appointment,
                          );
                        },
                        onDelete: () {
                          _deleteAppointment(
                            appointment,
                          );
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

// ═════════════════════════════════════════════════════════════════
// Header
// ═════════════════════════════════════════════════════════════════

class _CalendarHeader
    extends StatelessWidget {
  const _CalendarHeader({
    required this.showTodayButton,
    required this.onTodayPressed,
  });

  final bool showTodayButton;
  final VoidCallback onTodayPressed;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Text(
          'التقويم والتذكيرات',
          style:
              AppTextStyles.cardTitle
                  .copyWith(
            fontSize: 20,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (showTodayButton)
          InkWell(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            onTap:
                onTodayPressed,
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.iconBg,
                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
                border: Border.all(
                  color:
                      AppColors
                          .borderBeige,
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons
                        .today_rounded,
                    size: 15,
                    color: AppColors
                        .primary,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    'اليوم',
                    style:
                        AppTextStyles
                            .featureDesc
                            .copyWith(
                      fontSize:
                          11.5,
                      fontWeight:
                          FontWeight
                              .w700,
                      color:
                          AppColors
                              .primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Month card
// ═════════════════════════════════════════════════════════════════

class _MonthCard
    extends StatelessWidget {
  const _MonthCard({
    required this.visibleMonth,
    required this.selectedDate,
    required this.monthName,
    required this.appointmentCountForDay,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final String monthName;

  final int Function(int day)
      appointmentCountForDay;

  final ValueChanged<int>
      onDaySelected;

  final VoidCallback
      onPreviousMonth;

  final VoidCallback
      onNextMonth;

  @override
  Widget build(
    BuildContext context,
  ) {
    final now = DateTime.now();

    final firstDay = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    );

    final numberOfDays =
        DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;

    final leadingEmptyCells =
        firstDay.weekday % 7;

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
      padding:
          const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius:
            BorderRadius.circular(
          28,
        ),
        boxShadow: const [
          BoxShadow(
            color:
                Color(0x0D785037),
            blurRadius: 14,
            offset:
                Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              _MonthArrow(
                icon: Icons
                    .chevron_right_rounded,
                onTap:
                    onPreviousMonth,
              ),
              Text(
                '$monthName ${ArabicNumberFormatter.formatInt(visibleMonth.year)}',
                style:
                    AppTextStyles
                        .cardTitle
                        .copyWith(
                  fontSize: 16,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
              _MonthArrow(
                icon: Icons
                    .chevron_left_rounded,
                onTap:
                    onNextMonth,
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Row(
            children: weekDays
                .map(
                  (day) =>
                      Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style:
                            AppTextStyles
                                .featureDesc
                                .copyWith(
                          fontSize:
                              10.5,
                          color: AppColors
                              .textSecondary,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(
            height: 10,
          ),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount:
                leadingEmptyCells +
                    numberOfDays,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder:
                (context, index) {
              if (index <
                  leadingEmptyCells) {
                return const SizedBox
                    .shrink();
              }

              final day =
                  index -
                      leadingEmptyCells +
                      1;

              final isSelected =
                  selectedDate !=
                          null &&
                      selectedDate!
                              .year ==
                          visibleMonth
                              .year &&
                      selectedDate!
                              .month ==
                          visibleMonth
                              .month &&
                      selectedDate!
                              .day ==
                          day;

              final isToday =
                  now.year ==
                          visibleMonth
                              .year &&
                      now.month ==
                          visibleMonth
                              .month &&
                      now.day ==
                          day;

              return _CalendarDay(
                day: day,
                isSelected:
                    isSelected,
                isToday:
                    isToday,
                eventCount:
                    appointmentCountForDay(
                  day,
                ),
                onTap: () {
                  onDaySelected(
                    day,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthArrow
    extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration:
            BoxDecoration(
          color: AppColors.iconBg,
          borderRadius:
              BorderRadius
                  .circular(
            12,
          ),
        ),
        child: Icon(
          icon,
          color:
              AppColors.primary,
          size: 21,
        ),
      ),
    );
  }
}

class _CalendarDay
    extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.eventCount,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final int eventCount;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      onTap: onTap,
      child: Container(
        decoration:
            BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isToday
                  ? AppColors.iconBg
                  : Colors
                      .transparent),
          borderRadius:
              BorderRadius
                  .circular(
            12,
          ),
          border:
              isToday &&
                      !isSelected
                  ? Border.all(
                      color:
                          AppColors
                              .primary,
                      width: 1.3,
                    )
                  : null,
        ),
        child: Stack(
          alignment:
              Alignment.center,
          children: [
            Text(
              ArabicNumberFormatter.formatInt(day),
              style:
                  AppTextStyles
                      .featureDesc
                      .copyWith(
                fontSize: 12,
                fontWeight:
                    isSelected ||
                            isToday
                        ? FontWeight
                            .w700
                        : FontWeight
                            .w600,
                color: isSelected
                    ? Colors.white
                    : (isToday
                        ? AppColors
                            .primaryDark
                        : AppColors
                            .textSecondary),
              ),
            ),
            if (eventCount > 0)
              Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize:
                      MainAxisSize
                          .min,
                  children:
                      List.generate(
                    eventCount > 3
                        ? 3
                        : eventCount,
                    (i) =>
                        Container(
                      margin:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            1,
                      ),
                      width: 4,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color: isSelected
                            ? Colors
                                .white
                            : AppColors
                                .primary,
                        shape:
                            BoxShape
                                .circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Status Filter Chip & Type Chip Option
// ═════════════════════════════════════════════════════════════════

class _StatusFilterChip
    extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        999,
      ),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        decoration:
            BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors
                  .cardSurface,
          borderRadius:
              BorderRadius
                  .circular(
            999,
          ),
          border: Border.all(
            color: isSelected
                ? AppColors
                    .primary
                : AppColors
                    .borderLight,
          ),
        ),
        child: Text(
          label,
          style:
              AppTextStyles
                  .featureDesc
                  .copyWith(
            fontSize: 11.5,
            fontWeight:
                FontWeight.w600,
            color: isSelected
                ? Colors.white
                : AppColors
                    .textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TypeChipOption
    extends StatelessWidget {
  const _TypeChipOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final IconData icon;
  final String selectedValue;

  final ValueChanged<String>
      onSelected;

  @override
  Widget build(
    BuildContext context,
  ) {
    final isSelected =
        value ==
            selectedValue;

    return InkWell(
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      onTap: () {
        onSelected(
          value,
        );
      },
      child: Container(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 11,
          vertical: 7,
        ),
        decoration:
            BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors
                  .backgroundCream,
          borderRadius:
              BorderRadius
                  .circular(
            12,
          ),
          border: Border.all(
            color: isSelected
                ? AppColors
                    .primary
                : AppColors
                    .borderLight,
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : AppColors
                      .primary,
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              label,
              style:
                  AppTextStyles
                      .featureDesc
                      .copyWith(
                fontSize: 11.5,
                fontWeight:
                    FontWeight
                        .w600,
                color: isSelected
                    ? Colors.white
                    : AppColors
                        .textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Appointment model
// ═════════════════════════════════════════════════════════════════

class _Appointment {
  const _Appointment({
    required this.reminderId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.date,
    required this.time,
  });

  final String reminderId;
  final String title;
  final String description;
  final String type;
  final String status;
  final DateTime date;
  final TimeOfDay time;
}

// ═════════════════════════════════════════════════════════════════
// Appointment card
// ═════════════════════════════════════════════════════════════════

class _AppointmentCard
    extends StatelessWidget {
  const _AppointmentCard({
    required this.accentColor,
    required this.badgeBgColor,
    required this.title,
    required this.description,
    required this.typeLabel,
    required this.relativeBadge,
    required this.isCompleted,
    required this.date,
    required this.time,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final Color accentColor;
  final Color badgeBgColor;

  final String title;
  final String description;
  final String typeLabel;
  final String relativeBadge;

  final bool isCompleted;

  final String date;
  final String time;

  final VoidCallback
      onToggleStatus;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration:
          BoxDecoration(
        color: isCompleted
            ? AppColors.cardSurface
                .withValues(
                  alpha: 0.78,
                )
            : AppColors.cardSurface,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: isCompleted
              ? AppColors.success
                  .withValues(
                    alpha: 0.35,
                  )
              : AppColors
                  .borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color:
                Color(0x0D785037),
            blurRadius: 12,
            offset:
                Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          IconButton(
            tooltip: isCompleted
                ? 'إعادة إلى القادمة'
                : 'تحديد كمكتمل',
            visualDensity:
                VisualDensity.compact,
            padding:
                EdgeInsets.zero,
            constraints:
                const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            onPressed:
                onToggleStatus,
            icon: Icon(
              isCompleted
                  ? Icons
                      .check_circle_rounded
                  : Icons
                      .radio_button_unchecked_rounded,
              color: isCompleted
                  ? AppColors.success
                  : AppColors.primary,
              size: 26,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style:
                            AppTextStyles
                                .cardTitle
                                .copyWith(
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .w600,
                          decoration:
                              isCompleted
                                  ? TextDecoration
                                      .lineThrough
                                  : null,
                          color: isCompleted
                              ? AppColors
                                  .textSecondary
                              : AppColors
                                  .textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (description
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    description,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        AppTextStyles
                            .featureDesc
                            .copyWith(
                      fontSize: 11,
                      height: 1.5,
                      color: AppColors
                          .textSecondary,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 8,
                ),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment:
                      WrapCrossAlignment
                          .center,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            badgeBgColor,
                        borderRadius:
                            BorderRadius
                                .circular(
                          999,
                        ),
                      ),
                      child: Text(
                        typeLabel,
                        style:
                            AppTextStyles
                                .featureDesc
                                .copyWith(
                          fontSize: 10,
                          color:
                              accentColor,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color: isCompleted
                            ? AppColors
                                .successBg
                            : AppColors
                                .backgroundCream,
                        borderRadius:
                            BorderRadius
                                .circular(
                          999,
                        ),
                        border:
                            Border.all(
                          color: isCompleted
                              ? AppColors
                                  .success
                                  .withValues(
                                    alpha:
                                        0.4,
                                  )
                              : AppColors
                                  .borderBeige,
                        ),
                      ),
                      child: Text(
                        relativeBadge,
                        style:
                            AppTextStyles
                                .featureDesc
                                .copyWith(
                          fontSize: 10,
                          color: isCompleted
                              ? AppColors
                                  .success
                              : AppColors
                                  .textSecondary,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 6,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .schedule_rounded,
                      size: 13,
                      color: AppColors
                          .textSecondary,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text(
                      '$date • $time',
                      style:
                          AppTextStyles
                              .featureDesc
                              .copyWith(
                        fontSize: 11,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                tooltip:
                    'خيارات الموعد',
                icon: const Icon(
                  Icons
                      .more_vert_rounded,
                  color: AppColors
                      .textSecondary,
                  size: 20,
                ),
                color:
                    AppColors.cardSurface,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),
                onSelected:
                    (value) {
                  if (value ==
                      'edit') {
                    onEdit();
                  } else if (value ==
                      'delete') {
                    onDelete();
                  }
                },
                itemBuilder:
                    (context) => [
                  PopupMenuItem<
                      String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .edit_outlined,
                          size: 19,
                          color: AppColors
                              .primary,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          'تعديل',
                          style:
                              AppTextStyles
                                  .featureDesc
                                  .copyWith(
                            fontSize:
                                12,
                            color: AppColors
                                .textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<
                      String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .delete_outline_rounded,
                          size: 19,
                          color:
                              AppColors.alert,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          'حذف',
                          style:
                              AppTextStyles
                                  .featureDesc
                                  .copyWith(
                            fontSize:
                                12,
                            color:
                                AppColors.alert,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Arabic time picker helper widgets
// ═════════════════════════════════════════════════════════════════

class _ArabicTimeInputBox extends StatelessWidget {
  const _ArabicTimeInputBox({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.onPick,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onPick;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.featureDesc.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              onChanged: onChanged,
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 26,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                errorText: errorText,
                errorStyle: AppTextStyles.helperText.copyWith(
                  fontSize: 9,
                  color: AppColors.alert,
                ),
                filled: true,
                fillColor: AppColors.backgroundCream,
                contentPadding: const EdgeInsets.fromLTRB(
                  8,
                  18,
                  8,
                  18,
                ),
                suffixIcon: IconButton(
                  tooltip: 'اختيار من القائمة',
                  onPressed: onPick,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.primary,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArabicPeriodButton extends StatelessWidget {
  const _ArabicPeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.iconBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTextStyles.featureDesc.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? AppColors.primaryDark
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Dialog picker tile
// ═════════════════════════════════════════════════════════════════

class _DialogPickerTile
    extends StatelessWidget {
  const _DialogPickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration:
            BoxDecoration(
          color: AppColors
              .backgroundCream,
          borderRadius:
              BorderRadius
                  .circular(
            14,
          ),
          border: Border.all(
            color:
                AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(
                color: AppColors.iconBg,
                borderRadius:
                    BorderRadius
                        .circular(
                  11,
                ),
              ),
              child: Icon(
                icon,
                size: 19,
                color:
                    AppColors.primary,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    label,
                    style:
                        AppTextStyles
                            .featureDesc
                            .copyWith(
                      fontSize: 10.5,
                      color: AppColors
                          .textSecondary,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    value,
                    style:
                        AppTextStyles
                            .cardTitle
                            .copyWith(
                      fontSize: 13,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons
                  .chevron_left_rounded,
              color: AppColors
                  .textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Empty state
// ═════════════════════════════════════════════════════════════════

class _NoAppointmentsCard
    extends StatelessWidget {
  const _NoAppointmentsCard({
    required this.hasSelectedDay,
    required this.onShowAllMonth,
    required this.onAddAppointment,
  });

  final bool hasSelectedDay;
  final VoidCallback?
      onShowAllMonth;
  final VoidCallback
      onAddAppointment;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 16,
        vertical: 22,
      ),
      decoration:
          BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: AppColors.iconBg,
              borderRadius:
                  BorderRadius
                      .circular(
                14,
              ),
            ),
            child: const Icon(
              Icons
                  .event_available_outlined,
              color:
                  AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            hasSelectedDay
                ? 'لا توجد مواعيد مسجلة في هذا اليوم'
                : 'لا توجد مواعيد في هذا الشهر',
            style:
                AppTextStyles
                    .featureDesc
                    .copyWith(
              fontSize: 12.5,
              color: AppColors
                  .textSecondary,
              fontWeight:
                  FontWeight
                      .w600,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Wrap(
            spacing: 10,
            children: [
              if (hasSelectedDay &&
                  onShowAllMonth !=
                      null)
                TextButton(
                  onPressed:
                      onShowAllMonth,
                  child: Text(
                    'عرض كل مواعيد الشهر',
                    style:
                        AppTextStyles
                            .featureDesc
                            .copyWith(
                      fontSize: 12,
                      color: AppColors
                          .textSecondary,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed:
                    onAddAppointment,
                icon: const Icon(
                  Icons
                      .add_circle_outline_rounded,
                  size: 16,
                  color:
                      AppColors.primary,
                ),
                label: Text(
                  'إضافة موعد جديد',
                  style:
                      AppTextStyles
                          .featureDesc
                          .copyWith(
                    fontSize: 12,
                    color:
                        AppColors.primary,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}