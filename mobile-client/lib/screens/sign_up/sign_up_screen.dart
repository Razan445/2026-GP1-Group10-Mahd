import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_snack_bar.dart';

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('User was not created.');
      }

      final displayName = _nameController.text.trim();
      final email = _emailController.text.trim();

      await user.updateDisplayName(displayName);

      await FirestoreService.instance.createAccount(
        displayName: displayName,
        email: email,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      AppSnackBar.show(
        context,
        'تم إنشاء الحساب بنجاح!',
        type: AppSnackBarType.success,
      );

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.infantRegistration,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      debugPrint(
        'FirebaseAuthException: ${e.code} | ${e.message}',
      );

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'البريد الإلكتروني مستخدم مسبقًا';
          break;

        case 'invalid-email':
          message = 'صيغة البريد الإلكتروني غير صحيحة';
          break;

        case 'weak-password':
          message = 'كلمة المرور ضعيفة';
          break;

        case 'network-request-failed':
          message = 'تعذر الاتصال بالشبكة، حاولي مرة أخرى';
          break;

        default:
          message = 'حدث خطأ أثناء إنشاء الحساب';
      }

      AppSnackBar.show(
        context,
        message,
        type: AppSnackBarType.error,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      debugPrint(
        'FirebaseException: ${e.code} | ${e.message}',
      );

      AppSnackBar.show(
        context,
        'حدث خطأ أثناء حفظ بيانات الحساب',
        type: AppSnackBarType.error,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      debugPrint('Unexpected sign-up error: $e');

      AppSnackBar.show(
        context,
        'حدث خطأ غير متوقع، حاولي مرة أخرى',
        type: AppSnackBarType.error,
      );
    }
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
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _BackButton(
                    onTap: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'إنشاء حساب',
                  style: AppTextStyles.screenTitle,
                ),

                const SizedBox(height: 4),

                Text(
                  'أدخلي بياناتك للبدء مع مهد',
                  style: AppTextStyles.helperText,
                ),

                const SizedBox(height: 20),

                AppTextField(
                  label: 'الاسم الكامل',
                  hint: 'سارة العتيبي',
                  controller: _nameController,
                  validator: Validators.arabicFullName,
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
                  helperText:
                      '٨ أحرف على الأقل تشمل حرفًا كبيرًا وصغيرًا ورقمًا ورمزًا خاصًا',
                  validator: Validators.password,
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

                PrimaryButton(
                  label: 'إنشاء الحساب',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب؟ ',
                      style: AppTextStyles.helperText.copyWith(
                        fontSize: 12.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.login,
                      ),
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