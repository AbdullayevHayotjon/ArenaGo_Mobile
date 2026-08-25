import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/auth_session.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/session_storage.dart';

enum AppStage { login, createPin, unlock, home }

class AppController extends ChangeNotifier {
  AppController({
    AuthService? authService,
    SessionStorage? storage,
    BiometricService? biometricService,
  }) : _storage = storage ?? SessionStorage(),
       _biometricService = biometricService ?? BiometricService() {
    _apiClient = ApiClient(
      sessionProvider: () => session,
      onSessionRefreshed: _saveRefreshedSession,
      onSessionExpired: _clearExpiredSession,
    );
    _authService = authService ?? AuthService(apiClient: _apiClient);
  }

  final SessionStorage _storage;
  final BiometricService _biometricService;
  late final ApiClient _apiClient;
  late final AuthService _authService;
  AuthSession? session;
  AppStage stage = AppStage.login;
  String language = 'uz';
  ThemeMode themeMode = ThemeMode.light;
  bool busy = false;
  bool logoutBusy = false;

  AppStrings get strings => AppStrings(language);
  ApiClient get apiClient => _apiClient;

  Future<void> initialize() async {
    language = await _storage.readLanguage();
    themeMode = await _storage.readDarkMode()
        ? ThemeMode.dark
        : ThemeMode.light;
    session = await _storage.readSession();
    if (session != null) {
      stage = await _storage.hasPin() ? AppStage.unlock : AppStage.createPin;
    }
  }

  Future<String?> login(String phone, String password) async {
    busy = true;
    notifyListeners();
    try {
      session = await _authService.login(phone, password);
      await _storage.saveSession(session!);
      language = session!.preferredLanguage.toLowerCase().startsWith('ru')
          ? 'ru'
          : 'uz';
      await _storage.saveLanguage(language);
      stage = AppStage.createPin;
      return null;
    } on AuthException catch (error) {
      if (error.code == 'unsupported_role') return strings.t('customerOnly');
      if (error.code == 'network_error') return strings.t('networkError');
      return error.message?.isNotEmpty == true
          ? error.message
          : strings.t('loginError');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> createPin(String pin) async {
    await _storage.savePin(pin);
  }

  Future<bool> canUseBiometrics() => _biometricService.isAvailable();

  Future<bool> isBiometricEnabled() => _storage.readBiometricEnabled();

  Future<void> setBiometricEnabled(bool value) =>
      _storage.saveBiometricEnabled(value);

  Future<bool> authenticateWithBiometrics() async {
    if (!await _storage.readBiometricEnabled()) return false;
    if (!await _biometricService.isAvailable()) return false;
    return _biometricService.authenticate(strings.t('biometricReason'));
  }

  Future<bool> confirmBiometricSetup() async {
    if (!await _biometricService.isAvailable()) return false;
    return _biometricService.authenticate(strings.t('biometricReason'));
  }

  Future<void> completePinSetup() => _enterHome();

  Future<void> unlockWithBiometrics() => _enterHome();

  Future<bool> unlock(String pin) async {
    final valid = await _storage.verifyPin(pin);
    if (valid) await _enterHome();
    return valid;
  }

  Future<void> _enterHome() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    stage = AppStage.home;
    notifyListeners();
  }

  Future<String?> logout() async {
    final activeSession = session;
    if (activeSession == null || logoutBusy) return null;

    logoutBusy = true;
    notifyListeners();
    try {
      await _authService.logout(activeSession.accessToken);
      await _storage.clearAuth();
      session = null;
      stage = AppStage.login;
      return null;
    } on AuthException catch (error) {
      if (error.code == 'network_error') return strings.t('networkError');
      return error.message?.isNotEmpty == true
          ? error.message
          : strings.t('logoutError');
    } finally {
      logoutBusy = false;
      notifyListeners();
    }
  }

  Future<void> _saveRefreshedSession(AuthSession refreshedSession) async {
    session = refreshedSession;
    await _storage.saveSession(refreshedSession);
    notifyListeners();
  }

  Future<void> _clearExpiredSession() async {
    await _storage.clearAuth();
    session = null;
    stage = AppStage.login;
    busy = false;
    logoutBusy = false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _storage.saveDarkMode(themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    await setLanguage(language == 'uz' ? 'ru' : 'uz');
  }

  Future<void> setLanguage(String value) async {
    if (value == language || (value != 'uz' && value != 'ru')) return;
    language = value;
    await _storage.saveLanguage(language);
    notifyListeners();
  }
}
