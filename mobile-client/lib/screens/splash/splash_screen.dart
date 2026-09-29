import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

/// Screen 01 — شاشة البداية (Splash)
///
/// Shown briefly at app launch. After 2.5 s it auto-navigates
/// to the Onboarding/Welcome screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Navigate to onboarding after 2.5 s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.1,
            colors: [AppColors.gradientStart, AppColors.backgroundCream],
            stops: [0.0, 0.65],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ─────────────────────────────────────────
                  Image.asset(
                    'assets/images/mahd-logo.png',
                    width: 188,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 26),

                  // ── Tagline ───────────────────────────────────────
                  Text(
                    'مهد يسمع… لتطمئنّي',
                    style: AppTextStyles.splashTagline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'مراقبة صوتية هادئة لطفلك',
                    style: AppTextStyles.splashSub,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 56),

                  // ── Page indicator dots ──────────────────────────
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Dot(
                        width: 26,
                        color: AppColors.primaryLight,
                      ),
                      SizedBox(width: 6),
                      _Dot(color: AppColors.borderBeige),
                      SizedBox(width: 6),
                      _Dot(color: AppColors.borderBeige),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.width = 8, required this.color});
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
