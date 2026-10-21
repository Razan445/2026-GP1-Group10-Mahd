import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/primary_button.dart';

/// Shows the "check your email" box after the user requests an email change.
///
/// Returns `true` when the new email was confirmed and applied to the account.
Future<bool> showEmailVerificationDialog(
  BuildContext context, {
  required String newEmail,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (_) => _EmailVerificationDialog(newEmail: newEmail),
  );

  return result ?? false;
}

class _EmailVerificationDialog extends StatefulWidget {
  const _EmailVerificationDialog({required this.newEmail});

  final String newEmail;

  @override
  State<_EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<_EmailVerificationDialog> {
  static const int _resendSeconds = 45;

  bool _isChecking = false;
  bool _isResending = false;
  int _cooldown = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  Future<void> _confirm() async {
    setState(() => _isChecking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await user?.reload();

      final currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      if (currentEmail.toLowerCase() == widget.newEmail.toLowerCase()) {
        await FirestoreService.instance.syncEmailFromAuth();

        if (!mounted) return;

        Navigator.of(context).pop(true);
        return;
      }

      if (!mounted) return;

      setState(() => _isChecking = false);

      AppSnackBar.show(
        context,
        'لم يتم تأكيد البريد بعد، افتحي الرابط في رسالتك ثم اضغطي "تم التأكيد"',
        type: AppSnackBarType.error,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Email confirm error: ${e.code}');

      if (!mounted) return;

      // After the address changes Firebase may require signing in again.
      if (e.code == 'user-token-expired' || e.code == 'user-not-found') {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() => _isChecking = false);

      AppSnackBar.show(
        context,
        'تعذر التحقق، حاولي مرة أخرى',
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);

    try {
      await FirebaseAuth.instance.currentUser
          ?.verifyBeforeUpdateEmail(widget.newEmail);

      if (!mounted) return;

      setState(() => _isResending = false);

      _startCooldown();

      AppSnackBar.show(
        context,
        'تم إرسال رابط التأكيد مرة أخرى',
        type: AppSnackBarType.success,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Email resend error: ${e.code}');

      if (!mounted) return;

      setState(() => _isResending = false);

      AppSnackBar.show(
        context,
        e.code == 'too-many-requests'
            ? 'محاولات كثيرة، انتظري قليلًا ثم حاولي مرة أخرى'
            : 'تعذر إرسال الرابط، حاولي مرة أخرى',
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _cooldown <= 0 && !_isResending && !_isChecking;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'تحقق من بريدك الإلكتروني',
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
              ),

              const SizedBox(height: 8),

              Text(
                'أرسلنا رابط التأكيد إلى',
                textAlign: TextAlign.center,
                style: AppTextStyles.helperText.copyWith(fontSize: 12),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBeige,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderBeige),
                ),
                child: Text(
                  widget.newEmail,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'افتحي الرسالة واضغطي على الرابط، ثم ارجعي هنا واضغطي "تم التأكيد". '
                'إذا لم تجديها، تفقدي مجلد الرسائل غير المرغوب فيها (Spam).',
                textAlign: TextAlign.center,
                style: AppTextStyles.helperText.copyWith(
                  fontSize: 11.5,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 18),

              PrimaryButton(
                label: 'تم التأكيد',
                onPressed: _isChecking ? () {} : _confirm,
                isLoading: _isChecking,
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  _cooldown > 0
                      ? 'إعادة الإرسال بعد $_cooldown ثانية'
                      : 'إعادة إرسال الرابط',
                  style: AppTextStyles.helperText.copyWith(
                    color: canResend
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              TextButton(
                onPressed: _isChecking
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(
                  'لاحقًا',
                  style: AppTextStyles.helperText.copyWith(
                    color: AppColors.textSecondary,
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
