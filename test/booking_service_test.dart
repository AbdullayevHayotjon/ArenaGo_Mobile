import 'dart:convert';

import 'package:arenago/services/api_client.dart';
import 'package:arenago/services/booking_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads a paginated customer booking tab', () async {
    final httpClient = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, endsWith('/api/bookings'));
      expect(request.url.queryParameters, {
        'Tab': 'active',
        'PageNumber': '2',
        'PageSize': '20',
      });
      expect(request.headers['accept'], 'text/plain');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'items': [
              {
                'id': 'booking-2',
                'bookingNumber': 'AG-BOOKING-2',
                'footballFieldId': 'field-2',
                'ownerAdminId': 'admin-1',
                'customerId': 'customer-1',
                'source': 'online',
                'customerName': 'Foydalanuvchi',
                'customerPhoneNumber': '+998900000000',
                'bookingDate': '2026-08-26',
                'startsAt': '15:00:00',
                'endsAt': '16:00:00',
                'status': 'pendingPayment',
                'totalAmount': 200000,
                'prepaymentAmount': 150000,
                'collectedAmount': 0,
                'currency': 'UZS',
                'expiresAt': '2026-08-25T11:26:52.762545',
                'createdAt': '2026-08-25T11:16:52.765803',
                'field': {
                  'id': 'field-2',
                  'name': {'uz': 'Telebashniya', 'ru': 'Телебашня'},
                  'address': {'uz': 'Manzil', 'ru': 'Адрес'},
                  'image': null,
                },
                'remainingAmount': 200000,
              },
            ],
            'pageNumber': 2,
            'pageSize': 20,
            'totalCount': 21,
            'totalPages': 2,
            'hasPreviousPage': true,
            'hasNextPage': false,
          }),
        ),
        200,
      );
    });

    final service = BookingService(ApiClient(client: httpClient));
    final page = await service.getBookings(
      tab: 'active',
      pageNumber: 2,
      pageSize: 20,
    );

    expect(page.items, hasLength(1));
    expect(page.items.single.bookingNumber, 'AG-BOOKING-2');
    expect(page.items.single.status, 'pendingPayment');
    expect(page.items.single.field.name.value('ru'), 'Телебашня');
    expect(page.pageNumber, 2);
    expect(page.totalCount, 21);
    expect(page.hasNextPage, isFalse);
  });

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

  test(
    'creates an online booking with field, date and start time only',
    () async {
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/api/bookings'));
        expect(request.headers['accept'], 'text/plain');
        expect(jsonDecode(request.body), {
          'footballFieldId': 'field-1',
          'date': '2026-08-25',
          'startTime': '11:00:00.000',
        });
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'id': 'booking-1',
              'bookingNumber': 'AG-BOOKING-1',
              'footballFieldId': 'field-1',
              'ownerAdminId': 'admin-1',
              'customerId': 'customer-1',
              'source': 'online',
              'customerName': 'Foydalanuvchi',
              'customerPhoneNumber': '+998900000000',
              'bookingDate': '2026-08-25',
              'startsAt': '11:00:00',
              'endsAt': '12:00:00',
              'status': 'pendingPayment',
              'totalAmount': 120000,
              'prepaymentAmount': 18000,
              'collectedAmount': 0,
              'currency': 'UZS',
              'expiresAt': '2026-08-25T10:41:20.1451407',
              'createdAt': '2026-08-25T10:31:20.1628296',
              'field': {
                'id': 'field-1',
                'name': {'uz': 'Maydon', 'ru': 'Поле'},
                'address': {'uz': 'Manzil', 'ru': 'Адрес'},
                'image': null,
              },
              'remainingAmount': 120000,
            }),
          ),
          201,
        );
      });

      final service = BookingService(ApiClient(client: httpClient));
      final booking = await service.create(
        footballFieldId: 'field-1',
        date: '2026-08-25',
        startTime: '11:00:00.000',
      );

      expect(booking.id, 'booking-1');
      expect(booking.bookingNumber, 'AG-BOOKING-1');
      expect(booking.endsAt, '12:00:00');
      expect(booking.prepaymentAmount, 18000);
      expect(booking.field.name.value('ru'), 'Поле');
      expect(booking.expiresAt, DateTime.parse('2026-08-25T10:41:20.1451407'));
    },
  );
}
