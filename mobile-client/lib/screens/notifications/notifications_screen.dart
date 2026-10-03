import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _cryAlerts = true;
  bool _environmentAlerts = true;
  bool _connectionAlerts = true;
  bool _soundAndVibration = false;

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
                  'الإشعارات',
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'تصلك الإشعارات عند رصد الأحداث المهمة حتى لو كان التطبيق مغلقًا.',
              style: AppTextStyles.helperText.copyWith(
                fontSize: 11.5,
                height: 1.8,
              ),
            ),

            const SizedBox(height: 18),

            // ─────────────────────────────────────────────
            // Notification options card
            // ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D785037),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _NotificationRow(
                    title: 'تنبيهات البكاء',
                    subtitle:
                        'مع السبب المحتمل ودرجة الثقة',
                    value: _cryAlerts,
                    onChanged: (value) {
                      setState(() {
                        _cryAlerts = value;
                      });
                    },
                  ),

                  const _NotificationDivider(),

                  _NotificationRow(
                    title: 'تنبيهات البيئة',
                    subtitle:
                        'عند تغير الحرارة أو الرطوبة عن النطاق المناسب',
                    value: _environmentAlerts,
                    onChanged: (value) {
                      setState(() {
                        _environmentAlerts = value;
                      });
                    },
                  ),

                  const _NotificationDivider(),

                  _NotificationRow(
                    title: 'انقطاع الاتصال',
                    subtitle:
                        'تنبيه عند توقف اتصال جهاز مَهد',
                    value: _connectionAlerts,
                    onChanged: (value) {
                      setState(() {
                        _connectionAlerts = value;
                      });
                    },
                  ),

                  const _NotificationDivider(),

                  _NotificationRow(
                    title: 'النغمة والاهتزاز',
                    subtitle:
                        'تنبيه مسموع مع الإشعار',
                    value: _soundAndVibration,
                    onChanged: (value) {
                      setState(() {
                        _soundAndVibration = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─────────────────────────────────────────────
            // Information note
            // ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundBeige,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'ننصح بإبقاء تنبيهات البكاء وانقطاع الاتصال مفعّلة لمتابعة حالة الطفل.',
                      style: AppTextStyles.helperText.copyWith(
                        fontSize: 10.5,
                        height: 1.8,
                        color: AppColors.textHelper,
                      ),
                    ),
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
// Notification row
// ────────────────────────────────────────────────────────────────
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 10.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.borderBeige,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Divider
// ────────────────────────────────────────────────────────────────
class _NotificationDivider extends StatelessWidget {
  const _NotificationDivider();

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