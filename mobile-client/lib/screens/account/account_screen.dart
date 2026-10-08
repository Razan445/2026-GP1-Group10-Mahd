import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_text_field.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(
    text: 'سارة العتيبي',
  );

  final _emailController = TextEditingController(
    text: 'sara@example.com',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    // TODO:
    // Save account information to Firebase later.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ التغييرات',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          30,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─────────────────────────────────────────────
              // Header
              // ─────────────────────────────────────────────
              Row(
                children: [
                  _BackButton(
                    onTap: widget.onBack,
                  ),

                  const Spacer(),

                  Text(
                    'الحساب',
                    style: AppTextStyles.screenTitle.copyWith(
                      fontSize: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ─────────────────────────────────────────────
              // Avatar
              // ─────────────────────────────────────────────
              Center(
                child: Container(
                  width: 74,
                  height: 74,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'س',
                    style: AppTextStyles.screenTitle.copyWith(
                      fontSize: 25,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ─────────────────────────────────────────────
              // Full name
              // ─────────────────────────────────────────────
              AppTextField(
                label: 'الاسم الكامل',
                controller: _nameController,
                hint: 'سارة العتيبي',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الاسم مطلوب';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // ─────────────────────────────────────────────
              // Email
              // ─────────────────────────────────────────────
              AppTextField(
                label: 'البريد الإلكتروني',
                controller: _emailController,
                hint: 'sara@example.com',
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'البريد الإلكتروني مطلوب';
                  }

                  final emailRegex = RegExp(
                    r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );

                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'صيغة البريد الإلكتروني غير صحيحة';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ─────────────────────────────────────────────
              // Change password
              // ─────────────────────────────────────────────
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'سيتم ربط تغيير كلمة المرور لاحقًا',
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  },
                  child: Ink(
                    height: 58,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'تغيير كلمة المرور',
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─────────────────────────────────────────────
              // Save button
              // ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  onPressed: _saveChanges,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.darkSurface,
                    foregroundColor: AppColors.darkSurfaceText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: Text(
                    'حفظ التغييرات',
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.darkSurfaceText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Back button
// ────────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.onTap,
  });

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