import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';

/// Screen 06 — تسجيل بيانات الطفل (Infant Data Registration)
///
/// Collects: infant name, gender (dropdown), date of birth (date-picker).
/// On "حفظ ومتابعة" routes to [HomeScreen].
///
/// Schema fields:
///   - infantName  : String
///   - gender      : 'ذكر' | 'أنثى'
///   - dateOfBirth : DateTime
class InfantRegistrationScreen extends StatefulWidget {
  const InfantRegistrationScreen({super.key});

  @override
  State<InfantRegistrationScreen> createState() =>
      _InfantRegistrationScreenState();
}

class _InfantRegistrationScreenState extends State<InfantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedGender;
  DateTime? _dateOfBirth;
  bool _isLoading = false;

  static const List<String> _genderOptions = ['ذكر', 'أنثى'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Date-picker ────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      // Limit to plausible infant ages (0–3 years old)
      initialDate: _dateOfBirth ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 3)),
      lastDate: now,
      locale: const Locale('ar'),
      builder: (context, child) {
        // Wrap with the Mahd colour palette
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

    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  // ── Submit ─────────────────────────────────────────────────────
  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      _showError('يرجى اختيار تاريخ الميلاد');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // TODO: persist infant data to backend / local storage
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.alert,
      ),
    );
  }

  // ── Formatted date display ─────────────────────────────────────
  String get _formattedDate {
    if (_dateOfBirth == null) return 'اختر تاريخ الميلاد';
    final d = _dateOfBirth!;
    // Display as  DD/MM/YYYY  in LTR for readability
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 34),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Back button ──────────────────────────────
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _BackButton(onTap: () => Navigator.pop(context)),
                ),

                const SizedBox(height: 22),

                // ── Header ───────────────────────────────────
                Text('بيانات الطفل', style: AppTextStyles.screenTitle),
                const SizedBox(height: 4),
                Text(
                  'أضيفي معلومات طفلك للبدء مع مهد',
                  style: AppTextStyles.helperText,
                ),

                const SizedBox(height: 28),

                // ── Baby icon illustration ────────────────────
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.iconBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.child_care_rounded,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Infant Name ───────────────────────────────
                const _FieldLabel(label: 'اسم الطفل'),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameController,
                  style: AppTextStyles.bodyText,
                  decoration: const InputDecoration(
                    hintText: 'مثال: يوسف',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'اسم الطفل مطلوب' : null,
                ),

                const SizedBox(height: 16),

                // ── Gender Dropdown ───────────────────────────
                const _FieldLabel(label: 'الجنس'),
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
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g, style: AppTextStyles.bodyText),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                  validator: (v) =>
                      (v == null) ? 'يرجى اختيار الجنس' : null,
                  decoration: const InputDecoration(
                    // Override suffixIcon so arrow appears on the left in RTL
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // Match card styling
                  dropdownColor: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  icon: const SizedBox.shrink(), // hide default icon; we use suffix
                ),

                const SizedBox(height: 16),

                // ── Date of Birth (DatePicker) ─────────────────
                const _FieldLabel(label: 'تاريخ الميلاد'),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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

                const SizedBox(height: 36),

                // ── Save & Continue ───────────────────────────
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
//  Shared small widgets
// ────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: AppTextStyles.fieldLabel);
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
