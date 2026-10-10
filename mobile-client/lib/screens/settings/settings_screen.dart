import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../account/account_screen.dart';
import '../notifications/notifications_screen.dart';
import '../privacy_security/privacy_security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showAccountScreen = false;
  bool _showNotificationsScreen = false;
  bool _showPrivacySecurityScreen = false;

  void _openAccountScreen() {
    setState(() {
      _showAccountScreen = true;
    });
  }

  void _closeAccountScreen() {
    setState(() {
      _showAccountScreen = false;
    });
  }

  void _openNotificationsScreen() {
    setState(() {
      _showNotificationsScreen = true;
    });
  }

  void _closeNotificationsScreen() {
    setState(() {
      _showNotificationsScreen = false;
    });
  }

  void _openPrivacySecurityScreen() {
    setState(() {
      _showPrivacySecurityScreen = true;
    });
  }

  void _closePrivacySecurityScreen() {
    setState(() {
      _showPrivacySecurityScreen = false;
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.cardSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(
              22,
              24,
              22,
              0,
            ),
            contentPadding: const EdgeInsets.fromLTRB(
              22,
              10,
              22,
              0,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              18,
              20,
              18,
              18,
            ),
            title: Center(
              child: Text(
                'تسجيل الخروج؟',
                style: AppTextStyles.screenTitle.copyWith(
                  fontSize: 18,
                ),
              ),
            ),
            content: Text(
              'لن تصلك التنبيهات حتى تسجلي الدخول مرة أخرى.',
              textAlign: TextAlign.center,
              style: AppTextStyles.helperText.copyWith(
                fontSize: 11.5,
                height: 1.7,
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(
                          color: AppColors.borderBeige,
                          width: 1.2,
                        ),
                        minimumSize: const Size(
                          double.infinity,
                          48,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: AppTextStyles.buttonTextDark.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();

                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.alert,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(
                          double.infinity,
                          48,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'خروج',
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showAccountScreen) {
      return AccountScreen(
        onBack: _closeAccountScreen,
      );
    }

    if (_showNotificationsScreen) {
      return NotificationsScreen(
        onBack: _closeNotificationsScreen,
      );
    }

    if (_showPrivacySecurityScreen) {
      return PrivacySecurityScreen(
        onBack: _closePrivacySecurityScreen,
      );
    }

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
            // Screen title
            // ─────────────────────────────────────────────
            Text(
              'الإعدادات',
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────────
            // User profile card
            // ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D785037),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.iconBg,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      'س',
                      style: AppTextStyles.screenTitle.copyWith(
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Name + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سارة العتيبي',
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'sara@example.com',
                          textDirection: TextDirection.ltr,
                          style: AppTextStyles.featureDesc.copyWith(
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Edit button
                  OutlinedButton(
                    onPressed: _openAccountScreen,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(
                        color: AppColors.borderBeige,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'تعديل',
                      style: AppTextStyles.helperText.copyWith(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ─────────────────────────────────────────────
            // Settings options group
            // ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08785037),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'الإشعارات',
                    showArrow: true,
                    onTap: _openNotificationsScreen,
                  ),

                  const _SettingsDivider(),

                  _SettingsRow(
                    icon: Icons.shield_outlined,
                    title: 'الخصوصية والأمان',
                    showArrow: true,
                    onTap: _openPrivacySecurityScreen,
                  ),

                  const _SettingsDivider(),

                  _SettingsRow(
                    icon: Icons.language_rounded,
                    title: 'اللغة',
                    trailingText: 'العربية',
                    onTap: () {},
                  ),

                  const _SettingsDivider(),

                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'عن مَهد',
                    trailingText: 'الإصدار 1.0',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ─────────────────────────────────────────────
            // Logout button
            // ─────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.alert,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(
                    color: AppColors.alertBorder,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'تسجيل الخروج',
                  style: AppTextStyles.buttonTextDark.copyWith(
                    color: AppColors.alert,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────────
            // Footer
            // ─────────────────────────────────────────────
            Center(
              child: Text(
                'مَهد',
                style: AppTextStyles.helperText.copyWith(
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Settings row
// ────────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.showArrow = false,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final bool showArrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: AppColors.primary,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              if (trailingText != null)
                Text(
                  trailingText!,
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 10.5,
                  ),
                ),

              if (showArrow) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_left_rounded,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Divider between rows
// ────────────────────────────────────────────────────────────────

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.8,
      indent: 16,
      endIndent: 16,
      color: AppColors.borderMedium,
    );
  }
}