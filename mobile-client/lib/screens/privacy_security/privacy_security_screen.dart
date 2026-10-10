import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<PrivacySecurityScreen> createState() =>
      _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState
    extends State<PrivacySecurityScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          28,
        ),
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
                  'الخصوصية والأمان',
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ─────────────────────────────────────────────
            // Main privacy card
            // ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20,
              ),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.cardSurface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 25,
                      color: AppColors.success,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'صوت بيتك يبقى في بيتك',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'يُحلل الصوت داخل جهاز مَهد ولا يُرفع أي تسجيل صوتي إلى أي خادم.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.helperText.copyWith(
                      fontSize: 10.5,
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─────────────────────────────────────────────
            // Privacy points
            // ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08785037),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _PrivacyCheckRow(
                    text:
                        'لا يُحفظ أي تسجيل صوتي على الجهاز أو بعد انتهاء الجلسة',
                  ),

                  _Divider(),

                  _PrivacyCheckRow(
                    text:
                        'تُرسل النتائج وأوقاتها فقط إلى تطبيقك',
                  ),

                  _Divider(),

                  _PrivacyCheckRow(
                    text:
                        'بياناتك مرتبطة بحسابك وحده والاتصال مشفّر',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─────────────────────────────────────────────
            // Session settings
            // ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08785037),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _SessionRow(
                    title:
                        'إنهاء الجلسة تلقائيًا عند عدم الاستخدام',
                    value: 'مُفعّل',
                  ),

                  _Divider(),

                  _SessionRow(
                    title: 'الأجهزة المسجلة الدخول',
                    value: 'جهاز واحد',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Privacy checklist row
// ────────────────────────────────────────────────────────────────

class _PrivacyCheckRow extends StatelessWidget {
  const _PrivacyCheckRow({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 17,
            color: AppColors.success,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyText.copyWith(
                fontSize: 10.5,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Session row
// ────────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Text(
            value,
            style: AppTextStyles.helperText.copyWith(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Divider
// ────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.7,
      color: AppColors.borderMedium,
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