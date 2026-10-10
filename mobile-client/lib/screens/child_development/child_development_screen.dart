import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _headController.dispose();
    super.dispose();
  }

  void _saveMeasurements() {
    FocusScope.of(context).unfocus();

    final height = _heightController.text.trim();
    final weight = _weightController.text.trim();
    final head = _headController.text.trim();

    if (height.isEmpty || weight.isEmpty || head.isEmpty) {
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

    final wasAlreadySaved = _hasSavedMeasurements;

    setState(() {
      _hasSavedMeasurements = true;
      _isEditingMeasurements = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasAlreadySaved
              ? 'تم تعديل القياسات بنجاح'
              : 'تم حفظ القياسات بنجاح',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  void _editMeasurements() {
    setState(() {
      _isEditingMeasurements = true;
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PageHeader(),

                const SizedBox(height: 22),

                const _AgeCard(),

                const SizedBox(height: 16),

                _MeasurementsCard(
                  heightController: _heightController,
                  weightController: _weightController,
                  headController: _headController,
                  hasSavedMeasurements: _hasSavedMeasurements,
                  isEditing: _isEditingMeasurements,
                  onSave: _saveMeasurements,
                  onEdit: _editMeasurements,
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

// ── Header ────────────────────────────────────────────────────────

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

        const Spacer(),

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

// ── Age card ──────────────────────────────────────────────────────

class _AgeCard extends StatelessWidget {
  const _AgeCard();

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

                Text(
                  '3 أشهر',
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

// ── Measurements ──────────────────────────────────────────────────

class _MeasurementsCard extends StatelessWidget {
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController headController;

  final bool hasSavedMeasurements;
  final bool isEditing;

  final VoidCallback onSave;
  final VoidCallback onEdit;

  const _MeasurementsCard({
    required this.heightController,
    required this.weightController,
    required this.headController,
    required this.hasSavedMeasurements,
    required this.isEditing,
    required this.onSave,
    required this.onEdit,
  });

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
                      'تسجيل قياسات النمو',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasSavedMeasurements && !isEditing
                          ? 'آخر قياسات الطفل المحفوظة'
                          : 'أدخلي أحدث قياسات الطفل',
                      style: AppTextStyles.featureDesc.copyWith(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _MeasurementField(
            controller: heightController,
            label: 'الطول',
            hint: 'مثال: 60',
            unit: 'سم',
            icon: Icons.height_rounded,
            readOnly: !isEditing,
          ),

          const SizedBox(height: 12),

          _MeasurementField(
            controller: weightController,
            label: 'الوزن',
            hint: 'مثال: 5.8',
            unit: 'كجم',
            icon: Icons.monitor_weight_outlined,
            readOnly: !isEditing,
          ),

          const SizedBox(height: 12),

          _MeasurementField(
            controller: headController,
            label: 'محيط الرأس',
            hint: 'مثال: 40',
            unit: 'سم',
            icon: Icons.circle_outlined,
            readOnly: !isEditing,
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed:
                  hasSavedMeasurements && !isEditing
                      ? onEdit
                      : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                hasSavedMeasurements && !isEditing
                    ? 'تعديل القياسات'
                    : hasSavedMeasurements
                        ? 'حفظ التعديلات'
                        : 'حفظ القياسات',
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

class _MeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String unit;
  final IconData icon;
  final bool readOnly;

  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.unit,
    required this.icon,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
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

// ── Development milestone ─────────────────────────────────────────

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

// ── Activities ────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.description,
  });

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