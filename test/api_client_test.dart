import 'dart:convert';

import 'package:arenago/models/auth_session.dart';
import 'package:arenago/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient token refresh', () {
    test('rotates both tokens and retries the failed request once', () async {
      var session = _session(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
      var refreshCalls = 0;
      var protectedCalls = 0;

      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshCalls++;
          expect(jsonDecode(request.body), {'refreshToken': 'old-refresh'});
          return http.Response(
            jsonEncode(
              _session(
                accessToken: 'new-access',
                refreshToken: 'new-refresh',
              ).toJson(),
            ),
            200,
          );
        }

        protectedCalls++;
        if (protectedCalls == 1) {
          expect(request.headers['authorization'], 'Bearer old-access');
          return http.Response('', 401);
        }
        expect(request.headers['authorization'], 'Bearer new-access');
        return http.Response('{"ok":true}', 200);
      });

      final client = ApiClient(
        client: httpClient,
        sessionProvider: () => session,
        onSessionRefreshed: (refreshed) async => session = refreshed,
      );

      final response = await client.request('GET', '/protected');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
      expect(protectedCalls, 2);
      expect(session.accessToken, 'new-access');
      expect(session.refreshToken, 'new-refresh');
    });

    test('uses one refresh request for simultaneous 401 responses', () async {
      var session = _session(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
      var refreshCalls = 0;

      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return http.Response(
            jsonEncode(
              _session(
                accessToken: 'new-access',
                refreshToken: 'new-refresh',
              ).toJson(),
            ),
            200,
          );
        }
        if (request.headers['authorization'] == 'Bearer old-access') {
          return http.Response('', 401);
        }
        return http.Response('{}', 200);
      });

      final client = ApiClient(
        client: httpClient,
        sessionProvider: () => session,
        onSessionRefreshed: (refreshed) async => session = refreshed,
      );

      final responses = await Future.wait([
        client.request('GET', '/first'),
        client.request('GET', '/second'),
      ]);

      expect(
        responses.map((response) => response.statusCode),
        everyElement(200),
      );
      expect(refreshCalls, 1);
    });

    test('expires the local session when refresh is rejected', () async {
      final session = _session(
        accessToken: 'old-access',
        refreshToken: 'expired-refresh',
      );
      var expired = false;

      final client = ApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            return http.Response('', 401);
          }
          return http.Response('', 401);
        }),
        sessionProvider: () => session,
        onSessionExpired: () async => expired = true,
      );

      final response = await client.request('GET', '/protected');

      expect(response.statusCode, 401);
      expect(expired, isTrue);
    });
  });
}

AuthSession _session({
  required String accessToken,
  required String refreshToken,
}) {
  return AuthSession(
    userId: 'user-id',
    firstName: 'Foydalanuvchi',
    phoneNumber: '+998900000000',
    preferredLanguage: 'uzbek',
    role: 'customer',
    accessToken: accessToken,
    expiresAtUtc: 'ignored',
    refreshToken: refreshToken,
    refreshTokenExpiresAt: 'ignored',
  );
}
