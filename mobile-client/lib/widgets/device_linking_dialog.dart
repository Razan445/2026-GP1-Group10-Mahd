import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'primary_button.dart';

/// اسم الجهاز كما يظهر للمستخدمة داخل التطبيق.
const String kMahdDeviceName = 'نبض مهد';

/// نافذة منبثقة تحاكي عملية ربط جهاز «نبض مهد» (الهاردوير) بحساب المستخدمة.
///
/// تمر النافذة بخمس مراحل: تعريف → بحث → العثور على الجهاز → ربط → نجاح.
/// تُرجِع `true` عند اكتمال الربط، و`false` إذا اختارت المستخدمة التخطي.
class DeviceLinkingDialog extends StatefulWidget {
  const DeviceLinkingDialog({super.key, this.userName});

  /// اسم المستخدمة لعرض رسالة ترحيب شخصية (اختياري).
  final String? userName;

  /// يعرض النافذة ويُرجِع `true` إذا تم الربط بنجاح.
  static Future<bool> show(BuildContext context, {String? userName}) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ربط الجهاز',
      barrierColor: const Color(0x993A2B23),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => DeviceLinkingDialog(userName: userName),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
    return result ?? false;
  }

  @override
  State<DeviceLinkingDialog> createState() => _DeviceLinkingDialogState();
}

enum _Stage { intro, searching, found, linking, success }

class _DeviceLinkingDialogState extends State<DeviceLinkingDialog>
    with TickerProviderStateMixin {
  static const _linkSteps = [
    'الاتصال بالجهاز',
    'التحقق من الأمان',
    'ربطه بحسابك',
  ];

  _Stage _stage = _Stage.intro;
  int _completedSteps = 0;
  final List<Timer> _timers = [];

  late final AnimationController _rings = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _rings.repeat();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _rings.dispose();
    _float.dispose();
    super.dispose();
  }

  void _later(Duration d, VoidCallback fn) {
    _timers.add(
      Timer(d, () {
        if (mounted) fn();
      }),
    );
  }

  void _startSearch() {
    setState(() => _stage = _Stage.searching);
    _later(const Duration(milliseconds: 3200), () {
      setState(() => _stage = _Stage.found);
    });
  }

  void _startLinking() {
    setState(() {
      _stage = _Stage.linking;
      _completedSteps = 0;
    });
    for (var i = 1; i <= _linkSteps.length; i++) {
      _later(Duration(milliseconds: 1000 * i), () {
        setState(() => _completedSteps = i);
      });
    }
    _later(Duration(milliseconds: 1000 * _linkSteps.length + 600), () {
      setState(() => _stage = _Stage.success);
    });
  }

  void _close(bool linked) => Navigator.of(context).pop(linked);

  bool get _showRings =>
      _stage == _Stage.searching ||
      _stage == _Stage.found ||
      _stage == _Stage.linking;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppColors.backgroundCream,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  // خلفية متدرجة ناعمة خلف منطقة الجهاز
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 250,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.gradientEnd,
                            AppColors.backgroundCream,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDeviceArea(),
                        const SizedBox(height: 18),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeOut,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.06),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey(_stage),
                              child: _buildStageContent(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── منطقة الجهاز مع حلقات البحث ──────────────────────────────
  Widget _buildDeviceArea() {
    final success = _stage == _Stage.success;
    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (_showRings)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rings,
                builder: (_, __) =>
                    CustomPaint(painter: _RingsPainter(progress: _rings.value)),
              ),
            ),
          // توهج خلف الجهاز
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (success ? AppColors.success : AppColors.primaryLight)
                      .withValues(alpha: 0.35),
                  blurRadius: 60,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _float,
            builder: (_, child) {
              final dy = math.sin(_float.value * math.pi) * -7;
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              scale: _stage == _Stage.intro ? 1.0 : 0.82,
              child: Image.asset(
                'assets/images/mahd-device.png',
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // شارة النجاح
          Positioned(
            bottom: 8,
            right: 62,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              scale: success ? 1 : 0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundCream,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case _Stage.intro:
        return _buildIntro();
      case _Stage.searching:
        return _buildSearching();
      case _Stage.found:
        return _buildFound();
      case _Stage.linking:
        return _buildLinking();
      case _Stage.success:
        return _buildSuccess();
    }
  }

  Widget _title(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: AppTextStyles.screenTitle.copyWith(fontSize: 21),
  );

  Widget _subtitle(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: AppTextStyles.helperText.copyWith(fontSize: 13),
  );

  Widget _skipButton(String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    child: Text(
      label,
      style: AppTextStyles.helperText.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // ── 1) التعريف ──────────────────────────────────────────────
  Widget _buildIntro() {
    final name = widget.userName?.trim();
    final firstName = (name == null || name.isEmpty)
        ? null
        : name.split(' ').first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _title(
          firstName == null
              ? 'لنربط $kMahdDeviceName بحسابك'
              : 'أهلًا $firstName، لنربط $kMahdDeviceName',
        ),
        const SizedBox(height: 6),
        _subtitle(
          'جهاز مهد القريب من سرير طفلك يستمع ويراقب بهدوء،\n'
          'ونرسل لك التنبيهات على حسابك مباشرة.',
        ),
        const SizedBox(height: 18),
        const _InstructionTile(
          icon: Icons.power_settings_new_rounded,
          text: 'شغّلي الجهاز وانتظري ضوءه الأخضر',
        ),
        const SizedBox(height: 8),
        const _InstructionTile(
          icon: Icons.bluetooth_rounded,
          text: 'فعّلي البلوتوث وقرّبي الهاتف من الجهاز',
        ),
        const SizedBox(height: 22),
        PrimaryButton(label: 'ابدئي البحث عن الجهاز', onPressed: _startSearch),
        const SizedBox(height: 4),
        _skipButton('لاحقًا', () => _close(false)),
      ],
    );
  }

  // ── 2) البحث ────────────────────────────────────────────────
  Widget _buildSearching() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('جارٍ البحث عن الجهاز...'),
        const SizedBox(height: 6),
        _subtitle('أبقي الجهاز قريبًا من هاتفك.\nلن يستغرق الأمر سوى لحظات.'),
        const SizedBox(height: 22),
        const _DotsLoader(),
        const SizedBox(height: 18),
        _skipButton('إلغاء', () => _close(false)),
      ],
    );
  }

  // ── 3) تم العثور على الجهاز ─────────────────────────────────
  Widget _buildFound() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('وجدنا جهازك!'),
        const SizedBox(height: 6),
        _subtitle('تأكدي أنه الجهاز الصحيح ثم اضغطي «ربط الجهاز».'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderBeige, width: 1.5),
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
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kMahdDeviceName, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      'MAHD-NB-4821',
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.helperText.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.signal_cellular_alt_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'إشارة قوية',
                      style: AppTextStyles.helperText.copyWith(
                        fontSize: 11,
                        color: const Color(0xFF3B5738),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'ربط الجهاز', onPressed: _startLinking),
        const SizedBox(height: 4),
        _skipButton('ليس جهازي', () {
          setState(() => _stage = _Stage.searching);
          _later(
            const Duration(milliseconds: 2400),
            () => setState(() => _stage = _Stage.found),
          );
        }),
      ],
    );
  }

  // ── 4) الربط ────────────────────────────────────────────────
  Widget _buildLinking() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('نربط الجهاز بحسابك...'),
        const SizedBox(height: 6),
        _subtitle('لحظات قليلة ونكون جاهزين.'),
        const SizedBox(height: 18),
        for (var i = 0; i < _linkSteps.length; i++) ...[
          _StepRow(
            label: _linkSteps[i],
            done: i < _completedSteps,
            active: i == _completedSteps,
          ),
          if (i != _linkSteps.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // ── 5) النجاح ───────────────────────────────────────────────
  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('تم الربط بنجاح !'),
        const SizedBox(height: 6),
        _subtitle(
          '$kMahdDeviceName أصبح مرتبطًا بحسابك\n'
          'وجاهز لمراقبة طفلك بكل طمأنينة.',
        ),
        const SizedBox(height: 22),
        PrimaryButton(label: 'متابعة', onPressed: () => _close(true)),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  عناصر مساعدة
// ═════════════════════════════════════════════════════════════

class _InstructionTile extends StatelessWidget {
  const _InstructionTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyText.copyWith(fontSize: 13, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.success : Colors.white,
            border: Border.all(
              color: done ? AppColors.success : AppColors.borderBeige,
              width: 1.5,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
              : active
              ? const Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTextStyles.bodyText.copyWith(
            fontSize: 13.5,
            color: done || active
                ? AppColors.textPrimary
                : AppColors.textSecondary.withValues(alpha: 0.6),
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// ثلاث نقاط تنبض بالتتابع أثناء البحث.
class _DotsLoader extends StatefulWidget {
  const _DotsLoader();

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((_c.value - i * 0.18) % 1.0 + 1.0) % 1.0;
          final s = 0.55 + 0.45 * math.sin(t * math.pi);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 10 * s + 3,
            height: 10 * s + 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.35 + 0.65 * s),
            ),
          );
        }),
      ),
    );
  }
}

/// حلقات تتوسع من مركز الجهاز وتتلاشى — تعطي إحساس «البحث عن إشارة».
class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = math.min(size.width, size.height) / 2 + 30;
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final radius = 55 + (maxR - 55) * Curves.easeOut.transform(t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.primaryLight.withValues(alpha: (1 - t) * 0.55);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.progress != progress;
}
