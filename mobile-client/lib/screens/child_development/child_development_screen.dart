import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_snack_bar.dart';

class ChildDevelopmentScreen extends StatefulWidget {
  const ChildDevelopmentScreen({super.key});

  @override
  State<ChildDevelopmentScreen> createState() => _ChildDevelopmentScreenState();
}

class _ChildDevelopmentScreenState extends State<ChildDevelopmentScreen> {
  final TextEditingController _heightController = TextEditingController();

  final TextEditingController _weightController = TextEditingController();

  final TextEditingController _headController = TextEditingController();

  bool _hasSavedMeasurements = false;
  bool _isEditingMeasurements = true;
  bool _isAddingNewMeasurement = false;

  String? _growthRecordId;

  String _childAgeText = 'جاري حساب العمر...';
  bool _isAgeLoading = true;

  final List<_GrowthRecordData> _growthRecords = [];

  StreamSubscription<User?>? _authSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _accountSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _growthRecordsSubscription;

  @override
  void initState() {
    super.initState();
    _listenToAuthentication();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _accountSubscription?.cancel();
    _growthRecordsSubscription?.cancel();

    _heightController.dispose();
    _weightController.dispose();
    _headController.dispose();

    super.dispose();
  }

  void _listenToAuthentication() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        _accountSubscription?.cancel();
        _growthRecordsSubscription?.cancel();

        if (user == null) {
          if (!mounted) {
            return;
          }

          setState(() {
            _childAgeText = 'غير متاح';
            _isAgeLoading = false;

            _growthRecords.clear();
            _growthRecordId = null;
            _hasSavedMeasurements = false;
            _isEditingMeasurements = true;
            _isAddingNewMeasurement = false;

            _heightController.clear();
            _weightController.clear();
            _headController.clear();
          });

          return;
        }

        _listenToAccount();
        _listenToGrowthRecords();
      },
    );
  }

  void _listenToAccount() {
    _accountSubscription = FirestoreService.instance.watchAccount().listen(
      (snapshot) {
        final data = snapshot.data();
        final birthDateValue = data?['childDateOfBirth'];

        String ageText;

        if (birthDateValue is Timestamp) {
          ageText = _calculateAge(
            birthDateValue.toDate(),
          );
        } else {
          ageText = 'لم يتم تسجيل تاريخ الميلاد';
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _childAgeText = ageText;
          _isAgeLoading = false;
        });
      },
      onError: (Object error) {
        debugPrint(
          'Error loading child age: $error',
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _childAgeText = 'تعذر تحميل العمر';
          _isAgeLoading = false;
        });
      },
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final birth = DateTime(
      birthDate.year,
      birthDate.month,
      birthDate.day,
    );

    if (birth.isAfter(today)) {
      return 'تاريخ الميلاد غير صالح';
    }

    int years = today.year - birth.year;
    int months = today.month - birth.month;

    if (today.day < birth.day) {
      months--;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    if (years <= 0) {
      return _formatMonths(months);
    }

    if (years == 1) {
      if (months == 0) {
        return 'سنة واحدة';
      }

      return 'سنة و${_formatMonths(months)}';
    }

    if (years == 2) {
      if (months == 0) {
        return 'سنتان';
      }

      return 'سنتان و${_formatMonths(months)}';
    }

    if (months == 0) {
      return '$years سنوات';
    }

    return '$years سنوات و${_formatMonths(months)}';
  }

  String _formatMonths(int months) {
    if (months <= 0) {
      return 'أقل من شهر';
    }

    if (months == 1) {
      return 'شهر واحد';
    }

    if (months == 2) {
      return 'شهران';
    }

    if (months >= 3 && months <= 10) {
      return '$months أشهر';
    }

    return '$months شهرًا';
  }

  void _listenToGrowthRecords() {
    _growthRecordsSubscription =
        FirestoreService.instance.watchGrowthRecords().listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          if (!mounted) {
            return;
          }

          setState(() {
            _growthRecords.clear();

            _growthRecordId = null;
            _hasSavedMeasurements = false;
            _isEditingMeasurements = true;
            _isAddingNewMeasurement = false;

            _heightController.clear();
            _weightController.clear();
            _headController.clear();
          });

          return;
        }

        final records = <_GrowthRecordData>[];

        for (final document in snapshot.docs) {
          final data = document.data();

          final height = _numberToDouble(data['height']);

          final weight = _numberToDouble(data['weight']);

          final headCircumference = _numberToDouble(
            data['headCircumference'],
          );

          if (height == null || weight == null || headCircumference == null) {
            continue;
          }

          final createdAtValue = data['createdAt'];

          final createdAt = createdAtValue is Timestamp
              ? createdAtValue.toDate()
              : DateTime.now();

          records.add(
            _GrowthRecordData(
              recordId: document.id,
              height: height,
              weight: weight,
              headCircumference: headCircumference,
              createdAt: createdAt,
            ),
          );
        }

        records.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );

        if (records.isEmpty) {
          if (!mounted) {
            return;
          }

          setState(() {
            _growthRecords.clear();
            _growthRecordId = null;
            _hasSavedMeasurements = false;
            _isEditingMeasurements = true;
            _isAddingNewMeasurement = false;

            _heightController.clear();
            _weightController.clear();
            _headController.clear();
          });

          return;
        }

        final latestRecord = records.last;

        if (!mounted) {
          return;
        }

        setState(() {
          _growthRecords
            ..clear()
            ..addAll(records);

          if (!_isAddingNewMeasurement) {
            _growthRecordId = latestRecord.recordId;

            _heightController.text = _numberToText(
              latestRecord.height,
            );

            _weightController.text = _numberToText(
              latestRecord.weight,
            );

            _headController.text = _numberToText(
              latestRecord.headCircumference,
            );

            _isEditingMeasurements = false;
          }

          _hasSavedMeasurements = true;
        });
      },
      onError: (Object error) {
        debugPrint(
          'Error loading growth records: $error',
        );
      },
    );
  }

  double? _numberToDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return null;
  }

  String _numberToText(dynamic value) {
    if (value is int) {
      return value.toString();
    }

    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }

      return value.toString();
    }

    if (value is num) {
      return value.toString();
    }

    return '';
  }

  Future<void> _saveMeasurements() async {
    FocusScope.of(context).unfocus();

    final heightText = _heightController.text.trim().replaceAll(',', '.');

    final weightText = _weightController.text.trim().replaceAll(',', '.');

    final headText = _headController.text.trim().replaceAll(',', '.');

    if (heightText.isEmpty || weightText.isEmpty || headText.isEmpty) {
      AppSnackBar.show(
        context,
        'فضلاً أدخلي جميع القياسات',
        type: AppSnackBarType.info,
      );

      return;
    }

    final height = double.tryParse(heightText);

    final weight = double.tryParse(weightText);

    final headCircumference = double.tryParse(headText);

    if (height == null || weight == null || headCircumference == null) {
      AppSnackBar.show(
        context,
        'فضلاً أدخلي قياسات صحيحة',
        type: AppSnackBarType.info,
      );

      return;
    }

    final isNewMeasurement = _isAddingNewMeasurement || _growthRecordId == null;

    try {
      if (isNewMeasurement) {
        _growthRecordId = await FirestoreService.instance.createGrowthRecord(
          height: height,
          weight: weight,
          headCircumference: headCircumference,
        );
      } else {
        await FirestoreService.instance.updateGrowthRecord(
          recordId: _growthRecordId!,
          height: height,
          weight: weight,
          headCircumference: headCircumference,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _hasSavedMeasurements = true;
        _isEditingMeasurements = false;
        _isAddingNewMeasurement = false;
      });

      AppSnackBar.show(
        context,
        isNewMeasurement
            ? 'تم تسجيل القياس الجديد بنجاح'
            : 'تم تعديل القياسات بنجاح',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      debugPrint(
        'Growth record save error: $e',
      );

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        'حدث خطأ أثناء حفظ القياسات',
        type: AppSnackBarType.error,
      );
    }
  }

  void _editMeasurements() {
    if (_growthRecords.isEmpty) {
      return;
    }

    final latest = _growthRecords.last;

    _growthRecordId = latest.recordId;

    _heightController.text = _numberToText(latest.height);

    _weightController.text = _numberToText(latest.weight);

    _headController.text = _numberToText(
      latest.headCircumference,
    );

    setState(() {
      _isAddingNewMeasurement = false;
      _isEditingMeasurements = true;
    });
  }

  void _addNewMeasurement() {
    _growthRecordId = null;

    _heightController.clear();
    _weightController.clear();
    _headController.clear();

    setState(() {
      _isAddingNewMeasurement = true;
      _isEditingMeasurements = true;
    });
  }

  void _cancelMeasurementForm() {
    if (_growthRecords.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    final latest = _growthRecords.last;

    _growthRecordId = latest.recordId;

    _heightController.text = _numberToText(latest.height);

    _weightController.text = _numberToText(latest.weight);

    _headController.text = _numberToText(
      latest.headCircumference,
    );

    setState(() {
      _isAddingNewMeasurement = false;
      _isEditingMeasurements = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PageHeader(),
                const SizedBox(height: 22),
                _AgeCard(
                  ageText: _childAgeText,
                  isLoading: _isAgeLoading,
                ),
                const SizedBox(height: 16),
                if (!_hasSavedMeasurements || _isEditingMeasurements)
                  _MeasurementsFormCard(
                    heightController: _heightController,
                    weightController: _weightController,
                    headController: _headController,
                    hasSavedMeasurements: _hasSavedMeasurements,
                    isAddingNewMeasurement: _isAddingNewMeasurement,
                    onSave: _saveMeasurements,
                    onCancel: _cancelMeasurementForm,
                  )
                else
                  _GrowthChartsCard(
                    records: _growthRecords,
                    onEdit: _editMeasurements,
                    onAddNew: _addNewMeasurement,
                  ),
                const SizedBox(height: 22),
                Text(
                  'التطور في هذا العمر',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const _DevelopmentCard(),
                const SizedBox(height: 22),
                Text(
                  'أنشطة مناسبة لعمر الطفل',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const _ActivityCard(
                  icon: Icons.visibility_outlined,
                  title: 'تتبّع الأشياء',
                  description:
                      'حرّكي لعبة ملونة ببطء أمام الطفل لمساعدته على تتبعها بعينيه.',
                ),
                const SizedBox(height: 12),
                const _ActivityCard(
                  icon: Icons.record_voice_over_outlined,
                  title: 'التحدث مع الطفل',
                  description:
                      'تحدثي معه بصوت هادئ وكرري الأصوات البسيطة لدعم تفاعله.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

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
        const SizedBox(width: 12),
        Text(
          'نمو الطفل',
          style: AppTextStyles.cardTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AgeCard extends StatelessWidget {
  const _AgeCard({
    required this.ageText,
    required this.isLoading,
  });

  final String ageText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.child_care_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عمر الطفل الحالي',
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Text(
                    ageText,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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

class _MeasurementsFormCard extends StatelessWidget {
  const _MeasurementsFormCard({
    required this.heightController,
    required this.weightController,
    required this.headController,
    required this.hasSavedMeasurements,
    required this.isAddingNewMeasurement,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController heightController;

  final TextEditingController weightController;

  final TextEditingController headController;

  final bool hasSavedMeasurements;
  final bool isAddingNewMeasurement;

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    String buttonLabel;

    if (!hasSavedMeasurements) {
      title = 'تسجيل قياسات النمو';
      subtitle = 'أدخلي أحدث قياسات الطفل';
      buttonLabel = 'حفظ القياسات';
    } else if (isAddingNewMeasurement) {
      title = 'تسجيل قياس جديد';
      subtitle = 'أدخلي القياسات الحالية لإضافتها إلى سجل النمو';
      buttonLabel = 'حفظ القياس الجديد';
    } else {
      title = 'تعديل قياسات النمو';
      subtitle = 'عدّلي آخر قياسات محفوظة ثم احفظي التغييرات';
      buttonLabel = 'حفظ التعديلات';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D785037),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.straighten_rounded,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyles.featureDesc.copyWith(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSavedMeasurements) ...[
                const SizedBox(width: 12),
                _FormBackButton(
                  onTap: onCancel,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _MeasurementField(
            controller: heightController,
            label: 'الطول',
            hint: 'مثال: 60',
            unit: 'سم',
            icon: Icons.height_rounded,
          ),
          const SizedBox(height: 12),
          _MeasurementField(
            controller: weightController,
            label: 'الوزن',
            hint: 'مثال: 5.8',
            unit: 'كجم',
            icon: Icons.monitor_weight_outlined,
          ),
          const SizedBox(height: 12),
          _MeasurementField(
            controller: headController,
            label: 'محيط الرأس',
            hint: 'مثال: 40',
            unit: 'سم',
            icon: Icons.circle_outlined,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormBackButton extends StatelessWidget {
  const _FormBackButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'العودة إلى قياسات النمو',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(
                0xFFF4E8DE,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.unit,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        suffixText: unit,
        labelStyle: AppTextStyles.featureDesc.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
        hintStyle: AppTextStyles.featureDesc.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
        suffixStyle: AppTextStyles.featureDesc.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
        filled: true,
        fillColor: AppColors.backgroundCream,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified Growth Charts Card (Merged Height, Weight & Head Circumference)
// ─────────────────────────────────────────────────────────────────────────────

enum _GrowthMetricFilter {
  all,
  height,
  weight,
  head,
}

class _GrowthChartsCard extends StatefulWidget {
  const _GrowthChartsCard({
    required this.records,
    required this.onEdit,
    required this.onAddNew,
  });

  final List<_GrowthRecordData> records;
  final VoidCallback onEdit;
  final VoidCallback onAddNew;

  static const Color heightColor = AppColors.primary; // #CE7E52
  static const Color weightColor = Color(0xFF5E8C61); // Sage Green
  static const Color headColor = Color(0xFF5B82A6); // Warm Slate Blue

  static String formatMeasurement(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  State<_GrowthChartsCard> createState() => _GrowthChartsCardState();
}

class _GrowthChartsCardState extends State<_GrowthChartsCard> {
  _GrowthMetricFilter _selectedFilter = _GrowthMetricFilter.all;

  void _toggleCardFilter(_GrowthMetricFilter filter) {
    setState(() {
      if (_selectedFilter == filter) {
        _selectedFilter = _GrowthMetricFilter.all;
      } else {
        _selectedFilter = filter;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.records.last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D785037),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قياسات النمو',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'آخر القياسات المحفوظة وتطورها',
                      style: AppTextStyles.featureDesc.copyWith(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تعديل آخر قياس',
                onPressed: widget.onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── 3 Summary Metric Cards (Interactive) ──
          Row(
            children: [
              Expanded(
                child: _LatestValueCard(
                  label: 'الطول',
                  value: _GrowthChartsCard.formatMeasurement(latest.height),
                  unit: 'سم',
                  icon: Icons.height_rounded,
                  accentColor: _GrowthChartsCard.heightColor,
                  isSelected: _selectedFilter == _GrowthMetricFilter.height,
                  onTap: () => _toggleCardFilter(_GrowthMetricFilter.height),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LatestValueCard(
                  label: 'الوزن',
                  value: _GrowthChartsCard.formatMeasurement(latest.weight),
                  unit: 'كجم',
                  icon: Icons.monitor_weight_outlined,
                  accentColor: _GrowthChartsCard.weightColor,
                  isSelected: _selectedFilter == _GrowthMetricFilter.weight,
                  onTap: () => _toggleCardFilter(_GrowthMetricFilter.weight),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LatestValueCard(
                  label: 'محيط الرأس',
                  value: _GrowthChartsCard.formatMeasurement(
                    latest.headCircumference,
                  ),
                  unit: 'سم',
                  icon: Icons.circle_outlined,
                  accentColor: _GrowthChartsCard.headColor,
                  isSelected: _selectedFilter == _GrowthMetricFilter.head,
                  onTap: () => _toggleCardFilter(_GrowthMetricFilter.head),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Add New Measurement Button ──
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: widget.onAddNew,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(
                Icons.add_rounded,
                size: 20,
              ),
              label: const Text(
                'تسجيل قياس جديد',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Unified Combined Growth Chart ──
          _UnifiedGrowthChart(
            records: widget.records,
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
        ],
      ),
    );
  }
}

class _LatestValueCard extends StatelessWidget {
  const _LatestValueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.10)
              : AppColors.backgroundCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.65)
                : Colors.transparent,
            width: 1.3,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 19,
              color: accentColor,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.featureDesc.copyWith(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$value $unit',
              textDirection: TextDirection.rtl,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedGrowthChart extends StatelessWidget {
  const _UnifiedGrowthChart({
    required this.records,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final List<_GrowthRecordData> records;
  final _GrowthMetricFilter selectedFilter;
  final ValueChanged<_GrowthMetricFilter> onFilterChanged;

  String get _chartTitle {
    switch (selectedFilter) {
      case _GrowthMetricFilter.all:
        return 'منحنى تطور القياسات';
      case _GrowthMetricFilter.height:
        return 'تطور الطول';
      case _GrowthMetricFilter.weight:
        return 'تطور الوزن';
      case _GrowthMetricFilter.head:
        return 'تطور محيط الرأس';
    }
  }

  String _deltaSummary(List<double> values, String unit) {
    if (values.length < 2) {
      return 'قياس واحد مسجل حتى الآن';
    }
    final diff = values.last - values[values.length - 2];
    if (diff.abs() < 0.05) {
      return 'مستقر مقارنةً بالقياس السابق';
    }
    final sign = diff > 0 ? '+' : '';
    final formatted = diff == diff.roundToDouble()
        ? diff.toInt().toString()
        : diff.toStringAsFixed(1);
    return '$sign$formatted $unit عن القياس السابق';
  }

  @override
  Widget build(BuildContext context) {
    // Show up to the latest 6 measurements so the chart stays clean and legible
    final displayRecords =
        records.length > 6 ? records.sublist(records.length - 6) : records;

    final heights = displayRecords.map((r) => r.height).toList();
    final weights = displayRecords.map((r) => r.weight).toList();
    final heads = displayRecords.map((r) => r.headCircumference).toList();
    final dates = displayRecords.map((r) => r.createdAt).toList();

    List<double> singleValues = const [];
    String singleUnit = '';
    Color singleColor = _GrowthChartsCard.heightColor;

    if (selectedFilter == _GrowthMetricFilter.height) {
      singleValues = heights;
      singleUnit = 'سم';
      singleColor = _GrowthChartsCard.heightColor;
    } else if (selectedFilter == _GrowthMetricFilter.weight) {
      singleValues = weights;
      singleUnit = 'كجم';
      singleColor = _GrowthChartsCard.weightColor;
    } else if (selectedFilter == _GrowthMetricFilter.head) {
      singleValues = heads;
      singleUnit = 'سم';
      singleColor = _GrowthChartsCard.headColor;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Chart Title & Latest Badge (in single mode) ──
          Row(
            children: [
              Expanded(
                child: Text(
                  _chartTitle,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selectedFilter != _GrowthMetricFilter.all &&
                  singleValues.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: singleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_GrowthChartsCard.formatMeasurement(singleValues.last)} $singleUnit',
                    style: AppTextStyles.featureDesc.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: singleColor,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Segmented Filter Pills (الكل | الطول | الوزن | محيط الرأس) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MetricFilterChip(
                  label: 'الكل',
                  color: AppColors.primary,
                  isSelected: selectedFilter == _GrowthMetricFilter.all,
                  onTap: () => onFilterChanged(_GrowthMetricFilter.all),
                ),
                const SizedBox(width: 6),
                _MetricFilterChip(
                  label: 'الطول',
                  color: _GrowthChartsCard.heightColor,
                  dotColor: _GrowthChartsCard.heightColor,
                  isSelected: selectedFilter == _GrowthMetricFilter.height,
                  onTap: () => onFilterChanged(_GrowthMetricFilter.height),
                ),
                const SizedBox(width: 6),
                _MetricFilterChip(
                  label: 'الوزن',
                  color: _GrowthChartsCard.weightColor,
                  dotColor: _GrowthChartsCard.weightColor,
                  isSelected: selectedFilter == _GrowthMetricFilter.weight,
                  onTap: () => onFilterChanged(_GrowthMetricFilter.weight),
                ),
                const SizedBox(width: 6),
                _MetricFilterChip(
                  label: 'محيط الرأس',
                  color: _GrowthChartsCard.headColor,
                  dotColor: _GrowthChartsCard.headColor,
                  isSelected: selectedFilter == _GrowthMetricFilter.head,
                  onTap: () => onFilterChanged(_GrowthMetricFilter.head),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Legend (for 'all') or Delta Summary (for single metric) ──
          if (selectedFilter == _GrowthMetricFilter.all)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.cardSurface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _LegendItem(
                    label: 'الطول',
                    value:
                        '${_GrowthChartsCard.formatMeasurement(heights.last)} سم',
                    color: _GrowthChartsCard.heightColor,
                  ),
                  _LegendItem(
                    label: 'الوزن',
                    value:
                        '${_GrowthChartsCard.formatMeasurement(weights.last)} كجم',
                    color: _GrowthChartsCard.weightColor,
                  ),
                  _LegendItem(
                    label: 'محيط الرأس',
                    value:
                        '${_GrowthChartsCard.formatMeasurement(heads.last)} سم',
                    color: _GrowthChartsCard.headColor,
                  ),
                ],
              ),
            )
          else
            Text(
              _deltaSummary(singleValues, singleUnit),
              style: AppTextStyles.featureDesc.copyWith(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),

          const SizedBox(height: 14),

          // ── Unified Chart Canvas ──
          SizedBox(
            height: selectedFilter == _GrowthMetricFilter.all ? 250 : 195,
            width: double.infinity,
            child: CustomPaint(
              painter: selectedFilter == _GrowthMetricFilter.all
                  ? _CombinedThreeTrackChartPainter(
                      heights: heights,
                      weights: weights,
                      heads: heads,
                      dates: dates,
                    )
                  : _SingleMetricChartPainter(
                      values: singleValues,
                      dates: dates,
                      metricLabel: selectedFilter == _GrowthMetricFilter.height
                          ? 'الطول'
                          : selectedFilter == _GrowthMetricFilter.weight
                              ? 'الوزن'
                              : 'محيط الرأس',
                      unit: singleUnit,
                      lineColor: singleColor,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricFilterChip extends StatelessWidget {
  const _MetricFilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final Color color;
  final Color? dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? color : AppColors.borderBeige,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTextStyles.featureDesc.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: AppTextStyles.featureDesc.copyWith(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.cardTitle.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Combined 3-Track Chart Painter (Height, Weight & Head Circumference in 1 view)
// ─────────────────────────────────────────────────────────────────────────────

class _CombinedThreeTrackChartPainter extends CustomPainter {
  const _CombinedThreeTrackChartPainter({
    required this.heights,
    required this.weights,
    required this.heads,
    required this.dates,
  });

  final List<double> heights;
  final List<double> weights;
  final List<double> heads;
  final List<DateTime> dates;

  @override
  void paint(Canvas canvas, Size size) {
    if (dates.isEmpty) return;

    const rightLabelWidth = 68.0;
    const leftPad = 30.0;
    const rightPad = rightLabelWidth + 18.0;
    const bottomAxisArea = 42.0;
    const topHeaderHeight = 20.0;

    const plotLeft = leftPad;
    final plotRight = size.width - rightPad;
    final plotWidth = (plotRight - plotLeft).clamp(10.0, size.width);
    final plotBottom = size.height - bottomAxisArea;
    final totalTracksHeight = plotBottom - topHeaderHeight;
    final trackHeight = totalTracksHeight / 3.0;

    // ── Y-Axis Header Title (top right) ──
    _drawText(
      canvas,
      text: 'المؤشر (الوحدة)',
      center: Offset(size.width - rightLabelWidth / 2, topHeaderHeight / 2),
      style: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );

    final n = dates.length;

    // RTL chronological X-positions: oldest (index 0) on the RIGHT, newest on the LEFT
    final xPositions = List.generate(n, (i) {
      if (n == 1) return plotLeft + plotWidth / 2;
      return plotRight - (plotWidth * i / (n - 1));
    });

    // Vertical column guide lines + Date labels (with Year) at the bottom
    final vGuidePaint = Paint()
      ..color = AppColors.borderLight.withValues(alpha: 0.65)
      ..strokeWidth = 1;

    final axisLinePaint = Paint()
      ..color = AppColors.borderBeige
      ..strokeWidth = 1.2;

    for (int i = 0; i < n; i++) {
      final x = xPositions[i];
      canvas.drawLine(
        Offset(x, topHeaderHeight),
        Offset(x, plotBottom),
        vGuidePaint,
      );

      // Small X-axis tick mark
      canvas.drawLine(
        Offset(x, plotBottom),
        Offset(x, plotBottom + 4),
        axisLinePaint,
      );

      final dateStr = '${dates[i].day}/${dates[i].month}/${dates[i].year}';
      _drawLtrText(
        canvas,
        text: dateStr,
        center: Offset(x, plotBottom + 13),
        style: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
    }

    // Vertical Y-axis separator line (on the right of plot area)
    final yAxisX = size.width - rightLabelWidth - 2;
    canvas.drawLine(
      Offset(yAxisX, topHeaderHeight),
      Offset(yAxisX, plotBottom),
      axisLinePaint,
    );

    // Horizontal track dividers & X-axis baseline
    final hDividerPaint = Paint()
      ..color = AppColors.borderLight.withValues(alpha: 0.9)
      ..strokeWidth = 1;

    canvas.drawLine(
      const Offset(plotLeft - 12, topHeaderHeight),
      Offset(size.width - 2, topHeaderHeight),
      hDividerPaint,
    );

    for (int t = 1; t <= 3; t++) {
      final y = topHeaderHeight + trackHeight * t;
      canvas.drawLine(
        Offset(plotLeft - 12, y),
        Offset(size.width - 2, y),
        t == 3 ? axisLinePaint : hDividerPaint,
      );
    }

    // ── X-Axis Title (bottom center) ──
    _drawText(
      canvas,
      text: 'تاريخ القياس',
      center: Offset(plotLeft + plotWidth / 2, size.height - 7),
      style: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );

    // Draw each of the 3 tracks cleanly in its own horizontal lane
    _drawTrack(
      canvas: canvas,
      size: size,
      rightLabelWidth: rightLabelWidth,
      values: heights,
      xPositions: xPositions,
      trackTop: topHeaderHeight,
      trackHeight: trackHeight,
      color: _GrowthChartsCard.heightColor,
      label: 'الطول',
      unit: 'سم',
    );

    _drawTrack(
      canvas: canvas,
      size: size,
      rightLabelWidth: rightLabelWidth,
      values: weights,
      xPositions: xPositions,
      trackTop: topHeaderHeight + trackHeight,
      trackHeight: trackHeight,
      color: _GrowthChartsCard.weightColor,
      label: 'الوزن',
      unit: 'كجم',
    );

    _drawTrack(
      canvas: canvas,
      size: size,
      rightLabelWidth: rightLabelWidth,
      values: heads,
      xPositions: xPositions,
      trackTop: topHeaderHeight + trackHeight * 2,
      trackHeight: trackHeight,
      color: _GrowthChartsCard.headColor,
      label: 'محيط الرأس',
      unit: 'سم',
    );
  }

  void _drawTrack({
    required Canvas canvas,
    required Size size,
    required double rightLabelWidth,
    required List<double> values,
    required List<double> xPositions,
    required double trackTop,
    required double trackHeight,
    required Color color,
    required String label,
    required String unit,
  }) {
    if (values.isEmpty) return;

    // Right-side Y-axis track label + unit
    final labelCenterX = size.width - rightLabelWidth / 2;
    _drawText(
      canvas,
      text: label,
      center: Offset(labelCenterX, trackTop + trackHeight / 2 - 6),
      style: TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
    _drawText(
      canvas,
      text: '($unit)',
      center: Offset(labelCenterX, trackTop + trackHeight / 2 + 8),
      style: const TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 8.5,
        color: AppColors.textSecondary,
      ),
    );

    double minVal = values.first;
    double maxVal = values.first;
    for (final v in values) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }

    double range = maxVal - minVal;
    if (range == 0) {
      range = 1.0;
      minVal -= 0.5;
      maxVal += 0.5;
    }

    final usableTop = trackTop + 19.0;
    final usableBottom = trackTop + trackHeight - 10.0;
    final usableHeight = (usableBottom - usableTop).clamp(8.0, trackHeight);

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final norm = (values[i] - minVal) / (maxVal - minVal);
      final y = usableBottom - norm * usableHeight;
      points.add(Offset(xPositions[i], y));
    }

    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        linePath.lineTo(p.dx, p.dy);
      }

      final fillPath = Path.from(linePath)
        ..lineTo(points.last.dx, trackTop + trackHeight)
        ..lineTo(points.first.dx, trackTop + trackHeight)
        ..close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = color.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        linePath,
        Paint()
          ..color = color
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    final dotFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = AppColors.cardSurface
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 4.0, dotFill);
      canvas.drawCircle(pt, 4.0, dotBorder);

      // Value label right above each dot
      final valText = _GrowthChartsCard.formatMeasurement(values[i]);
      _drawValueBadge(
        canvas,
        text: valText,
        center: Offset(pt.dx, pt.dy - 11),
        color: color,
      );
    }
  }

  void _drawValueBadge(
    Canvas canvas, {
    required String text,
    required Offset center,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + 8,
      height: tp.height + 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = AppColors.cardSurface.withValues(alpha: 0.92),
    );
    tp.paint(
        canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Offset center,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(
        canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawLtrText(
    Canvas canvas, {
    required String text,
    required Offset center,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CombinedThreeTrackChartPainter oldDelegate) {
    return oldDelegate.heights != heights ||
        oldDelegate.weights != weights ||
        oldDelegate.heads != heads ||
        oldDelegate.dates != dates;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single Metric Detailed Chart Painter (Height OR Weight OR Head Circumference)
// ─────────────────────────────────────────────────────────────────────────────

class _SingleMetricChartPainter extends CustomPainter {
  const _SingleMetricChartPainter({
    required this.values,
    required this.dates,
    required this.metricLabel,
    required this.unit,
    required this.lineColor,
  });

  final List<double> values;
  final List<DateTime> dates;
  final String metricLabel;
  final String unit;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || dates.isEmpty) return;

    const leftPad = 30.0;
    const rightLabelWidth = 64.0;
    const rightPad = rightLabelWidth + 16.0;
    const topPad = 32.0;
    const bottomAxisArea = 42.0;

    const plotLeft = leftPad;
    final plotRight = size.width - rightPad;
    final plotWidth = (plotRight - plotLeft).clamp(10.0, size.width);
    final plotBottom = size.height - bottomAxisArea;
    final plotHeight = (plotBottom - topPad).clamp(10.0, size.height);

    // ── Y-Axis Header Title (top right) ──
    final yHeaderTp = TextPainter(
      text: TextSpan(
        text: '$metricLabel ($unit)',
        style: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: lineColor,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    yHeaderTp.paint(
      canvas,
      Offset(size.width - rightLabelWidth / 2 - yHeaderTp.width / 2, 4),
    );

    double minValue = values.first;
    double maxValue = values.first;
    for (final v in values) {
      if (v < minValue) minValue = v;
      if (v > maxValue) maxValue = v;
    }

    double range = maxValue - minValue;
    if (range == 0) {
      final delta =
          maxValue == 0 ? 1.0 : (maxValue.abs() * 0.1).clamp(1.0, 5.0);
      minValue -= delta;
      maxValue += delta;
    } else {
      final pad = range * 0.2;
      minValue -= pad;
      maxValue += pad;
    }
    final adjustedRange = maxValue - minValue;

    final gridPaint = Paint()
      ..color = AppColors.borderLight.withValues(alpha: 0.85)
      ..strokeWidth = 1;

    final axisLinePaint = Paint()
      ..color = AppColors.borderBeige
      ..strokeWidth = 1.2;

    // Vertical Y-axis line
    final yAxisX = size.width - rightLabelWidth - 2;
    canvas.drawLine(
      Offset(yAxisX, topPad),
      Offset(yAxisX, plotBottom),
      axisLinePaint,
    );

    // 3 horizontal gridlines + Y-axis labels (with unit) on the right
    for (int i = 0; i < 3; i++) {
      final frac = i / 2.0;
      final y = topPad + plotHeight * frac;
      final labelVal = maxValue - adjustedRange * frac;

      canvas.drawLine(
        Offset(plotLeft - 10, y),
        Offset(yAxisX, y),
        i == 2 ? axisLinePaint : gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${_GrowthChartsCard.formatMeasurement(labelVal)} $unit',
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          size.width - rightLabelWidth / 2 - tp.width / 2,
          y - tp.height / 2,
        ),
      );
    }

    final n = values.length;
    final points = <Offset>[];

    // RTL chronological X-positions: oldest on the RIGHT, newest on the LEFT
    for (int i = 0; i < n; i++) {
      final x = n == 1
          ? plotLeft + plotWidth / 2
          : plotRight - (plotWidth * i / (n - 1));
      final norm = (values[i] - minValue) / adjustedRange;
      final y = plotBottom - norm * plotHeight;
      points.add(Offset(x, y));

      // Small X-axis tick mark
      canvas.drawLine(
        Offset(x, plotBottom),
        Offset(x, plotBottom + 4),
        axisLinePaint,
      );

      // Date label with Year directly below each point
      final dateStr = '${dates[i].day}/${dates[i].month}/${dates[i].year}';
      final dateTp = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dateTp.paint(
        canvas,
        Offset(x - dateTp.width / 2, plotBottom + 6),
      );
    }

    // ── X-Axis Title (bottom center) ──
    final xTitleTp = TextPainter(
      text: const TextSpan(
        text: 'تاريخ القياس (يوم/شهر/سنة)',
        style: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    xTitleTp.paint(
      canvas,
      Offset(
        plotLeft + plotWidth / 2 - xTitleTp.width / 2,
        size.height - xTitleTp.height - 1,
      ),
    );

    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        linePath.lineTo(p.dx, p.dy);
      }

      final fillPath = Path.from(linePath)
        ..lineTo(points.last.dx, plotBottom)
        ..lineTo(points.first.dx, plotBottom)
        ..close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = lineColor.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    final dotFill = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = AppColors.cardSurface
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 4.5, dotFill);
      canvas.drawCircle(pt, 4.5, dotBorder);

      // Value badge above each point
      final valStr = '${_GrowthChartsCard.formatMeasurement(values[i])} $unit';
      final tp = TextPainter(
        text: TextSpan(
          text: valStr,
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: lineColor,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();

      final badgeCenter = Offset(pt.dx, pt.dy - 13);
      final rect = Rect.fromCenter(
        center: badgeCenter,
        width: tp.width + 8,
        height: tp.height + 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = AppColors.cardSurface.withValues(alpha: 0.92),
      );
      tp.paint(
        canvas,
        Offset(
          badgeCenter.dx - tp.width / 2,
          badgeCenter.dy - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SingleMetricChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.dates != dates ||
        oldDelegate.metricLabel != metricLabel ||
        oldDelegate.lineColor != lineColor;
  }
}

class _GrowthRecordData {
  const _GrowthRecordData({
    required this.recordId,
    required this.height,
    required this.weight,
    required this.headCircumference,
    required this.createdAt,
  });

  final String recordId;
  final double height;
  final double weight;
  final double headCircumference;
  final DateTime createdAt;
}

class _DevelopmentCard extends StatelessWidget {
  const _DevelopmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تتبّع الأشياء بصريًا',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'في هذا العمر يبدأ الطفل بتتبّع الأشياء المتحركة بعينيه والانتباه أكثر للوجوه والأصوات.',
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 11,
                    height: 1.7,
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 10.5,
                    height: 1.7,
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
