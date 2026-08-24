import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_session.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://172.29.90.122:8080/api',
);

class AuthException implements Exception {
  const AuthException(this.code, [this.message]);
  final String code;
  final String? message;
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();
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
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException('network_error');
    } on FormatException {
      throw const AuthException('invalid_response');
    } catch (_) {
      throw const AuthException('network_error');
    }
  }
}
