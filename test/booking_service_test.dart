import 'dart:convert';

import 'package:arenago/services/api_client.dart';
import 'package:arenago/services/booking_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads availability using the same date query as the web app', () async {
    final httpClient = MockClient((request) async {
      expect(request.method, 'GET');
      expect(
        request.url.path,
        endsWith('/api/football-fields/field-1/availability'),
      );
      expect(request.url.queryParameters['From'], '2026-08-24');
      expect(request.url.queryParameters['To'], '2026-08-30');
      expect(request.headers['accept'], 'text/plain');
      return http.Response(
        jsonEncode([
          {
            'date': '2026-08-24',
            'startsAt': '08:00:00',
            'endsAt': '09:00:00',
            'isAvailable': true,
          },
          {
            'date': '2026-08-24',
            'startsAt': '09:00:00',
            'endsAt': '10:00:00',
            'isAvailable': false,
          },
        ]),
        200,
      );
    });

    final service = BookingService(ApiClient(client: httpClient));
    final slots = await service.getAvailability(
      footballFieldId: 'field-1',
      from: '2026-08-24',
      to: '2026-08-30',
    );

    expect(slots, hasLength(2));
    expect(slots.first.isAvailable, isTrue);
    expect(slots.last.isAvailable, isFalse);
    expect(slots.first.timeKey, '08:00:00|09:00:00');
  });
}
