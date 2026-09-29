import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/infant_registration/infant_registration_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/sign_up/sign_up_screen.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Light status-bar style to match the cream background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MahdApp());
}

class MahdApp extends StatelessWidget {
  const MahdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مهد',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,

      // ── RTL (Arabic) support ──────────────────────────────────
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Routing ───────────────────────────────────────────────
      initialRoute: AppRoutes.splash,
      routes: {
        // Auth flow
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.signUp: (_) => const SignUpScreen(),
        AppRoutes.login: (_) => const LoginScreen(),

        // Post-auth flow
        AppRoutes.infantRegistration: (_) => const InfantRegistrationScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
      },
    );
  }
}
