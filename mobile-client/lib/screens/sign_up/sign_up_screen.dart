import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// Screen 03 — إنشاء حساب (Sign-Up Screen)
///
/// Full registration form: Full Name, Email,
/// Password (with visibility toggle), Confirm Password,
/// plus a primary "إنشاء الحساب" button.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // TODO: integrate real auth before navigating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إنشاء الحساب بنجاح!'),
        backgroundColor: AppColors.success,
      ),
    );

    // New accounts continue to register their infant
    Navigator.pushReplacementNamed(context, AppRoutes.infantRegistration);
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
                // ── Back button ────────────────────────────────
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _BackButton(onTap: () => Navigator.pop(context)),
                ),

                const SizedBox(height: 18),

                // ── Screen title ───────────────────────────────
                Text('إنشاء حساب', style: AppTextStyles.screenTitle),
                const SizedBox(height: 4),
                Text(
                  'أدخلي بياناتك للبدء مع مهد',
                  style: AppTextStyles.helperText,
                ),

                const SizedBox(height: 20),

                // ── Form fields ────────────────────────────────
                AppTextField(
                  label: 'الاسم الكامل',
                  hint: 'سارة العتيبي',
                  controller: _nameController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),

                const SizedBox(height: 14),

                AppTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'sara@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'البريد الإلكتروني مطلوب';
                    }
                    final emailRegex =
                        RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'صيغة البريد الإلكتروني غير صحيحة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                AppTextField(
                  label: 'كلمة المرور',
                  hint: '••••••••',
                  isPassword: true,
                  controller: _passwordController,
                  helperText: '٨ أحرف على الأقل',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                    if (v.length < 8) {
                      return 'كلمة المرور يجب أن تكون ٨ أحرف على الأقل';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                AppTextField(
                  label: 'تأكيد كلمة المرور',
                  hint: '••••••••',
                  isPassword: true,
                  controller: _confirmController,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'تأكيد كلمة المرور مطلوب';
                    }
                    if (v != _passwordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Submit ────────────────────────────────────
                PrimaryButton(
                  label: 'إنشاء الحساب',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 12),

                // ── Login link ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب؟ ',
                      style: AppTextStyles.helperText
                          .copyWith(fontSize: 12.5),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                      child: Text(
                        'تسجيل الدخول',
                        style: AppTextStyles.helperText.copyWith(
                          fontSize: 12.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
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
  }
}

// ────────────────────────────────────────────────────────────────
//  Back button — beige pill with chevron
// ────────────────────────────────────────────────────────────────
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
