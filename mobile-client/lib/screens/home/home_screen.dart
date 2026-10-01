import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Screen 07 — الرئيسية (Home Screen)
///
/// Current state: **Idle** — monitoring is not active.
///
/// Layout:
///  • Top bar  : logo + notification bell
///  • Greeting : "مساء الخير، سارة"
///  • Center   : Idle monitoring card (mic icon, status text, start button)
///  • Stats    : 3 small quick-stat tiles
///  • Bottom   : [_MahdBottomNav] with 4 tabs
///
/// Navigation between tabs swaps the body content while keeping
/// the BottomNavigationBar alive (IndexedStack).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Greeting based on time-of-day
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 18) return 'مساء الخير';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      // ── Tab body ─────────────────────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(greeting: _greeting),
          const _PlaceholderTab(
            icon: Icons.history_rounded,
            label: 'السجل',
            subtitle: 'سيظهر هنا سجل جميع الأحداث المرصودة',
          ),
          const _PlaceholderTab(
            icon: Icons.bar_chart_rounded,
            label: 'التقارير',
            subtitle: 'تقارير تفصيلية عن نوم وبكاء طفلك',
          ),
          const _PlaceholderTab(
            icon: Icons.settings_outlined,
            label: 'الإعدادات',
            subtitle: 'إعدادات الحساب والتنبيهات والجهاز',
          ),
        ],
      ),
      // ── Bottom nav ───────────────────────────────────────────
      bottomNavigationBar: _MahdBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Home tab — الرئيسية
// ────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.greeting});
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top bar ──────────────────────────────────────
            _TopBar(),

            const SizedBox(height: 6),

            // ── Greeting ─────────────────────────────────────
            Text(
              '$greeting، سارة',
              style: AppTextStyles.screenTitle.copyWith(fontSize: 21),
            ),
            const SizedBox(height: 4),
            Text(
              'ابدئي جلسة مراقبة ليستمع مهد إلى طفلك',
              style: AppTextStyles.helperText,
            ),

            const SizedBox(height: 20),

            // ── Idle monitoring card ──────────────────────────
            _IdleMonitoringCard(),

            const SizedBox(height: 16),

            // ── Latest detected cry / event ───────────────────
            const _LatestCryEventCard(),

            const SizedBox(height: 12),

            // ── Quick stats ───────────────────────────────────
            _QuickStatsRow(),

            const SizedBox(height: 14),

            // ── Environment sensors ───────────────────────────
            const _EnvironmentRow(),

            const SizedBox(height: 14),

            // ── Upcoming calendar preview ─────────────────────
            const _UpcomingCalendarCard(),

            const SizedBox(height: 14),

            // ── Child development preview ─────────────────────
            const _ChildDevelopmentCard(),

            const SizedBox(height: 14),

            // ── White noise quick control ─────────────────────
            const _WhiteNoiseCard(),

            const SizedBox(height: 14),

            // ── Privacy note ──────────────────────────────────
            _PrivacyNote(),
          ],
        ),
      ),
    );
  }
}

// ── Top bar (logo + notification bell) ──────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/mahd-logo.png',
            width: 62,
            fit: BoxFit.contain,
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F785037),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                // Unread badge
                Positioned(
                  top: 9,
                  left: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.alert,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Idle monitoring card ─────────────────────────────────────────
class _IdleMonitoringCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24C88C64),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Microphone icon container ─────────────────
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.mic_none_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 18),

          // ── Status texts ──────────────────────────────
          Text(
            'المراقبة متوقفة',
            style: AppTextStyles.screenTitle.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'ابدئي الجلسة ليستمع مهد إلى محيط طفلك.',
            style: AppTextStyles.helperText.copyWith(
              fontSize: 12.5,
              color: AppColors.textHelper,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // ── Start monitoring button ───────────────────
          _StartMonitoringButton(),
        ],
      ),
    );
  }
}

// ── Dark "بدء المراقبة" button ───────────────────────────────────
class _StartMonitoringButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          // TODO: trigger monitoring session (future feature)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('بدء جلسة المراقبة… (قريبًا)'),
            ),
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkSurfaceText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          'بدء المراقبة',
          style: AppTextStyles.buttonText.copyWith(
            color: AppColors.darkSurfaceText,
          ),
        ),
      ),
    );
  }
}

// ── Latest detected cry / event ──────────────────────────────────
class _LatestCryEventCard extends StatelessWidget {
  const _LatestCryEventCard();

  /// 🔧 MOCK — static classification values until AI inference is connected.
  static const String _cause = 'جوع';
  static const String _confidence = '٩٢٪';
  static const String _timestamp = 'منذ ١٥ دقيقة';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon pill ──────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 12),

              // ── Title + timestamp ──────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'آخر حالة بكاء تم رصدها',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timestamp,
                      style: AppTextStyles.featureDesc.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Classification details ─────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'السبب المحتمل: ',
                      style: AppTextStyles.featureDesc.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _cause,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'نسبة التأكد: ',
                      style: AppTextStyles.featureDesc.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _confidence,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick stats row ──────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _StatTile(
          value: '٠',
          label: 'أحداث بكاء اليوم',
          valueColor: AppColors.primary,
        ),
        SizedBox(width: 10),
        _StatTile(value: '—', label: 'مدة المراقبة'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 20,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.featureDesc.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Environment sensors (Temperature & Humidity) ─────────────────
///
/// Displays two side-by-side cards showing room temperature and
/// humidity. Values are **mocked** until the hardware is connected.
class _EnvironmentRow extends StatelessWidget {
  const _EnvironmentRow();

  /// 🔧 MOCK — replace with real sensor data when hardware is ready.
  static const double _temperature = 24;
  static const int _humidity = 45;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EnvCard(
            icon: Icons.thermostat_rounded,
            label: 'درجة الحرارة',
            value: '${_temperature.toStringAsFixed(0)}',
            unit: '°م',
            // Comfortable range: 18–26 °C → green tint; outside → warm alert
            accentColor: (_temperature >= 18 && _temperature <= 26)
                ? AppColors.success
                : AppColors.alert,
            iconBgColor: const Color(0xFFFDEADF),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _EnvCard(
            icon: Icons.water_drop_outlined,
            label: 'الرطوبة',
            value: '$_humidity',
            unit: '%',
            accentColor: AppColors.success,
            iconBgColor: Color(0xFFEDF2EB),
          ),
        ),
      ],
    );
  }
}

class _EnvCard extends StatelessWidget {
  const _EnvCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.iconBgColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon pill ──────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: accentColor),
          ),

          const SizedBox(width: 12),

          // ── Value + label ──────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Numeric value
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.screenTitle.copyWith(
                        fontSize: 22,
                        color: accentColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      unit,
                      style: AppTextStyles.helperText.copyWith(
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Arabic label
                Text(
                  label,
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'مناسب',
                    style: AppTextStyles.featureDesc.copyWith(
                      fontSize: 10,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming calendar preview ────────────────────────────────────
class _UpcomingCalendarCard extends StatelessWidget {
  const _UpcomingCalendarCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الموعد القادم',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'موعد تطعيم',
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '5 أكتوبر • 10:30 ص',
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Text(
            'عرض التقويم',
            style: AppTextStyles.featureDesc.copyWith(
              fontSize: 10.5,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Child development preview ───────────────────────────────────
class _ChildDevelopmentCard extends StatelessWidget {
  const _ChildDevelopmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.child_friendly_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'نمو طفلك',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'تطور هذا العمر: يبدأ الطفل بتتبع الأشياء بعينيه',
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Text(
            'استكشفي المزيد',
            style: AppTextStyles.featureDesc.copyWith(
              fontSize: 10.5,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── White noise quick control ────────────────────────────────────
class _WhiteNoiseCard extends StatefulWidget {
  const _WhiteNoiseCard();

  @override
  State<_WhiteNoiseCard> createState() => _WhiteNoiseCardState();
}

class _WhiteNoiseCardState extends State<_WhiteNoiseCard> {
  bool _isWhiteNoiseOn = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon pill ──────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isWhiteNoiseOn
                  ? const Color(0xFFFDEADF)
                  : const Color(0xFFF5EFEA),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 22,
              color: _isWhiteNoiseOn
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: 12),

          // ── Title + status subtitle ────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الضوضاء البيضاء',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isWhiteNoiseOn ? 'قيد التشغيل' : 'متوقفة حالياً',
                  style: AppTextStyles.featureDesc.copyWith(
                    fontSize: 11,
                    color: _isWhiteNoiseOn
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Toggle Switch ──────────────────────────
          Switch(
            value: _isWhiteNoiseOn,
            onChanged: (value) {
              setState(() {
                _isWhiteNoiseOn = value;
              });
            },
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

// ── Privacy note ─────────────────────────────────────────────────
class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 19,
            color: AppColors.success,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'لا يُرفع أي تسجيل صوتي — تُرسل النتائج فقط',
              style: AppTextStyles.helperText.copyWith(
                fontSize: 12,
                color: AppColors.textHelper,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_left,
            size: 16,
            color: AppColors.borderBeige,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Bottom Navigation Bar
// ────────────────────────────────────────────────────────────────
class _MahdBottomNav extends StatelessWidget {
  const _MahdBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'الرئيسية'),
    _NavItem(icon: Icons.history_rounded, label: 'السجل'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'التقارير'),
    _NavItem(icon: Icons.settings_outlined, label: 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
          top: BorderSide(color: AppColors.borderMedium, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14785037),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(
              _items.length,
              (i) => _NavTile(
                item: _items[i],
                isSelected: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.iconBg,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(item.icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTextStyles.helperText.copyWith(
                fontSize: 10.5,
                color: color,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Placeholder tabs (History / Reports / Settings)
//  Will be replaced with real screens in future iterations.
// ────────────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              Text(
                label,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.helperText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'قادم قريبًا',
                style: AppTextStyles.helperText.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
