import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/primary_button.dart';

/// Settings sub-screen — معلومات الطفل
///
/// Lets the user view and edit the child data that was entered
/// during registration (name, gender, date of birth).
class ChildInfoScreen extends StatefulWidget {
  const ChildInfoScreen({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<ChildInfoScreen> createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends State<ChildInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  static const List<String> _genderOptions = ['ذكر', 'أنثى'];

  String? _selectedGender;
  DateTime? _dateOfBirth;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadChild();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadChild() async {
    try {
      final snapshot = await FirestoreService.instance.watchAccount().first;
      final data = snapshot.data();

      if (data != null) {
        _nameController.text = (data['childName'] as String?) ?? '';

        final gender = data['childGender'] as String?;
        if (_genderOptions.contains(gender)) {
          _selectedGender = gender;
        }

        final dob = data['childDateOfBirth'];
        if (dob is Timestamp) {
          _dateOfBirth = dob.toDate();
        }
      }
    } catch (e) {
      debugPrint('Load child info error: $e');
    }

    if (!mounted) return;

    setState(() => _isLoading = false);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 3)),
      lastDate: now,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.backgroundCream,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() => _dateOfBirth = picked);
  }

  String get _formattedDate {
    final date = _dateOfBirth;

    if (date == null) return 'اختر تاريخ الميلاد';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      _showMessage('يرجى اختيار تاريخ الميلاد', AppColors.alert);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    try {
      await FirestoreService.instance.updateAccountProfile(
        childName: _nameController.text.trim(),
        childDateOfBirth: _dateOfBirth,
        childGender: _selectedGender,
      );

      if (!mounted) return;

      setState(() => _isSaving = false);

      _showMessage('تم حفظ معلومات الطفل', AppColors.success);
    } catch (e) {
      debugPrint('Child info save error: $e');

      if (!mounted) return;

      setState(() => _isSaving = false);

      _showMessage('حدث خطأ أثناء حفظ بيانات الطفل', AppColors.alert);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _BackButton(onTap: widget.onBack),
                  const Spacer(),
                  Text(
                    'معلومات الطفل',
                    style: AppTextStyles.screenTitle.copyWith(
                      fontSize: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else ...[
                Center(
                  child: Image.asset(
                    'assets/images/mahd-logo.png',
                    width: 90,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 24),

                Text('اسم الطفل', style: AppTextStyles.fieldLabel),

                const SizedBox(height: 4),

                TextFormField(
                  controller: _nameController,
                  style: AppTextStyles.bodyText,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'مثال: يوسف',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اسم الطفل مطلوب';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Text('الجنس', style: AppTextStyles.fieldLabel),

                const SizedBox(height: 4),

                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  hint: Text(
                    'اختر الجنس',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  items: _genderOptions
                      .map(
                        (gender) => DropdownMenuItem<String>(
                          value: gender,
                          child: Text(
                            gender,
                            style: AppTextStyles.bodyText,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedGender = value);
                  },
                  validator: (value) =>
                      value == null ? 'يرجى اختيار الجنس' : null,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  dropdownColor: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  icon: const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                Text('تاريخ الميلاد', style: AppTextStyles.fieldLabel),

                const SizedBox(height: 4),

                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formattedDate,
                          textDirection: TextDirection.ltr,
                          style: _dateOfBirth == null
                              ? AppTextStyles.bodyText.copyWith(
                                  color: AppColors.textSecondary,
                                )
                              : AppTextStyles.bodyText,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                PrimaryButton(
                  label: 'حفظ التغييرات',
                  onPressed: _save,
                  isLoading: _isSaving,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF4E8DE),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.chevron_right,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}
