import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/primary_button.dart';

/// Screen 02 — الترحيب / Onboarding (Welcome Screen)
///
/// Shows the Mahd logo, a welcome heading, 3 feature cards,
/// and two action buttons leading to Sign-Up or Login.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [AppColors.gradientStart, AppColors.backgroundCream],
            stops: [0.0, 0.46],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: [
                // ── Logo ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 0),
                  child: Image.asset(
                    'assets/images/mahd-logo.png',
                    width: 132,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 26),

                // ── Heading ─────────────────────────────────────
                Text(
                  'أهلًا بك في مهد',
                  style: AppTextStyles.welcomeTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'نستمع إلى محيط طفلك، ونطمئنك عندما يحتاج إليك.',
                  style: AppTextStyles.helperText.copyWith(
                    fontSize: 14,
                    height: 1.9,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // ── Feature cards ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        FeatureCard(
                          icon: _CryIcon(),
                          title: 'نميّز بكاء طفلك',
                          description: 'ونقدّر السبب المحتمل للبكاء',
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          icon: _BellIcon(),
                          title: 'نرسل لك التنبيهات فورًا',
                          description:
                              'لتصلك نتائج المراقبة في الوقت المناسب',
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          icon: _ShieldIcon(),
                          title: 'صوت العائلة يبقى في البيت',
                          description: 'لا يُرفع أي تسجيل صوتي',
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Action buttons ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 34),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'إنشاء حساب جديد',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.signUp,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SecondaryButton(
                        label: 'لديّ حساب بالفعل',
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.login),
                      ),
                    ],
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

// ────────────────────────────────────────────────────────────────
//  SVG-mirrored icon widgets (drawn via CustomPainter / Canvas)
//  using the exact path data from the HTML design file.
// ────────────────────────────────────────────────────────────────

/// Audio-waveform / cry detection icon
class _CryIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _CryIconPainter()),
    );
  }
}

class _CryIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final sx = size.width / 24;
    final sy = size.height / 24;

    // M12 4v16
    canvas.drawLine(Offset(12 * sx, 4 * sy), Offset(12 * sx, 20 * sy), paint);
    // M7 8v8
    canvas.drawLine(Offset(7 * sx, 8 * sy), Offset(7 * sx, 16 * sy), paint);
    // M17 8v8
    canvas.drawLine(Offset(17 * sx, 8 * sy), Offset(17 * sx, 16 * sy), paint);
    // M3 11v2
    canvas.drawLine(Offset(3 * sx, 11 * sy), Offset(3 * sx, 13 * sy), paint);
    // M21 11v2
    canvas.drawLine(Offset(21 * sx, 11 * sy), Offset(21 * sx, 13 * sy), paint);
  }

  @override
  bool shouldRepaint(_CryIconPainter oldDelegate) => false;
}

/// Bell / notification icon
class _BellIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _BellIconPainter()),
    );
  }
}

class _BellIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final sx = size.width / 24;
    final sy = size.height / 24;

    // Bell body path
    final bodyPath = Path()
      ..moveTo(12 * sx, 3.5 * sy)
      ..cubicTo(
        9.0 * sx,
        3.5 * sy,
        6.5 * sx,
        5.9 * sy,
        6.5 * sx,
        9.0 * sy,
      )
      ..cubicTo(
        6.5 * sx,
        13.0 * sy,
        4.5 * sx,
        14.5 * sy,
        4.5 * sx,
        14.5 * sy,
      )
      ..lineTo(19.5 * sx, 14.5 * sy)
      ..cubicTo(
        19.5 * sx,
        14.5 * sy,
        17.5 * sx,
        13.0 * sy,
        17.5 * sx,
        9.0 * sy,
      )
      ..cubicTo(
        17.5 * sx,
        5.9 * sy,
        15.0 * sx,
        3.5 * sy,
        12 * sx,
        3.5 * sy,
      )
      ..close();

    canvas.drawPath(bodyPath, paint);

    // Clapper
    final clapperPath = Path()
      ..moveTo(10 * sx, 18 * sy)
      ..arcToPoint(
        Offset(14 * sx, 18 * sy),
        radius: Radius.circular(2 * sx),
        clockwise: false,
      );

    canvas.drawPath(clapperPath, paint);
  }

  @override
  bool shouldRepaint(_BellIconPainter oldDelegate) => false;
}

/// Shield / privacy icon
class _ShieldIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _ShieldIconPainter()),
    );
  }
}

class _ShieldIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final sx = size.width / 24;
    final sy = size.height / 24;

    // Shield
    final shieldPath = Path()
      ..moveTo(12 * sx, 3.5 * sy)
      ..lineTo(5 * sx, 6.5 * sy)
      ..lineTo(5 * sx, 11.5 * sy)
      ..cubicTo(
        5 * sx,
        15.7 * sy,
        7.9 * sx,
        19.1 * sy,
        12 * sx,
        20.5 * sy,
      )
      ..cubicTo(
        16.1 * sx,
        19.1 * sy,
        19 * sx,
        15.7 * sy,
        19 * sx,
        11.5 * sy,
      )
      ..lineTo(19 * sx, 6.5 * sy)
      ..close();

    canvas.drawPath(shieldPath, paint);

    // Check mark
    final checkPath = Path()
      ..moveTo(9.4 * sx, 12 * sy)
      ..lineTo(11.3 * sx, 13.9 * sy)
      ..lineTo(14.7 * sx, 10.3 * sy);

    canvas.drawPath(checkPath, paint);
  }

  @override
  bool shouldRepaint(_ShieldIconPainter oldDelegate) => false;
}