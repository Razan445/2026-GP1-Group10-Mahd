import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';

class ChildDevelopmentScreen extends StatefulWidget {
  const ChildDevelopmentScreen({super.key});

  @override
  State<ChildDevelopmentScreen> createState() =>
      _ChildDevelopmentScreenState();
}

class _ChildDevelopmentScreenState
    extends State<ChildDevelopmentScreen> {
  final TextEditingController _heightController =
      TextEditingController();

  final TextEditingController _weightController =
      TextEditingController();

  final TextEditingController _headController =
      TextEditingController();

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
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(
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
    _accountSubscription =
        FirestoreService.instance.watchAccount().listen(
      (snapshot) {
        final data = snapshot.data();
        final birthDateValue =
            data?['childDateOfBirth'];

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

          final height =
              _numberToDouble(data['height']);

          final weight =
              _numberToDouble(data['weight']);

          final headCircumference =
              _numberToDouble(
            data['headCircumference'],
          );

          if (height == null ||
              weight == null ||
              headCircumference == null) {
            continue;
          }

          final createdAtValue =
              data['createdAt'];

          final createdAt =
              createdAtValue is Timestamp
                  ? createdAtValue.toDate()
                  : DateTime.now();

          records.add(
            _GrowthRecordData(
              recordId: document.id,
              height: height,
              weight: weight,
              headCircumference:
                  headCircumference,
              createdAt: createdAt,
            ),
          );
        }

        records.sort(
          (a, b) =>
              a.createdAt.compareTo(b.createdAt),
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
            _growthRecordId =
                latestRecord.recordId;

            _heightController.text =
                _numberToText(
              latestRecord.height,
            );

            _weightController.text =
                _numberToText(
              latestRecord.weight,
            );

            _headController.text =
                _numberToText(
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

    final heightText =
        _heightController.text
            .trim()
            .replaceAll(',', '.');

    final weightText =
        _weightController.text
            .trim()
            .replaceAll(',', '.');

    final headText =
        _headController.text
            .trim()
            .replaceAll(',', '.');

    if (heightText.isEmpty ||
        weightText.isEmpty ||
        headText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'فضلاً أدخلي جميع القياسات',
            textDirection: TextDirection.rtl,
          ),
        ),
      );

      return;
    }

    final height =
        double.tryParse(heightText);

    final weight =
        double.tryParse(weightText);

    final headCircumference =
        double.tryParse(headText);

    if (height == null ||
        weight == null ||
        headCircumference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'فضلاً أدخلي قياسات صحيحة',
            textDirection: TextDirection.rtl,
          ),
        ),
      );

      return;
    }

    final isNewMeasurement =
        _isAddingNewMeasurement ||
        _growthRecordId == null;

    try {
      if (isNewMeasurement) {
        _growthRecordId =
            await FirestoreService.instance
                .createGrowthRecord(
          height: height,
          weight: weight,
          headCircumference:
              headCircumference,
        );
      } else {
        await FirestoreService.instance
            .updateGrowthRecord(
          recordId: _growthRecordId!,
          height: height,
          weight: weight,
          headCircumference:
              headCircumference,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNewMeasurement
                ? 'تم تسجيل القياس الجديد بنجاح'
                : 'تم تعديل القياسات بنجاح',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor:
              AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint(
        'Growth record save error: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء حفظ القياسات',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor:
              AppColors.alert,
        ),
      );
    }
  }

  void _editMeasurements() {
    if (_growthRecords.isEmpty) {
      return;
    }

    final latest =
        _growthRecords.last;

    _growthRecordId =
        latest.recordId;

    _heightController.text =
        _numberToText(latest.height);

    _weightController.text =
        _numberToText(latest.weight);

    _headController.text =
        _numberToText(
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

    final latest =
        _growthRecords.last;

    _growthRecordId =
        latest.recordId;

    _heightController.text =
        _numberToText(latest.height);

    _weightController.text =
        _numberToText(latest.weight);

    _headController.text =
        _numberToText(
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
        backgroundColor:
            AppColors.backgroundCream,
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              28,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const _PageHeader(),

                const SizedBox(height: 22),

                _AgeCard(
                  ageText: _childAgeText,
                  isLoading: _isAgeLoading,
                ),

                const SizedBox(height: 16),

                if (!_hasSavedMeasurements ||
                    _isEditingMeasurements)
                  _MeasurementsFormCard(
                    heightController:
                        _heightController,
                    weightController:
                        _weightController,
                    headController:
                        _headController,
                    hasSavedMeasurements:
                        _hasSavedMeasurements,
                    isAddingNewMeasurement:
                        _isAddingNewMeasurement,
                    onSave:
                        _saveMeasurements,
                    onCancel:
                        _cancelMeasurementForm,
                  )
                else
                  _GrowthChartsCard(
                    records: _growthRecords,
                    onEdit:
                        _editMeasurements,
                    onAddNew:
                        _addNewMeasurement,
                  ),

                const SizedBox(height: 22),

                Text(
                  'التطور في هذا العمر',
                  style:
                      AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                const _DevelopmentCard(),

                const SizedBox(height: 22),

                Text(
                  'أنشطة مناسبة لعمر الطفل',
                  style:
                      AppTextStyles.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                const _ActivityCard(
                  icon:
                      Icons.visibility_outlined,
                  title: 'تتبّع الأشياء',
                  description:
                      'حرّكي لعبة ملونة ببطء أمام الطفل لمساعدته على تتبعها بعينيه.',
                ),

                const SizedBox(height: 12),

                const _ActivityCard(
                  icon: Icons
                      .record_voice_over_outlined,
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
            borderRadius:
                BorderRadius.circular(14),
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
          'نمو الطفل',
          style:
              AppTextStyles.cardTitle.copyWith(
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
        borderRadius:
            BorderRadius.circular(24),
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
              borderRadius:
                  BorderRadius.circular(16),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'عمر الطفل الحالي',
                  style: AppTextStyles
                      .featureDesc
                      .copyWith(
                    fontSize: 11,
                    color:
                        AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          AppColors.primary,
                    ),
                  )
                else
                  Text(
                    ageText,
                    style: AppTextStyles
                        .cardTitle
                        .copyWith(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
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

class _MeasurementsFormCard
    extends StatelessWidget {
  const _MeasurementsFormCard({
    required this.heightController,
    required this.weightController,
    required this.headController,
    required this.hasSavedMeasurements,
    required this.isAddingNewMeasurement,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController
      heightController;

  final TextEditingController
      weightController;

  final TextEditingController
      headController;

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
      subtitle =
          'أدخلي القياسات الحالية لإضافتها إلى سجل النمو';
      buttonLabel = 'حفظ القياس الجديد';
    } else {
      title = 'تعديل قياسات النمو';
      subtitle =
          'عدّلي آخر قياسات محفوظة ثم احفظي التغييرات';
      buttonLabel = 'حفظ التعديلات';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D785037),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius:
                      BorderRadius.circular(
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles
                          .cardTitle
                          .copyWith(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: AppTextStyles
                          .featureDesc
                          .copyWith(
                        fontSize: 10.5,
                        color: AppColors
                            .textSecondary,
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
            icon:
                Icons.monitor_weight_outlined,
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
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily:
                      'IBMPlexSansArabic',
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
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
          borderRadius:
              BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(
                0xFFF4E8DE,
              ),
              borderRadius:
                  BorderRadius.circular(
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

class _MeasurementField
    extends StatelessWidget {
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
      keyboardType:
          const TextInputType
              .numberWithOptions(
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
        labelStyle:
            AppTextStyles.featureDesc.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
        hintStyle:
            AppTextStyles.featureDesc.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
        suffixStyle:
            AppTextStyles.featureDesc.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
        filled: true,
        fillColor:
            AppColors.backgroundCream,
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _GrowthChartsCard extends StatelessWidget {
  const _GrowthChartsCard({
    required this.records,
    required this.onEdit,
    required this.onAddNew,
  });

  final List<_GrowthRecordData> records;
  final VoidCallback onEdit;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final latest = records.last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D785037),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قياسات النمو',
                      style: AppTextStyles
                          .cardTitle
                          .copyWith(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'آخر القياسات المحفوظة وتطورها',
                      style: AppTextStyles
                          .featureDesc
                          .copyWith(
                        fontSize: 10.5,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'تعديل آخر قياس',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _LatestValueCard(
                  label: 'الطول',
                  value:
                      _formatMeasurement(
                    latest.height,
                  ),
                  unit: 'سم',
                  icon:
                      Icons.height_rounded,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _LatestValueCard(
                  label: 'الوزن',
                  value:
                      _formatMeasurement(
                    latest.weight,
                  ),
                  unit: 'كجم',
                  icon: Icons
                      .monitor_weight_outlined,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _LatestValueCard(
                  label: 'محيط الرأس',
                  value:
                      _formatMeasurement(
                    latest
                        .headCircumference,
                  ),
                  unit: 'سم',
                  icon:
                      Icons.circle_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onAddNew,
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                  width: 1.2,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.add_rounded,
                size: 20,
              ),
              label: const Text(
                'تسجيل قياس جديد',
                style: TextStyle(
                  fontFamily:
                      'IBMPlexSansArabic',
                  fontSize: 12.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          _GrowthTrendChart(
            title: 'تطور الطول',
            unit: 'سم',
            values: records
                .map(
                  (record) =>
                      record.height,
                )
                .toList(),
            dates: records
                .map(
                  (record) =>
                      record.createdAt,
                )
                .toList(),
          ),

          const SizedBox(height: 18),

          _GrowthTrendChart(
            title: 'تطور الوزن',
            unit: 'كجم',
            values: records
                .map(
                  (record) =>
                      record.weight,
                )
                .toList(),
            dates: records
                .map(
                  (record) =>
                      record.createdAt,
                )
                .toList(),
          ),

          const SizedBox(height: 18),

          _GrowthTrendChart(
            title: 'تطور محيط الرأس',
            unit: 'سم',
            values: records
                .map(
                  (record) => record
                      .headCircumference,
                )
                .toList(),
            dates: records
                .map(
                  (record) =>
                      record.createdAt,
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static String _formatMeasurement(
    double value,
  ) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class _LatestValueCard
    extends StatelessWidget {
  const _LatestValueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 19,
            color: AppColors.primary,
          ),

          const SizedBox(height: 6),

          Text(
            label,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                AppTextStyles.featureDesc.copyWith(
              fontSize: 9.5,
              color:
                  AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '$value $unit',
            textDirection:
                TextDirection.rtl,
            style:
                AppTextStyles.cardTitle.copyWith(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthTrendChart
    extends StatelessWidget {
  const _GrowthTrendChart({
    required this.title,
    required this.unit,
    required this.values,
    required this.dates,
  });

  final String title;
  final String unit;
  final List<double> values;
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    final latestValue =
        values.isEmpty ? 0.0 : values.last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles
                      .cardTitle
                      .copyWith(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '${_formatValue(latestValue)} $unit',
                style: AppTextStyles
                    .featureDesc
                    .copyWith(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter:
                  _GrowthLineChartPainter(
                values: values,
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (dates.isNotEmpty)
            _ChartDateLabels(
              dates: dates,
            ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class _ChartDateLabels
    extends StatelessWidget {
  const _ChartDateLabels({
    required this.dates,
  });

  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    if (dates.length == 1) {
      return Center(
        child: Text(
          _formatDate(dates.first),
          style:
              AppTextStyles.featureDesc.copyWith(
            fontSize: 9,
            color:
                AppColors.textSecondary,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDate(dates.first),
          style:
              AppTextStyles.featureDesc.copyWith(
            fontSize: 9,
            color:
                AppColors.textSecondary,
          ),
        ),

        Text(
          _formatDate(dates.last),
          style:
              AppTextStyles.featureDesc.copyWith(
            fontSize: 9,
            color:
                AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

class _GrowthLineChartPainter
    extends CustomPainter {
  const _GrowthLineChartPainter({
    required this.values,
  });

  final List<double> values;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (values.isEmpty) {
      return;
    }

    const horizontalPadding = 10.0;
    const verticalPadding = 10.0;

    final chartWidth =
        size.width - horizontalPadding * 2;

    final chartHeight =
        size.height - verticalPadding * 2;

    double minValue = values.first;
    double maxValue = values.first;

    for (final value in values) {
      if (value < minValue) {
        minValue = value;
      }

      if (value > maxValue) {
        maxValue = value;
      }
    }

    double range =
        maxValue - minValue;

    if (range == 0) {
      range = maxValue == 0
          ? 1.0
          : maxValue.abs() * 0.2;

      if (range == 0) {
        range = 1.0;
      }

      minValue -= range / 2;
      maxValue += range / 2;
    } else {
      final padding =
          range * 0.2;

      minValue -= padding;
      maxValue += padding;
    }

    final adjustedRange =
        maxValue - minValue;

    final gridPaint = Paint()
      ..color = AppColors.borderLight
          .withValues(alpha: 0.8)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y =
          verticalPadding +
          (chartHeight / 3) * i;

      canvas.drawLine(
        Offset(
          horizontalPadding,
          y,
        ),
        Offset(
          size.width -
              horizontalPadding,
          y,
        ),
        gridPaint,
      );
    }

    final points = <Offset>[];

    for (int index = 0;
        index < values.length;
        index++) {
      final x = values.length == 1
          ? size.width / 2
          : horizontalPadding +
              chartWidth *
                  index /
                  (values.length - 1);

      final normalized =
          (values[index] - minValue) /
              adjustedRange;

      final y =
          verticalPadding +
          chartHeight *
              (1 - normalized);

      points.add(
        Offset(x, y),
      );
    }

    if (points.length > 1) {
      final linePath = Path()
        ..moveTo(
          points.first.dx,
          points.first.dy,
        );

      for (final point
          in points.skip(1)) {
        linePath.lineTo(
          point.dx,
          point.dy,
        );
      }

      final fillPath =
          Path.from(linePath)
            ..lineTo(
              points.last.dx,
              size.height -
                  verticalPadding,
            )
            ..lineTo(
              points.first.dx,
              size.height -
                  verticalPadding,
            )
            ..close();

      final fillPaint = Paint()
        ..color = AppColors.primary
            .withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;

      canvas.drawPath(
        fillPath,
        fillPaint,
      );

      final linePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5
        ..strokeCap =
            StrokeCap.round
        ..strokeJoin =
            StrokeJoin.round
        ..style =
            PaintingStyle.stroke;

      canvas.drawPath(
        linePath,
        linePaint,
      );
    }

    final pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = AppColors.cardSurface
      ..strokeWidth = 2
      ..style =
          PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawCircle(
        point,
        4.5,
        pointPaint,
      );

      canvas.drawCircle(
        point,
        4.5,
        pointBorderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _GrowthLineChartPainter oldDelegate,
  ) {
    if (oldDelegate.values.length !=
        values.length) {
      return true;
    }

    for (int i = 0;
        i < values.length;
        i++) {
      if (oldDelegate.values[i] !=
          values[i]) {
        return true;
      }
    }

    return false;
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

class _DevelopmentCard
    extends StatelessWidget {
  const _DevelopmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons
                  .psychology_alt_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'تتبّع الأشياء بصريًا',
                  style: AppTextStyles
                      .cardTitle
                      .copyWith(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'في هذا العمر يبدأ الطفل بتتبّع الأشياء المتحركة بعينيه والانتباه أكثر للوجوه والأصوات.',
                  style: AppTextStyles
                      .featureDesc
                      .copyWith(
                    fontSize: 11,
                    height: 1.7,
                    color: AppColors
                        .textSecondary,
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

class _ActivityCard
    extends StatelessWidget {
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
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius:
                  BorderRadius.circular(14),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles
                      .cardTitle
                      .copyWith(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: AppTextStyles
                      .featureDesc
                      .copyWith(
                    fontSize: 10.5,
                    height: 1.7,
                    color: AppColors
                        .textSecondary,
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