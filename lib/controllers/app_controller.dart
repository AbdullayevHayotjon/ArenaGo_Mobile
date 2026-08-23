import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';
import '../services/session_storage.dart';

enum AppStage { login, createPin, unlock, home }

class AppController extends ChangeNotifier {
  AppController({AuthService? authService, SessionStorage? storage})
    : _authService = authService ?? AuthService(),
      _storage = storage ?? SessionStorage();

  final AuthService _authService;
  final SessionStorage _storage;
  AuthSession? session;
  AppStage stage = AppStage.login;
  String language = 'uz';
  ThemeMode themeMode = ThemeMode.light;
  bool busy = false;

  AppStrings get strings => AppStrings(language);

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
    stage = AppStage.home;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final valid = await _storage.verifyPin(pin);
    if (valid) {
      stage = AppStage.home;
      notifyListeners();
    }
    return valid;
  }

  Future<void> logout() async {
    await _storage.clearAuth();
    session = null;
    stage = AppStage.login;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _storage.saveDarkMode(themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    language = language == 'uz' ? 'ru' : 'uz';
    await _storage.saveLanguage(language);
    notifyListeners();
  }
}
