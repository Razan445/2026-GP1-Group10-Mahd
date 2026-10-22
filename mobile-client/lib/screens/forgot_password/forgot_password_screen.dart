import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// نسيت كلمة المرور — sends a Firebase password-reset email.
///
/// Optionally receives the email typed on the login screen as a route
/// argument (String) to pre-fill the field.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int _resendSeconds = 45;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _sent = false;
  bool _prefilled = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_prefilled) {
      _prefilled = true;

      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is String) {
        _emailController.text = args;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();

    setState(() => _cooldown = _resendSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_cooldown <= 1) {
        timer.cancel();
      }

      setState(() => _cooldown = _cooldown - 1);
    });
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _sent = true;
      });

      _startCooldown();

      AppSnackBar.show(
        context,
        'تم إرسال رابط إعادة تعيين كلمة المرور',
        type: AppSnackBarType.success,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code} | ${e.message}');

      if (!mounted) return;

      setState(() => _isLoading = false);

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'لا يوجد حساب مسجل بهذا البريد الإلكتروني';
          break;
        case 'invalid-email':
          message = 'صيغة البريد الإلكتروني غير صحيحة';
          break;
        case 'too-many-requests':
          message = 'محاولات كثيرة، انتظري قليلًا ثم حاولي مرة أخرى';
          break;
        case 'network-request-failed':
          message = 'تعذر الاتصال بالشبكة، حاولي مرة أخرى';
          break;
        default:
          message = 'حدث خطأ أثناء إرسال الرابط';
      }

      AppSnackBar.show(context, message, type: AppSnackBarType.error);
    } catch (e) {
      debugPrint('Unexpected password reset error: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

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
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Image.asset(
                    'assets/images/mahd-logo.png',
                    width: 104,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _sent ? 'تحقق من بريدك الإلكتروني' : 'نسيت كلمة المرور؟',
                  style: AppTextStyles.screenTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  _sent
                      ? 'أرسلنا رابط إعادة تعيين كلمة المرور إلى بريدك. '
                          'افتحي الرسالة واضغطي على الرابط، وإذا لم تجديها '
                          'تفقدي مجلد الرسائل غير المرغوب فيها (Spam).'
                      : 'أدخلي بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور',
                  style: AppTextStyles.helperText.copyWith(height: 1.7),
                ),
                const SizedBox(height: 22),
                AppTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'example@gmail.com',
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
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _sent
                      ? (_cooldown > 0
                          ? 'إعادة الإرسال بعد $_cooldown ثانية'
                          : 'إعادة إرسال الرابط')
                      : 'إرسال الرابط',
                  onPressed: (_sent && _cooldown > 0) ? () {} : _send,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'العودة لتسجيل الدخول',
                      style: AppTextStyles.helperText.copyWith(
                        fontSize: 12.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
