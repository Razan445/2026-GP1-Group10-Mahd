import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsService {
  LocalSettingsService._();

  static final LocalSettingsService instance =
      LocalSettingsService._();

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  static const String _cryAlertsKey =
      'cryAlertsEnabled';

  static const String _environmentAlertsKey =
      'environmentAlertsEnabled';

  static const String _connectionAlertsKey =
      'connectionAlertsEnabled';

  Future<bool> getCryAlertsEnabled() async {
    return await _preferences.getBool(
          _cryAlertsKey,
        ) ??
        true;
  }

  Future<bool> getEnvironmentAlertsEnabled() async {
    return await _preferences.getBool(
          _environmentAlertsKey,
        ) ??
        true;
  }

  Future<bool> getConnectionAlertsEnabled() async {
    return await _preferences.getBool(
          _connectionAlertsKey,
        ) ??
        true;
  }

  Future<void> setCryAlertsEnabled(
    bool value,
  ) async {
    await _preferences.setBool(
      _cryAlertsKey,
      value,
    );
  }

  Future<void> setEnvironmentAlertsEnabled(
    bool value,
  ) async {
    await _preferences.setBool(
      _environmentAlertsKey,
      value,
    );
  }

  Future<void> setConnectionAlertsEnabled(
    bool value,
  ) async {
    await _preferences.setBool(
      _connectionAlertsKey,
      value,
    );
  }
}