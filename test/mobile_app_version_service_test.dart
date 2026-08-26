import 'dart:convert';

import 'package:arenago/services/api_client.dart';
import 'package:arenago/services/mobile_app_version_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('checks the current mobile platform and version without auth', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, endsWith('/api/mobile-app-versions/status'));
      expect(request.url.queryParameters['Platform'], 'android');
      expect(request.url.queryParameters['Version'], '1.0.0');
      expect(request.headers['authorization'], isNull);
      expect(request.headers['accept'], 'text/plain');
      return http.Response(
        jsonEncode({
          'platform': 'android',
          'version': '1.0.0',
          'isActive': false,
        }),
        200,
      );
    });

    final service = MobileAppVersionService(ApiClient(client: client));
    final status = await service.getStatus(
      platform: 'android',
      version: '1.0.0',
    );

    expect(status.platform, 'android');
    expect(status.version, '1.0.0');
    expect(status.isActive, isFalse);
  });
}
