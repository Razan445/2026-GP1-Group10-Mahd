import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsService {
  LocalSettingsService._();

  static final LocalSettingsService instance =
      LocalSettingsService._();

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  static const String _cryAlertsKey =
      'cryAlertsEnabled';

  // Cry and environmental context belong to one notification preference.
  // Keep the old environment methods below for existing callers.
  static const String _connectionAlertsKey =
      'connectionAlertsEnabled';

  static const String _reminderAlertsKey =
      'reminderAlertsEnabled';

  static const String _reminderEnabledSinceKey =
      'reminderAlertsEnabledSince';

  Future<bool> getCryAlertsEnabled() async {
    return await _preferences.getBool(
          _cryAlertsKey,
        ) ??
        true;
  }

  // Compatibility with any existing code that reads the old environment
  // preference. Environment readings are context for a cry event, not a
  // separate source of push notifications.
  Future<bool> getEnvironmentAlertsEnabled() async {
    return getCryAlertsEnabled();
  }

  Future<bool> getConnectionAlertsEnabled() async {
    return await _preferences.getBool(
          _connectionAlertsKey,
        ) ??
        true;
  }

  // Disabled by default until the caregiver enables calendar reminders.
  Future<bool> getReminderAlertsEnabled() async {
    return await _preferences.getBool(
          _reminderAlertsKey,
        ) ??
        false;
  }

  // Prevent alerts due while reminders were disabled from appearing as
  // newly-unread bell items after they are enabled again.
  Future<DateTime?> getReminderAlertsEnabledSince() async {
    final milliseconds = await _preferences.getInt(
      _reminderEnabledSinceKey,
    );
    if (milliseconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  Future<void> setCryAlertsEnabled(
    bool value,
  ) async {
    await _preferences.setBool(
      _cryAlertsKey,
      value,
    );
  }

  // Compatibility wrapper: no separate environment notification switch.
  Future<void> setEnvironmentAlertsEnabled(
    bool value,
  ) async {
    await setCryAlertsEnabled(value);
  }

  Future<void> setConnectionAlertsEnabled(
    bool value,
  ) async {
    await _preferences.setBool(
      _connectionAlertsKey,
      value,
    );
  }

  Future<void> setReminderAlertsEnabled(
    bool value,
  ) async {
    final wasEnabled = await getReminderAlertsEnabled();
    if (value && !wasEnabled) {
      await _preferences.setInt(
        _reminderEnabledSinceKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } else if (!value) {
      await _preferences.remove(_reminderEnabledSinceKey);
    }
    await _preferences.setBool(
      _reminderAlertsKey,
      value,
    );
  }
}
