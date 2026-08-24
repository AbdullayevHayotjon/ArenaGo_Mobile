import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import 'api_logging_client.dart';
import 'app_logger.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://172.29.90.122:8080/api',
);

class AuthException implements Exception {
  const AuthException(this.code, [this.message]);
  final String code;
  final String? message;

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? ApiLoggingClient();
  final http.Client _client;

  Future<AuthSession> login(String phoneNumber, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$apiBaseUrl/auth/login'),
            headers: const {
              'accept': 'text/plain',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'phoneNumber': phoneNumber,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String? message;
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body is Map<String, dynamic>) {
            message = body['message']?.toString() ?? body['title']?.toString();
          }
        } catch (_) {
          message = utf8.decode(response.bodyBytes).trim();
        }
        throw AuthException('invalid_credentials', message);
      }

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final session = AuthSession.fromJson(data);
      if (session.role.trim().toLowerCase() != 'customer') {
        throw const AuthException('unsupported_role');
      }
      if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
        throw const AuthException('invalid_response');
      }
      return session;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('AUTH', error, stackTrace);
      rethrow;
    } on TimeoutException catch (error, stackTrace) {
      AppLogger.error('AUTH', error, stackTrace);
      throw const AuthException('network_error');
    } on FormatException catch (error, stackTrace) {
      AppLogger.error('AUTH', error, stackTrace);
      throw const AuthException('invalid_response');
    } catch (error, stackTrace) {
      AppLogger.error('AUTH', error, stackTrace);
      throw const AuthException('network_error');
    }
  }

  Future<void> logout(String accessToken) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$apiBaseUrl/auth/logout'),
            headers: {
              'accept': '*/*',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException('logout_failed', _readErrorMessage(response));
      }
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('AUTH', error, stackTrace);
      rethrow;
    } on TimeoutException catch (error, stackTrace) {
      AppLogger.error('AUTH', error, stackTrace);
      throw const AuthException('network_error');
    } catch (error, stackTrace) {
      AppLogger.error('AUTH', error, stackTrace);
      throw const AuthException('network_error');
    }
  }

  String? _readErrorMessage(http.Response response) {
    final text = utf8.decode(response.bodyBytes).trim();
    if (text.isEmpty) return null;
    try {
      final body = jsonDecode(text);
      if (body is Map<String, dynamic>) {
        return body['message']?.toString() ?? body['title']?.toString();
      }
    } on FormatException {
      return text;
    }
    return text;
  }
}
