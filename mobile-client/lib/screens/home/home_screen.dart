import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/audio_monitoring_service.dart';
import '../../services/firestore_service.dart';
import '../calendar/calendar_screen.dart';
import '../child_development/child_development_gate.dart';
import '../settings/settings_screen.dart';
import '../history/history_screen.dart';
import '../reports/reports_screen.dart';
import '../../widgets/app_snack_bar.dart';

/// Screen 07 — الرئيسية (Home Screen)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasImportantReminders = true;
  bool _isMonitoring = false;
  bool _isMonitoringActionInProgress = false;
  String? _activeSessionId;

  Timer? _monitoringTimer;
  int _currentSessionSeconds = 0;
  int _completedSessionsSecondsToday = 0;

  // Greeting based on time-of-day
  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'صباح الخير';
    if (hour < 18) return 'مساء الخير';
    return 'مساء الخير';
  }

  int get _totalMonitoringSecondsToday =>
      _completedSessionsSecondsToday + _currentSessionSeconds;

  String get _formattedMonitoringDuration {
    final total = _totalMonitoringSecondsToday;
    if (!_isMonitoring && total == 0) {
      return '—';
    }
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }

  void _startElapsedTimer() {
    _monitoringTimer?.cancel();
    _currentSessionSeconds = 0;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isMonitoring) return;
      setState(() {
        _currentSessionSeconds += 1;
      });
    });
  }

  void _stopElapsedTimer() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _completedSessionsSecondsToday += _currentSessionSeconds;
    _currentSessionSeconds = 0;
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoringActionInProgress) {
      return;
    }

    if (_isMonitoring) {
      await _stopMonitoring();
    } else {
      await _startMonitoring();
    }
  }

  Future<void> _startMonitoring() async {
    setState(() {
      _isMonitoringActionInProgress = true;
    });

    try {
      // Start the real microphone stream first.
      // A Firestore session is created only if microphone startup succeeds.
      await AudioMonitoringService.instance.startMonitoring();

      final sessionId = await FirestoreService.instance.startSession();

      if (!mounted) {
        await _cleanupMonitoringOnDispose(sessionId);
        return;
      }

      setState(() {
        _activeSessionId = sessionId;
        _isMonitoring = true;
        _startElapsedTimer();
      });
    } on AudioMonitoringPermissionException {
      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        'نحتاج إذن الميكروفون لبدء المراقبة',
        type: AppSnackBarType.error,
      );
    } catch (e) {
      debugPrint('Monitoring start error: $e');

      if (AudioMonitoringService.instance.isMonitoring) {
        try {
          await AudioMonitoringService.instance.stopMonitoring();
        } catch (stopError) {
          debugPrint(
            'Microphone cleanup after start failure: $stopError',
          );
        }
      }

      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        'تعذر بدء المراقبة، حاولي مرة أخرى',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMonitoringActionInProgress = false;
        });
      }
    }
  }

  Future<void> _stopMonitoring() async {
    setState(() {
      _isMonitoringActionInProgress = true;
    });

    final sessionId = _activeSessionId;
    Object? microphoneError;
    Object? sessionError;

    try {
      await AudioMonitoringService.instance.stopMonitoring();
    } catch (e) {
      microphoneError = e;
      debugPrint('Microphone stop error: $e');
    }

    if (sessionId != null) {
      try {
        await FirestoreService.instance.endSession(
          sessionId: sessionId,
        );
      } catch (e) {
        sessionError = e;
        debugPrint('Session end error: $e');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _stopElapsedTimer();
      _isMonitoring = false;
      _activeSessionId = null;
      _isMonitoringActionInProgress = false;
    });

    if (microphoneError != null || sessionError != null) {
      AppSnackBar.show(
        context,
        'توقفت المراقبة، لكن تعذر تحديث جزء من بيانات الجلسة',
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _cleanupMonitoringOnDispose(
    String? sessionId,
  ) async {
    if (AudioMonitoringService.instance.isMonitoring) {
      try {
        await AudioMonitoringService.instance.stopMonitoring();
      } catch (e) {
        debugPrint('Microphone cleanup error: $e');
      }
    }

    if (sessionId != null) {
      try {
        await FirestoreService.instance.endSession(
          sessionId: sessionId,
        );
      } catch (e) {
        debugPrint('Session cleanup error: $e');
      }
    }
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    unawaited(
      _cleanupMonitoringOnDispose(_activeSessionId),
    );

    super.dispose();
  }

  Future<void> _showReminderDialog() async {
    setState(() {
      _hasImportantReminders = false;
    });

    await showDialog<void>(
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
            title: Text(
              'عندك تذكيرات مهمة',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 18,
              ),
            ),
            content: Text(
              'لديك تذكيرات تحتاج إلى انتباهك. يمكنك عرضها في السجل.',
              textAlign: TextAlign.center,
              style: AppTextStyles.helperText.copyWith(
                fontSize: 11.5,
                height: 1.7,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              18,
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
                          46,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'إغلاق',
                        style: AppTextStyles.buttonTextDark.copyWith(
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();

                        setState(() {
                          _currentIndex = 1;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(
                          double.infinity,
                          46,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'عرضها',
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 12.5,
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
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,

      // ── Tab body ─────────────────────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            greeting: _greeting,
            showReminderBadge: _hasImportantReminders,
            onBellTap: _showReminderDialog,
            isMonitoring: _isMonitoring,
            isMonitoringActionInProgress: _isMonitoringActionInProgress,
            monitoringDurationText: _formattedMonitoringDuration,
            onMonitoringTap: _toggleMonitoring,
          ),
          const HistoryScreen(),
          const ReportsScreen(),
          const SettingsScreen(),
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
  const _HomeTab({
    required this.greeting,
    required this.showReminderBadge,
    required this.onBellTap,
    required this.isMonitoring,
    required this.isMonitoringActionInProgress,
    required this.monitoringDurationText,
    required this.onMonitoringTap,
  });

  final String greeting;
  final bool showReminderBadge;
  final VoidCallback onBellTap;
  final bool isMonitoring;
  final bool isMonitoringActionInProgress;
  final String monitoringDurationText;
  final VoidCallback onMonitoringTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top bar ──────────────────────────────────────
            _TopBar(
              showReminderBadge: showReminderBadge,
              onBellTap: onBellTap,
            ),

            const SizedBox(height: 6),

            // ── Greeting ─────────────────────────────────────
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.instance.watchAccount(),
              builder: (context, snapshot) {
                final name =
                    (snapshot.data?.data()?['fullName'] as String?)?.trim();

                return Text(
                  (name == null || name.isEmpty)
                      ? greeting
                      : '$greeting، $name',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 21),
                );
              },
            ),

            const SizedBox(height: 4),

            Text(
              'ابدئي جلسة مراقبة ليستمع مهد إلى طفلك',
              style: AppTextStyles.helperText,
            ),

            const SizedBox(height: 20),

            // ── Monitoring card (Dynamic Color & Pulse State) ──
            _IdleMonitoringCard(
              isMonitoring: isMonitoring,
              isLoading: isMonitoringActionInProgress,
              onMonitoringTap: onMonitoringTap,
            ),

            const SizedBox(height: 16),

            // ── Latest detected cry / event ───────────────────
            const _LatestCryEventCard(),

            const SizedBox(height: 12),

            // ── Quick stats ───────────────────────────────────
            _QuickStatsRow(
              isMonitoring: isMonitoring,
              durationText: monitoringDurationText,
            ),

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
  const _TopBar({
    required this.showReminderBadge,
    required this.onBellTap,
  });

  final bool showReminderBadge;
  final VoidCallback onBellTap;

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
          InkWell(
            onTap: onBellTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
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
                  if (showReminderBadge)
                    Positioned(
                      top: 9,
                      left: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.alert,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dynamic monitoring card (Idle vs Active State) ──────────────

class _IdleMonitoringCard extends StatefulWidget {
  const _IdleMonitoringCard({
    required this.isMonitoring,
    required this.isLoading,
    required this.onMonitoringTap,
  });

  final bool isMonitoring;
  final bool isLoading;
  final VoidCallback onMonitoringTap;

  @override
  State<_IdleMonitoringCard> createState() => _IdleMonitoringCardState();
}

class _IdleMonitoringCardState extends State<_IdleMonitoringCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isMonitoring) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _IdleMonitoringCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMonitoring && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isMonitoring && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isMonitoring;

    // ألوان الحالة: الدافئة في وضع التوقف، والخضراء الحية المطمئنة في وضع التشغيل
    const activeStart = Color(0xFFE7F2E5);
    const activeEnd = Color(0xFFD4E7D1);
    const activeAccent = Color(0xFF4F7A4A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [activeStart, activeEnd]
              : const [AppColors.gradientStart, AppColors.gradientEnd],
          stops: const [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: active
              ? AppColors.success.withValues(alpha: 0.55)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? const Color(0x2864905E)
                : const Color(0x24C88C64),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Microphone icon container with live pulse ──
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseScale =
                  active ? 1.0 + (_pulseController.value * 0.11) : 1.0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (active)
                    Transform.scale(
                      scale: pulseScale,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(
                            alpha: 0.18 * (1.0 - _pulseController.value * 0.4),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 114,
                    height: 114,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      shape: BoxShape.circle,
                      border: active
                          ? Border.all(
                              color: AppColors.success.withValues(alpha: 0.5),
                              width: 2,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      active ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                      size: 44,
                      color: active ? activeAccent : AppColors.primary,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Status texts ──────────────────────────────
          Text(
            active ? 'المراقبة قيد التشغيل' : 'المراقبة متوقفة',
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: 18,
              color: active ? const Color(0xFF284325) : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            active
                ? 'مهد يستمع الآن إلى محيط طفلك ويعالج الصوت محليًا.'
                : 'ابدئي الجلسة ليستمع مهد إلى محيط طفلك.',
            style: AppTextStyles.helperText.copyWith(
              fontSize: 12.5,
              color: active ? const Color(0xFF3E633A) : AppColors.textHelper,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // ── Monitoring button ─────────────────────────
          _StartMonitoringButton(
            isMonitoring: active,
            isLoading: widget.isLoading,
            onPressed: widget.onMonitoringTap,
          ),
        ],
      ),
    );
  }
}

// ── Monitoring Action Button ─────────────────────────────────────

class _StartMonitoringButton extends StatelessWidget {
  const _StartMonitoringButton({
    required this.isMonitoring,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isMonitoring;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bgColor = isMonitoring
        ? const Color(0xFF2F4A2C)
        : AppColors.darkSurface;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.72),
          foregroundColor: AppColors.darkSurfaceText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.darkSurfaceText,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isMonitoring
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline_rounded,
                    size: 20,
                    color: AppColors.darkSurfaceText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMonitoring ? 'إيقاف المراقبة' : 'بدء المراقبة',
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.darkSurfaceText,
                    ),
                  ),
                ],
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

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
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
  const _QuickStatsRow({
    required this.isMonitoring,
    required this.durationText,
  });

  final bool isMonitoring;
  final String durationText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _StatTile(
          value: '٠',
          label: 'أحداث بكاء اليوم',
          valueColor: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _StatTile(
          value: durationText,
          label: 'مدة المراقبة',
          valueColor:
              isMonitoring ? const Color(0xFF4F7A4A) : AppColors.textPrimary,
        ),
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
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
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
              style: AppTextStyles.featureDesc.copyWith(
                fontSize: 11,
              ),
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
            value: _temperature.toStringAsFixed(0),
            unit: '°م',
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: accentColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
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

          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CalendarScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              child: Text(
                'عرض التقويم',
                style: AppTextStyles.featureDesc.copyWith(
                  fontSize: 10.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
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

          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChildDevelopmentGate(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              child: Text(
                'استكشفي المزيد',
                style: AppTextStyles.featureDesc.copyWith(
                  fontSize: 10.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
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
    _NavItem(
      icon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    _NavItem(
      icon: Icons.history_rounded,
      label: 'السجل',
    ),
    _NavItem(
      icon: Icons.bar_chart_rounded,
      label: 'التقارير',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      label: 'الإعدادات',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderMedium,
            width: 1,
          ),
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
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ),
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
  const _NavItem({
    required this.icon,
    required this.label,
  });

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
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.iconBg,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                item.icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTextStyles.helperText.copyWith(
                fontSize: 10.5,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
