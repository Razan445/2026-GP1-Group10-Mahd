import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_snack_bar.dart';
import 'email_verification_dialog.dart';

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

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';

    try {
      await FirestoreService.instance.syncEmailFromAuth();
    } catch (e) {
      debugPrint('Email sync error: $e');
    }

    try {
      final snapshot = await FirestoreService.instance.watchAccount().first;
      final data = snapshot.data();

      if (data != null) {
        _nameController.text =
            (data['fullName'] as String?) ?? _nameController.text;
        _emailController.text =
            (data['email'] as String?) ?? _emailController.text;
      }
    } catch (e) {
      debugPrint('Load account error: $e');
    }

    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();

      final user = FirebaseAuth.instance.currentUser;
      final newEmail = _emailController.text.trim();
      final emailChanged =
          user != null && newEmail.toLowerCase() != (user.email ?? '').toLowerCase();

      await user?.updateDisplayName(name);
      await FirestoreService.instance.updateAccountProfile(fullName: name);

      if (emailChanged) {
        // Firebase requires the new address to be verified before the
        // account email actually changes.
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (emailChanged) {
        _emailController.text = user.email ?? '';

        final verified = await showEmailVerificationDialog(
          context,
          newEmail: newEmail,
        );

        if (!mounted) return;

        if (verified) {
          AppSnackBar.show(
            context,
            'تم تأكيد البريد الإلكتروني وحفظ التغييرات',
            type: AppSnackBarType.success,
          );
        } else {
          AppSnackBar.show(
            context,
            'تم حفظ التغييرات. سيبقى بريدك الحالي حتى تؤكدي البريد الجديد',
            type: AppSnackBarType.info,
          );
        }
      } else {
        AppSnackBar.show(
          context,
          'تم حفظ التغييرات',
          type: AppSnackBarType.success,
        );
      }

      widget.onBack();
    } on FirebaseAuthException catch (e) {
      debugPrint('Account save auth error: ${e.code}');

      if (!mounted) return;

      setState(() => _isSaving = false);

      String message;

      switch (e.code) {
        case 'requires-recent-login':
          message = 'لتغيير البريد الإلكتروني سجّلي الدخول مرة أخرى ثم أعيدي المحاولة';
          break;
        case 'email-already-in-use':
          message = 'البريد الإلكتروني مستخدم مسبقًا';
          break;
        case 'invalid-email':
          message = 'صيغة البريد الإلكتروني غير صحيحة';
          break;
        case 'network-request-failed':
          message = 'تعذر الاتصال بالشبكة، حاولي مرة أخرى';
          break;
        default:
          message = 'حدث خطأ أثناء حفظ التغييرات';
      }

      AppSnackBar.show(context, message, type: AppSnackBarType.error);
    } catch (e) {
      debugPrint('Account save error: $e');

      if (!mounted) return;

      setState(() => _isSaving = false);

      AppSnackBar.show(
        context,
        'حدث خطأ أثناء حفظ التغييرات',
        type: AppSnackBarType.error,
      );
    }
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
                    _nameController.text.isEmpty
                        ? '؟'
                        : _nameController.text.substring(0, 1).toUpperCase(),
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
                validator: Validators.arabicFullName,
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
                    AppSnackBar.show(
        context,
        'سيتم ربط تغيير كلمة المرور لاحقًا',
        type: AppSnackBarType.info,
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
                  onPressed: _isSaving ? null : _saveChanges,
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