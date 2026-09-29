import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// Screen 05 — تسجيل الدخول (Login Screen)
///
/// ⚠️  MOCK/BYPASS MODE: No backend is connected yet.
///     Pressing "دخول" bypasses authentication and navigates
///     directly to [HomeScreen] via [Navigator.pushReplacementNamed].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Bypass: navigates directly to Home ────────────────────────
  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulated network delay for realistic UX
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _isLoading = false);

    // MOCK: replace entire back-stack so user can't go "back" to login
    Navigator.pushReplacementNamed(context, AppRoutes.home);
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

                const SizedBox(height: 28),

                // ── Logo ────────────────────────────────────
                Center(
                  child: Image.asset(
                    'assets/images/mahd-logo.png',
                    width: 104,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 30),

                // ── Screen title ─────────────────────────────
                Text('تسجيل الدخول', style: AppTextStyles.screenTitle),
                const SizedBox(height: 4),
                Text('أهلًا بعودتك', style: AppTextStyles.helperText),

                const SizedBox(height: 24),

                // ── Email ────────────────────────────────────
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

                // ── Password ─────────────────────────────────
                AppTextField(
                  label: 'كلمة المرور',
                  hint: '••••••••',
                  isPassword: true,
                  controller: _passwordController,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                    return null;
                  },
                ),

                // ── Forgot password link ──────────────────────
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () {
                      // TODO: navigate to password-reset screen
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      'نسيت كلمة المرور؟',
                      style: AppTextStyles.helperText.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Login button (MOCK bypass) ────────────────
                PrimaryButton(
                  label: 'دخول',
                  onPressed: _onLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 20),

                // ── Sign-up link ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟ ',
                      style: AppTextStyles.helperText.copyWith(fontSize: 12.5),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, AppRoutes.signUp),
                      child: Text(
                        'إنشاء حساب',
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
//  Back button — beige pill with RTL-aware chevron
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
        // chevron_right shows as "forward" in RTL = back arrow
        child: const Icon(
          Icons.chevron_right,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}
