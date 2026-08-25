import 'dart:convert';

import 'package:arenago/services/api_client.dart';
import 'package:arenago/services/football_field_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads valid football field map locations', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(
        request.url.path,
        endsWith('/api/admin/football-fields/locations'),
      );
      expect(request.headers['accept'], 'text/plain');
      return http.Response(
        jsonEncode([
          {'id': 'field-1', 'latitude': 41.323794, 'longitude': 69.417868},
          {'id': '', 'latitude': 0, 'longitude': 0},
        ]),
        200,
      );
    });

    final service = FootballFieldService(ApiClient(client: client));
    final locations = await service.getLocations();

    expect(locations, hasLength(1));
    expect(locations.single.id, 'field-1');
    expect(locations.single.latitude, 41.323794);
    expect(locations.single.longitude, 69.417868);
  });

  test('loads and parses a localized football field page', () async {
    final httpClient = MockClient((request) async {
      expect(request.url.path, endsWith('/api/football-fields'));
      expect(request.url.queryParameters['Search'], 'arena');
      expect(request.url.queryParameters['PageNumber'], '2');
      expect(request.url.queryParameters['PageSize'], '20');

      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'items': [
              {
                'id': 'field-1',
                'ownerAdminId': 'admin-1',
                'name': {'uz': 'Arena UZ', 'ru': 'Арена RU'},
                'description': {'uz': 'Tavsif', 'ru': 'Описание'},
                'address': {'uz': 'Toshkent', 'ru': 'Ташкент'},
                'location': {'latitude': 41.3, 'longitude': 69.2},
                'phoneNumber': '+998900000000',
                'opensAt': '08:00:00',
                'closesAt': '23:00:00',
                'hourlyPrice': 150000,
                'prepaymentPercent': 20,
                'prepaymentAmount': 30000,
                'currency': 'UZS',
                'image': {'id': 'image-1', 'url': '/uploads/field.jpg'},
                'isActive': true,
                'createdAt': '2026-08-24T10:00:00',
                'updatedAt': '2026-08-24T10:00:00',
                'isFavorite': true,
              },
            ],
            'pageNumber': 2,
            'pageSize': 20,
            'totalCount': 25,
            'totalPages': 2,
            'hasPreviousPage': true,
            'hasNextPage': false,
          }),
        ),
        200,
      );
    });

    final service = FootballFieldService(ApiClient(client: httpClient));
    final page = await service.getList(search: ' arena ', pageNumber: 2);

    expect(page.items, hasLength(1));
    expect(page.items.single.name.value('uz'), 'Arena UZ');
    expect(page.items.single.name.value('ru'), 'Арена RU');
    expect(page.items.single.hourlyPrice, 150000);
    expect(page.items.single.isFavorite, isTrue);
    expect(page.pageNumber, 2);
    expect(page.totalCount, 25);
    expect(page.hasNextPage, isFalse);
  });

  test(
    'adds and removes a football field favorite without reloading',
    () async {
      final methods = <String>[];
      final httpClient = MockClient((request) async {
        methods.add(request.method);
        expect(request.url.path, endsWith('/api/me/favorite-fields/field-1'));
        expect(request.headers['accept'], '*/*');
        return http.Response('', 204);
      });

      final service = FootballFieldService(ApiClient(client: httpClient));
      await service.addToFavorites('field-1');
      await service.removeFromFavorites('field-1');

      expect(methods, ['POST', 'DELETE']);
    },
  );

  test('loads favorites from the customer favorite endpoint', () async {
    final httpClient = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, endsWith('/api/me/favorite-fields'));
      expect(request.url.queryParameters['Search'], 'stadium');
      expect(request.url.queryParameters['PageNumber'], '1');
      expect(request.url.queryParameters['PageSize'], '20');
      return http.Response(
        '{"items":[],"pageNumber":1,"pageSize":20,"totalCount":0,'
        '"totalPages":0,"hasPreviousPage":false,"hasNextPage":false}',
        200,
      );
    });

    final service = FootballFieldService(ApiClient(client: httpClient));
    final page = await service.getFavorites(search: 'stadium', pageNumber: 1);

    expect(page.items, isEmpty);
    expect(page.totalCount, 0);
    expect(page.hasNextPage, isFalse);
  });

  test('loads football field details by id', () async {
    final httpClient = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, endsWith('/api/football-fields/field-1'));
      expect(request.headers['accept'], 'text/plain');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'id': 'field-1',
            'ownerAdminId': 'admin-1',
            'name': {'uz': 'Maydon', 'ru': 'Поле'},
            'description': {'uz': 'Tavsif', 'ru': 'Описание'},
            'address': {'uz': 'Manzil', 'ru': 'Адрес'},
            'location': {'latitude': 41.323794, 'longitude': 69.417868},
            'phoneNumber': '+998900000000',
            'opensAt': '08:00:00',
            'closesAt': '23:00:00',
            'hourlyPrice': 120000,
            'prepaymentPercent': 15,
            'prepaymentAmount': 18000,
            'currency': 'UZS',
            'image': null,
            'isActive': true,
            'createdAt': '2026-08-24T10:00:00',
            'updatedAt': '2026-08-24T10:00:00',
            'isFavorite': false,
          }),
        ),
        200,
      );
    });

    final service = FootballFieldService(ApiClient(client: httpClient));
    final field = await service.getById('field-1');

    expect(field.id, 'field-1');
    expect(field.location.latitude, 41.323794);
    expect(field.location.longitude, 69.417868);
    expect(field.name.value('ru'), 'Поле');
  });
}
