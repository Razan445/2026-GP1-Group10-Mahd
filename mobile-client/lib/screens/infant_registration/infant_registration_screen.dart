import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/primary_button.dart';

/// Screen 06 — تسجيل بيانات الطفل (Infant Data Registration)
///
/// Collects:
///  • Child name
///  • Gender
///  • Date of birth
///
/// Saves the data to the current account document in Firestore,
/// then routes to [HomeScreen].
class InfantRegistrationScreen extends StatefulWidget {
  const InfantRegistrationScreen({super.key});

  @override
  State<InfantRegistrationScreen> createState() =>
      _InfantRegistrationScreenState();
}

class _InfantRegistrationScreenState
    extends State<InfantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  String? _selectedGender;
  DateTime? _dateOfBirth;

  bool _isLoading = false;

  static const List<String> _genderOptions = [
    'ذكر',
    'أنثى',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Date picker
  // ─────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? now,
      firstDate: now.subtract(
        const Duration(
          days: 365 * 3,
        ),
      ),
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

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _dateOfBirth = picked;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Save child data to Firestore
  // ─────────────────────────────────────────────────────────────
  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateOfBirth == null) {
      _showError(
        'يرجى اختيار تاريخ الميلاد',
      );
      return;
    }

    if (_selectedGender == null) {
      _showError(
        'يرجى اختيار الجنس',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await FirestoreService.instance.updateAccountProfile(
        childName: _nameController.text.trim(),
        childDateOfBirth: _dateOfBirth,
        childGender: _selectedGender,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
      );
    } catch (e) {
      debugPrint(
        'Infant registration save error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        'حدث خطأ أثناء حفظ بيانات الطفل',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: AppColors.alert,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Formatted date
  // ─────────────────────────────────────────────────────────────
  String get _formattedDate {
    if (_dateOfBirth == null) {
      return 'اختر تاريخ الميلاد';
    }

    final date = _dateOfBirth!;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            26,
            8,
            26,
            34,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // No back button: the account was already created.
                const SizedBox(height: 22),

                // ─────────────────────────────────────
                // Header
                // ─────────────────────────────────────
                Text(
                  'بيانات الطفل',
                  style: AppTextStyles.screenTitle,
                ),

                const SizedBox(height: 4),

                Text(
                  'أضيفي معلومات طفلك للبدء مع مهد',
                  style: AppTextStyles.helperText,
                ),

                const SizedBox(height: 28),

                // ─────────────────────────────────────
                // Baby illustration
                // ─────────────────────────────────────
                Center(
                  child: Image.asset(
                    'assets/images/mahd-logo.png',
                    width: 104,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 28),

                // ─────────────────────────────────────
                // Child name
                // ─────────────────────────────────────
                const _FieldLabel(
                  label: 'اسم الطفل',
                ),

                const SizedBox(height: 4),

                TextFormField(
                  controller: _nameController,
                  style: AppTextStyles.bodyText,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'مثال: يوسف',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'اسم الطفل مطلوب';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────
                // Gender
                // ─────────────────────────────────────
                const _FieldLabel(
                  label: 'الجنس',
                ),

                const SizedBox(height: 4),

                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  hint: Text(
                    'اختر الجنس',
                    style:
                        AppTextStyles.bodyText.copyWith(
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                  items: _genderOptions
                      .map(
                        (gender) =>
                            DropdownMenuItem<String>(
                          value: gender,
                          child: Text(
                            gender,
                            style:
                                AppTextStyles.bodyText,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'يرجى اختيار الجنس';
                    }

                    return null;
                  },
                  decoration:
                      const InputDecoration(
                    suffixIcon: Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                  dropdownColor:
                      AppColors.cardSurface,
                  borderRadius:
                      BorderRadius.circular(16),
                  icon: const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────
                // Date of birth
                // ─────────────────────────────────────
                const _FieldLabel(
                  label: 'تاريخ الميلاد',
                ),

                const SizedBox(height: 4),

                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .calendar_today_outlined,
                          size: 18,
                          color:
                              AppColors.textSecondary,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          _formattedDate,
                          textDirection:
                              TextDirection.ltr,
                          style: _dateOfBirth == null
                              ? AppTextStyles
                                  .bodyText
                                  .copyWith(
                                  color: AppColors
                                      .textSecondary,
                                )
                              : AppTextStyles
                                  .bodyText,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ─────────────────────────────────────
                // Save and continue
                // ─────────────────────────────────────
                PrimaryButton(
                  label: 'حفظ ومتابعة',
                  onPressed: _onSave,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Field label
// ────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.fieldLabel,
    );
  }
}
