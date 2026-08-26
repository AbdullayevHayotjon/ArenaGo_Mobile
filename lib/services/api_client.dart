import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import 'api_config.dart';
import 'api_logging_client.dart';
import 'app_logger.dart';

typedef SessionProvider = AuthSession? Function();
typedef SessionRefreshed = Future<void> Function(AuthSession session);
typedef SessionExpired = Future<void> Function();

class ApiClient {
  ApiClient({
    http.Client? client,
    SessionProvider? sessionProvider,
    SessionRefreshed? onSessionRefreshed,
    SessionExpired? onSessionExpired,
  }) : _client = client ?? ApiLoggingClient(),
       _sessionProvider = sessionProvider ?? _noSession,
       _onSessionRefreshed = onSessionRefreshed ?? _ignoreRefreshedSession,
       _onSessionExpired = onSessionExpired ?? _ignoreExpiredSession;

  static AuthSession? _noSession() => null;
  static Future<void> _ignoreRefreshedSession(AuthSession _) async {}
  static Future<void> _ignoreExpiredSession() async {}

  final http.Client _client;
  final SessionProvider _sessionProvider;
  final SessionRefreshed _onSessionRefreshed;
  final SessionExpired _onSessionExpired;

  Future<AuthSession?>? _refreshInProgress;
  Future<void>? _expirationInProgress;

  Future<http.Response> request(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool authenticated = true,
    String? accessTokenOverride,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final firstToken = authenticated
        ? accessTokenOverride ?? _sessionProvider()?.accessToken
        : null;
    final firstResponse = await _send(
      method,
      path,
      headers: headers,
      body: body,
      accessToken: firstToken,
      timeout: timeout,
    );

    if (!authenticated || firstResponse.statusCode != 401) {
      return firstResponse;
    }

    final activeSession = _sessionProvider();
    if (activeSession == null || activeSession.refreshToken.isEmpty) {
      await _expireSession();
      return firstResponse;
    }

    final refreshedSession = await _refreshSession(activeSession);
    if (refreshedSession == null) return firstResponse;

    final retryResponse = await _send(
      method,
      path,
      headers: headers,
      body: body,
      accessToken: refreshedSession.accessToken,
      timeout: timeout,
    );
    if (retryResponse.statusCode == 401) await _expireSession();
    return retryResponse;
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    String? accessToken,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final request = http.Request(method, Uri.parse('$apiBaseUrl$path'));
    request.headers.addAll({
      'accept': 'application/json, text/plain',
      if (body != null) 'Content-Type': 'application/json',
      if (accessToken?.isNotEmpty == true)
        'Authorization': 'Bearer $accessToken',
      ...?headers,
    });
    if (body != null) {
      request.body = body is String ? body : jsonEncode(body);
    }
    final streamedResponse = await _client.send(request).timeout(timeout);
    return http.Response.fromStream(streamedResponse);
  }

  Future<AuthSession?> _refreshSession(AuthSession activeSession) {
    final currentRefresh = _refreshInProgress;
    if (currentRefresh != null) return currentRefresh;

    final refresh = _performRefresh(activeSession);
    _refreshInProgress = refresh;
    refresh.whenComplete(() {
      if (identical(_refreshInProgress, refresh)) {
        _refreshInProgress = null;
      }
    });
    return refresh;
  }

  Future<AuthSession?> _performRefresh(AuthSession activeSession) async {
    try {
      final response = await _send(
        'POST',
        '/auth/refresh',
        headers: const {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
        },
        body: {'refreshToken': activeSession.refreshToken},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _expireSession();
        return null;
      }

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final refreshedSession = AuthSession.fromJson(data);
      final validCustomer =
          refreshedSession.role.trim().toLowerCase() == 'customer';
      if (!validCustomer ||
          refreshedSession.accessToken.isEmpty ||
          refreshedSession.refreshToken.isEmpty) {
        await _expireSession();
        return null;
      }

      await _onSessionRefreshed(refreshedSession);
      return refreshedSession;
    } catch (error, stackTrace) {
      AppLogger.error('REFRESH', error, stackTrace);
      await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() {
    final currentExpiration = _expirationInProgress;
    if (currentExpiration != null) return currentExpiration;

    final expiration = _onSessionExpired();
    _expirationInProgress = expiration;
    expiration.whenComplete(() {
      if (identical(_expirationInProgress, expiration)) {
        _expirationInProgress = null;
      }
    });
    return expiration;
  }

  void close() => _client.close();
}
