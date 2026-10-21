import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Visual flavour of an [AppSnackBar].
enum AppSnackBarType { success, error, info }

/// App-wide styled message (success / error / info).
///
/// Each type uses a soft tinted box with a matching border and icon,
/// while the text uses a dark shade of the same hue so it always has
/// strong contrast against the box background.
class AppSnackBar {
  AppSnackBar._();

  static const Color _successText = Color(0xFF3B5738);
  static const Color _errorText = Color(0xFF8A3524);
  static const Color _infoText = AppColors.textPrimary;

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    final Color background;
    final Color border;
    final Color accent;
    final Color textColor;
    final IconData icon;

    switch (type) {
      case AppSnackBarType.success:
        background = AppColors.successBg;
        border = AppColors.success.withValues(alpha: 0.45);
        accent = AppColors.success;
        textColor = _successText;
        icon = Icons.check_rounded;
        break;
      case AppSnackBarType.error:
        background = AppColors.alertBg;
        border = AppColors.alertBorder;
        accent = AppColors.alert;
        textColor = _errorText;
        icon = Icons.priority_high_rounded;
        break;
      case AppSnackBarType.info:
        background = AppColors.backgroundBeige;
        border = AppColors.borderBeige;
        accent = AppColors.primary;
        textColor = _infoText;
        icon = Icons.info_outline_rounded;
        break;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: EdgeInsets.zero,
          duration: const Duration(seconds: 3),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14785037),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        height: 1.5,
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
