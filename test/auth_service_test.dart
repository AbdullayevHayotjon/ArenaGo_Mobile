import 'dart:convert';

import 'package:arenago/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthService.logout', () {
    test('sends the same authorized POST request as the web app', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url, Uri.parse('$apiBaseUrl/auth/logout'));
        expect(request.headers['accept'], '*/*');
        expect(request.headers['content-type'], 'application/json');
        expect(request.headers['authorization'], 'Bearer access-token');
        expect(request.body, isEmpty);
        return http.Response('', 204);
      });

      await AuthService(client: client).logout('access-token');
    });

    test('returns the server problem title on failure', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'title': 'Logout rad etildi'}),
          400,
          headers: {'content-type': 'application/json'},
        ),
      );

      expect(
        () => AuthService(client: client).logout('access-token'),
        throwsA(
          isA<AuthException>()
              .having((error) => error.code, 'code', 'logout_failed')
              .having((error) => error.message, 'message', 'Logout rad etildi'),
        ),
      );
    });
  });
}
