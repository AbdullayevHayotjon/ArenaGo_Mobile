import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';

class SessionStorage {
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _sessionKey = 'arenago_auth_session';
  static const _pinHashKey = 'arenago_pin_hash';
  static const _pinSaltKey = 'arenago_pin_salt';
  static const _biometricEnabledKey = 'arenago_biometric_enabled';

  Future<AuthSession?> readSession() async {
    final raw = await _secure.read(key: _sessionKey);
    if (raw == null) return null;
    try {
      final session = AuthSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (session.role.toLowerCase() != 'customer') return null;
      return session;
    } catch (_) {
      await clearAuth();
      return null;
    }
  }

  Future<void> saveSession(AuthSession session) =>
      _secure.write(key: _sessionKey, value: jsonEncode(session.toJson()));

  Future<bool> hasPin() async => (await _secure.read(key: _pinHashKey)) != null;

  Future<void> savePin(String pin) async {
    final random = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(24, (_) => random.nextInt(256)),
    );
    await _secure.write(key: _pinSaltKey, value: salt);
    await _secure.write(key: _pinHashKey, value: _hash(pin, salt));
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _secure.read(key: _pinSaltKey);
    final savedHash = await _secure.read(key: _pinHashKey);
    return salt != null && savedHash != null && _hash(pin, salt) == savedHash;
  }

  Future<bool> readBiometricEnabled() async =>
      (await _secure.read(key: _biometricEnabledKey)) == 'true';

  Future<void> saveBiometricEnabled(bool value) =>
      _secure.write(key: _biometricEnabledKey, value: value ? 'true' : 'false');

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin:ArenaGo')).toString();

  Future<void> clearAuth() async {
    await Future.wait([
      _secure.delete(key: _sessionKey),
      _secure.delete(key: _pinHashKey),
      _secure.delete(key: _pinSaltKey),
      _secure.delete(key: _biometricEnabledKey),
    ]);
  }

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();
  Future<String> readLanguage() async =>
      (await _prefs).getString('language') ?? 'uz';
  Future<bool> readDarkMode() async =>
      (await _prefs).getBool('dark_mode') ?? false;
  Future<void> saveLanguage(String value) async =>
      (await _prefs).setString('language', value);
  Future<void> saveDarkMode(bool value) async =>
      (await _prefs).setBool('dark_mode', value);
}
