/// Named route constants — single source of truth for navigation.
class AppRoutes {
  AppRoutes._();

  // ── Auth flow ────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signUp = '/sign-up';
  static const String login = '/login';

  // ── Post-auth flow ───────────────────────────────────────────
  static const String infantRegistration = '/infant-registration';
  static const String home = '/home';
}
