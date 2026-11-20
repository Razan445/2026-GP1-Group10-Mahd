import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/audio_monitoring_service.dart';
import '../../services/cry_classifier_service.dart';
import '../../services/firestore_service.dart';
import '../calendar/calendar_screen.dart';
import '../child_development/child_development_gate.dart';
import '../settings/settings_screen.dart';
import '../history/history_screen.dart';
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

  final CryClassifierService _classifier = CryClassifierService();
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _classifier.init();
      if (!mounted) return;
      setState(() => _modelReady = true);
    } catch (e) {
      debugPrint('CryClassifierService init error: $e');
    }
  }

  // Greeting based on time-of-day:
  // 4:00 AM .. 11:59 AM -> صباح الخير
  // 12:00 PM .. 3:59 AM -> مساء الخير
  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 12) return 'صباح الخير';
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
    _classifier.dispose();
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
              'لديك تذكيرات تحتاج إلى انتباهك. يمكنك عرضها في التقويم.',
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
                          _currentIndex = 2;
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
            onCameraTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const _LiveCameraScreen(),
                ),
              );
            },
          ),
          const HistoryScreen(),
          const CalendarScreen(),
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
    required this.onCameraTap,
  });

  final String greeting;
  final bool showReminderBadge;
  final VoidCallback onBellTap;
  final bool isMonitoring;
  final bool isMonitoringActionInProgress;
  final String monitoringDurationText;
  final VoidCallback onMonitoringTap;
  final VoidCallback onCameraTap;

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
                final fullName =
                    (snapshot.data?.data()?['fullName'] as String?)?.trim();

                final firstName =
                    (fullName == null || fullName.isEmpty)
                        ? ''
                        : fullName.split(RegExp(r'\s+')).first;

                return Text(
                  firstName.isEmpty ? greeting : '$greeting، $firstName',
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: 21,
                  ),
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
            // ── Microphone + camera controls ───────────────────────
            _MonitoringControlsRow(
              isMonitoring: isMonitoring,
              isLoading: isMonitoringActionInProgress,
              onMonitoringTap: onMonitoringTap,
              onCameraTap: onCameraTap,
            ),

            const SizedBox(height: 16),

            // ── Child development preview ─────────────────────
            const _ChildDevelopmentCard(),

            const SizedBox(height: 14),

            // ── Latest detected cry / event ───────────────────
            const _LatestCryEventCard(),

            const SizedBox(height: 12),

            // ── Quick stats ───────────────────────────────────
            _QuickStatsRow(
              isMonitoring: isMonitoring,
              durationText: monitoringDurationText,
            ),

            const SizedBox(height: 14),

            // ── White noise quick control ─────────────────────
            const _WhiteNoiseCard(),

            // ── Privacy note ──────────────────────────────────
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
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
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

// ── Microphone + camera controls ────────────────────────────────

class _MonitoringControlsRow extends StatelessWidget {
  const _MonitoringControlsRow({
    required this.isMonitoring,
    required this.isLoading,
    required this.onMonitoringTap,
    required this.onCameraTap,
  });

  final bool isMonitoring;
  final bool isLoading;
  final VoidCallback onMonitoringTap;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MonitoringFeatureCard(
            title: 'الميكروفون',
            subtitle:
                isMonitoring ? 'يستمع الآن' : 'متوقف حالياً',
            icon: isMonitoring
                ? Icons.graphic_eq_rounded
                : Icons.mic_none_rounded,
            isActive: isMonitoring,
            isLoading: isLoading,
            actionLabel:
                isMonitoring ? 'إيقاف' : 'بدء',
            onTap: onMonitoringTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MonitoringFeatureCard(
            title: 'الكاميرا',
            subtitle: 'بث مباشر فقط',
            icon: Icons.videocam_outlined,
            isActive: false,
            isLoading: false,
            actionLabel: 'عرض البث',
            onTap: onCameraTap,
          ),
        ),
      ],
    );
  }
}

class _MonitoringFeatureCard extends StatelessWidget {
  const _MonitoringFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.isLoading,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final bool isLoading;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeStart = Color(0xFFE7F2E5);
    const activeEnd = Color(0xFFD4E7D1);
    const activeAccent = Color(0xFF4F7A4A);

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 300,
      ),
      padding: const EdgeInsets.fromLTRB(
        14,
        18,
        14,
        14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? const [
                  activeStart,
                  activeEnd,
                ]
              : const [
                  AppColors.gradientStart,
                  AppColors.gradientEnd,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? AppColors.success.withValues(
                  alpha: 0.45,
                )
              : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18C88C64),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.84,
              ),
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(
                      color: AppColors.success.withValues(
                        alpha: 0.45,
                      ),
                      width: 1.5,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 30,
              color: isActive
                  ? activeAccent
                  : AppColors.primary,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? const Color(
                      0xFF284325,
                    )
                  : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.featureDesc.copyWith(
              fontSize: 10.5,
              color: isActive
                  ? const Color(
                      0xFF3E633A,
                    )
                  : AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed:
                  isLoading ? null : onTap,
              style: TextButton.styleFrom(
                backgroundColor: isActive
                    ? const Color(
                        0xFF2F4A2C,
                      )
                    : AppColors.darkSurface,
                disabledBackgroundColor:
                    AppColors.darkSurface.withValues(
                  alpha: 0.72,
                ),
                foregroundColor:
                    AppColors.darkSurfaceText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors
                            .darkSurfaceText,
                      ),
                    )
                  : Text(
                      actionLabel,
                      style: AppTextStyles.buttonText
                          .copyWith(
                        fontSize: 11.5,
                        color: AppColors
                            .darkSurfaceText,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live camera placeholder ──────────────────────────────────────

class _LiveCameraScreen extends StatelessWidget {
  const _LiveCameraScreen();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor:
              AppColors.backgroundCream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'البث المباشر',
            style:
                AppTextStyles.cardTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF1F1D1B,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam_outlined,
                          size: 58,
                          color: Colors.white70,
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Text(
                          'سيظهر البث المباشر هنا عند ربط كاميرا مهد',
                          textAlign:
                              TextAlign.center,
                          style: AppTextStyles
                              .featureDesc
                              .copyWith(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          height: 7,
                        ),
                        Text(
                          'البث للمشاهدة فقط ولن يتم تسجيل الفيديو أو حفظه.',
                          textAlign:
                              TextAlign.center,
                          style: AppTextStyles
                              .helperText
                              .copyWith(
                            fontSize: 11,
                            color:
                                Colors.white70,
                          ),
                        ),
                      ],
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
  State<_IdleMonitoringCard> createState() =>
      _IdleMonitoringCardState();
}

class _IdleMonitoringCardState
    extends State<_IdleMonitoringCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ),
    );

    if (widget.isMonitoring) {
      _pulseController.repeat(
        reverse: true,
      );
    }
  }

  @override
  void didUpdateWidget(
    covariant _IdleMonitoringCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.isMonitoring &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(
        reverse: true,
      );
    } else if (!widget.isMonitoring &&
        _pulseController.isAnimating) {
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
    const activeStart =
        Color(0xFFE7F2E5);
    const activeEnd =
        Color(0xFFD4E7D1);
    const activeAccent =
        Color(0xFF4F7A4A);

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 350,
      ),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [
                  activeStart,
                  activeEnd,
                ]
              : const [
                  AppColors.gradientStart,
                  AppColors.gradientEnd,
                ],
          stops: const [
            0.0,
            1.0,
          ],
        ),
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: active
              ? AppColors.success.withValues(
                  alpha: 0.55,
                )
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? const Color(
                    0x2864905E,
                  )
                : const Color(
                    0x24C88C64,
                  ),
            blurRadius: 30,
            offset: const Offset(
              0,
              12,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Microphone icon container with live pulse ──
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseScale = active
                  ? 1.0 +
                      (_pulseController.value *
                          0.11)
                  : 1.0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  if (active)
                    Transform.scale(
                      scale: pulseScale,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,
                          color: AppColors.success
                              .withValues(
                            alpha: 0.18 *
                                (1.0 -
                                    _pulseController
                                            .value *
                                        0.4),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 114,
                    height: 114,
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.82,
                      ),
                      shape: BoxShape.circle,
                      border: active
                          ? Border.all(
                              color: AppColors
                                  .success
                                  .withValues(
                                alpha: 0.5,
                              ),
                              width: 2,
                            )
                          : null,
                    ),
                    alignment:
                        Alignment.center,
                    child: Icon(
                      active
                          ? Icons
                              .graphic_eq_rounded
                          : Icons
                              .mic_none_rounded,
                      size: 44,
                      color: active
                          ? activeAccent
                          : AppColors.primary,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Status texts ──────────────────────────────
          Text(
            active
                ? 'المراقبة قيد التشغيل'
                : 'المراقبة متوقفة',
            style:
                AppTextStyles.screenTitle.copyWith(
              fontSize: 18,
              color: active
                  ? const Color(
                      0xFF284325,
                    )
                  : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            active
                ? 'مهد يستمع الآن إلى محيط طفلك ويعالج الصوت محليًا.'
                : 'ابدئي الجلسة ليستمع مهد إلى محيط طفلك.',
            style: AppTextStyles.helperText
                .copyWith(
              fontSize: 12.5,
              color: active
                  ? const Color(
                      0xFF3E633A,
                    )
                  : AppColors.textHelper,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // ── Monitoring button ─────────────────────────
          _StartMonitoringButton(
            isMonitoring: active,
            isLoading: widget.isLoading,
            onPressed:
                widget.onMonitoringTap,
          ),
        ],
      ),
    );
  }
}

// ── Monitoring Action Button ─────────────────────────────────────

class _StartMonitoringButton
    extends StatelessWidget {
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
        ? const Color(
            0xFF2F4A2C,
          )
        : AppColors.darkSurface;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: TextButton(
        onPressed:
            isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          disabledBackgroundColor:
              bgColor.withValues(
            alpha: 0.72,
          ),
          foregroundColor:
              AppColors.darkSurfaceText,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              17,
            ),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors
                      .darkSurfaceText,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Icon(
                    isMonitoring
                        ? Icons
                            .stop_circle_outlined
                        : Icons
                            .play_circle_outline_rounded,
                    size: 20,
                    color: AppColors
                        .darkSurfaceText,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    isMonitoring
                        ? 'إيقاف المراقبة'
                        : 'بدء المراقبة',
                    style: AppTextStyles
                        .buttonText
                        .copyWith(
                      color: AppColors
                          .darkSurfaceText,
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

  /// 🔧 MOCK — static classification & sensor values until AI inference is connected.
  static const String _cause = 'جوع';
  static const String _confidence = '٩٢٪';
  static const String _timestamp =
      'منذ ١٥ دقيقة';
  static const String _temperature =
      '24°م';
  static const String _humidity = '45%';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D785037),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                alignment:
                    Alignment.center,
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Text(
                      'آخر حالة بكاء تم رصدها',
                      style: AppTextStyles
                          .cardTitle
                          .copyWith(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timestamp,
                      style: AppTextStyles
                          .featureDesc
                          .copyWith(
                        fontSize: 11,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEAF3E8,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    999,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration:
                          const BoxDecoration(
                        color: Color(
                          0xFF4F7A4A,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color:
                  AppColors.backgroundCream,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'السبب المحتمل: ',
                          style: AppTextStyles
                              .featureDesc
                              .copyWith(
                            fontSize: 11.5,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                        Text(
                          _cause,
                          style: AppTextStyles
                              .cardTitle
                              .copyWith(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color: AppColors
                                .textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'نسبة التأكد: ',
                          style: AppTextStyles
                              .featureDesc
                              .copyWith(
                            fontSize: 11.5,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                        Text(
                          _confidence,
                          style: AppTextStyles
                              .cardTitle
                              .copyWith(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color: AppColors
                                .primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color:
                        AppColors.borderBeige,
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons
                                .thermostat_rounded,
                            size: 15,
                            color:
                                AppColors.primary,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            'درجة الحرارة: ',
                            style: AppTextStyles
                                .featureDesc
                                .copyWith(
                              fontSize: 11,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                          Text(
                            _temperature,
                            style: AppTextStyles
                                .cardTitle
                                .copyWith(
                              fontSize: 11.5,
                              fontWeight:
                                  FontWeight
                                      .w600,
                              color: AppColors
                                  .textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      color:
                          AppColors.borderBeige,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons
                                .water_drop_outlined,
                            size: 15,
                            color: Color(
                              0xFF4F7A4A,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            'الرطوبة: ',
                            style: AppTextStyles
                                .featureDesc
                                .copyWith(
                              fontSize: 11,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                          Text(
                            _humidity,
                            style: AppTextStyles
                                .cardTitle
                                .copyWith(
                              fontSize: 11.5,
                              fontWeight:
                                  FontWeight
                                      .w600,
                              color: AppColors
                                  .textPrimary,
                            ),
                          ),
                        ],
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
          valueColor: isMonitoring
              ? const Color(0xFF4F7A4A)
              : AppColors.textPrimary,
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
          borderRadius:
              BorderRadius.circular(20),
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
              style: AppTextStyles.screenTitle
                  .copyWith(
                fontSize: 20,
                color: valueColor ??
                    AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style:
                  AppTextStyles.featureDesc
                      .copyWith(
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

// ── Child development preview ───────────────────────────────────

class _ChildDevelopmentCard extends StatelessWidget {
  const _ChildDevelopmentCard();

  int? _ageInMonths(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;

    final now = DateTime.now();
    int months =
        (now.year - dateOfBirth.year) * 12 +
            (now.month - dateOfBirth.month);

    if (now.day < dateOfBirth.day) {
      months -= 1;
    }

    return months < 0 ? 0 : months;
  }

  String _formatAge(int? months) {
    if (months == null) return 'غير محدد بعد';
    if (months == 0) return 'أقل من شهر';
    if (months == 1) return 'شهر واحد';
    if (months == 2) return 'شهران';
    if (months >= 3 && months <= 10) {
      return '$months أشهر';
    }
    if (months == 11) return '11 شهرًا';

    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (remainingMonths == 0) {
      return years == 1
          ? 'سنة واحدة'
          : '$years سنوات';
    }

    final yearText = years == 1
        ? 'سنة'
        : '$years سنوات';

    final monthText = remainingMonths == 1
        ? 'وشهر'
        : remainingMonths == 2
            ? 'وشهران'
            : 'و$remainingMonths أشهر';

    return '$yearText $monthText';
  }

  String _mockActivityForAge(int? months) {
    // TODO: Replace mock age-based activity with research-backed developmental content.
    if (months == null) {
      return 'أكملي بيانات طفلك لعرض نشاط مناسب لعمره.';
    }

    if (months <= 2) {
      return 'حرّكي لعبة عالية التباين ببطء أمام طفلك وشجعيه على تتبعها بعينيه.';
    }

    if (months <= 4) {
      return 'خصصي وقتًا قصيرًا للاستلقاء على البطن مع وضع لعبة أمامه لتشجيعه على رفع رأسه.';
    }

    if (months <= 6) {
      return 'ضعي لعبة آمنة قريبة منه وشجعيه على مد يده والإمساك بها.';
    }

    if (months <= 9) {
      return 'ضعي لعبة أمامه على مسافة قصيرة وشجعيه على التحرك للوصول إليها.';
    }

    if (months <= 12) {
      return 'شجعيه على نقل لعبة بين يديه ووضعها داخل وعاء ثم إخراجها.';
    }

    if (months <= 18) {
      return 'سمّي الأشياء اليومية أمامه واطلبي منه الإشارة إلى الشيء الذي تسمّينه.';
    }

    return 'شاركيه نشاطًا بسيطًا مناسبًا لعمره مثل المطابقة أو تسمية الصور والأشياء اليومية.';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirestoreService.instance.watchAccount(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final dobValue =
            data?['childDateOfBirth'];

        final childName =
            (data?['childName'] as String?)
                ?.trim();

        DateTime? dateOfBirth;

        if (dobValue is Timestamp) {
          dateOfBirth =
              dobValue.toDate();
        }

        final ageMonths =
            _ageInMonths(dateOfBirth);

        final ageText =
            _formatAge(ageMonths);

        final activity =
            _mockActivityForAge(
          ageMonths,
        );

        return InkWell(
          borderRadius:
              BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const ChildDevelopmentGate(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              17,
            ),
            decoration: BoxDecoration(
              color:
                  AppColors.cardSurface,
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
              border: Border.all(
                color:
                    AppColors.borderLight,
              ),
              boxShadow: const [
                BoxShadow(
                  color:
                      Color(0x0D785037),
                  blurRadius: 16,
                  offset:
                      Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.iconBg,
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),
                      alignment:
                          Alignment.center,
                      child: const Icon(
                        Icons
                            .child_friendly_rounded,
                        size: 24,
                        color:
                            AppColors.primary,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'نمو طفلك',
                            style:
                                AppTextStyles
                                    .cardTitle
                                    .copyWith(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            childName !=
                                        null &&
                                    childName
                                        .isNotEmpty
                                ? 'عمر $childName: $ageText'
                                : 'عمر طفلك: $ageText',
                            style:
                                AppTextStyles
                                    .featureDesc
                                    .copyWith(
                              fontSize: 11.5,
                              color: AppColors
                                  .textSecondary,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          'استكشفي المزيد',
                          style:
                              AppTextStyles
                                  .featureDesc
                                  .copyWith(
                            fontSize: 10.5,
                            color: AppColors
                                .primary,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        const Icon(
                          Icons
                              .chevron_left_rounded,
                          size: 18,
                          color:
                              AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(
                  height: 14,
                ),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors
                        .backgroundCream,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons
                                .auto_awesome_rounded,
                            size: 16,
                            color:
                                AppColors.primary,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            'نشاط مقترح لهذا العمر',
                            style:
                                AppTextStyles
                                    .cardTitle
                                    .copyWith(
                              fontSize: 11.5,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Text(
                        activity,
                        style:
                            AppTextStyles
                                .featureDesc
                                .copyWith(
                          fontSize: 11.5,
                          height: 1.65,
                          color: AppColors
                              .textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── White noise quick control ────────────────────────────────────

class _WhiteNoiseCard extends StatefulWidget {
  const _WhiteNoiseCard();

  @override
  State<_WhiteNoiseCard> createState() =>
      _WhiteNoiseCardState();
}

class _WhiteNoiseCardState
    extends State<_WhiteNoiseCard> {
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
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D785037),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isWhiteNoiseOn
                  ? const Color(
                      0xFFFDEADF,
                    )
                  : const Color(
                      0xFFF5EFEA,
                    ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 22,
              color: _isWhiteNoiseOn
                  ? AppColors.primary
                  : AppColors
                      .textSecondary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  'الضوضاء البيضاء',
                  style: AppTextStyles
                      .cardTitle
                      .copyWith(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  _isWhiteNoiseOn
                      ? 'قيد التشغيل'
                      : 'متوقفة حالياً',
                  style: AppTextStyles
                      .featureDesc
                      .copyWith(
                    fontSize: 11,
                    color: _isWhiteNoiseOn
                        ? AppColors.primary
                        : AppColors
                            .textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: _isWhiteNoiseOn,
            onChanged: (value) {
              setState(() {
                _isWhiteNoiseOn =
                    value;
              });
            },
            activeThumbColor:
                Colors.white,
            activeTrackColor:
                AppColors.primary,
            inactiveThumbColor:
                Colors.white,
            inactiveTrackColor:
                AppColors.borderBeige,
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
        borderRadius:
            BorderRadius.circular(20),
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
              style: AppTextStyles.helperText
                  .copyWith(
                fontSize: 12,
                color: AppColors.textHelper,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_left,
            size: 16,
            color:
                AppColors.borderBeige,
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
      icon: Icons.calendar_month_rounded,
      label: 'التقويم',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      label: 'الإعدادات',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
          top: BorderSide(
            color:
                AppColors.borderMedium,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Color(0x14785037),
            blurRadius: 20,
            offset: Offset(
              0,
              -4,
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 8,
          ),
          child: Row(
            children: List.generate(
              _items.length,
              (i) => _NavTile(
                item: _items[i],
                isSelected:
                    i == currentIndex,
                onTap: () =>
                    onTap(i),
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
    final color = isSelected
        ? AppColors.primary
        : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior:
            HitTestBehavior.opaque,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 200,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: isSelected
                  ? BoxDecoration(
                      color:
                          AppColors.iconBg,
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    )
                  : null,
              child: Icon(
                item.icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              item.label,
              style: AppTextStyles
                  .helperText
                  .copyWith(
                fontSize: 10.5,
                color: color,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}