import 'dart:convert';

import '../models/football_field.dart';
import 'api_client.dart';

class FootballFieldService {
  const FootballFieldService(this._apiClient);

  final ApiClient _apiClient;

  Future<FootballFieldPage> getList({
    String? search,
    required int pageNumber,
    int pageSize = 20,
  }) {
    return _getPage(
      '/football-fields',
      search: search,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  Future<FootballFieldPage> getFavorites({
    String? search,
    required int pageNumber,
    int pageSize = 20,
  }) {
    return _getPage(
      '/me/favorite-fields',
      search: search,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  Future<FootballField> getById(String footballFieldId) async {
    final response = await _apiClient.request(
      'GET',
      '/football-fields/${Uri.encodeComponent(footballFieldId)}',
      headers: const {'accept': 'text/plain'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FootballFieldException(statusCode: response.statusCode);
    }

    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) throw const FormatException();
      return FootballField.fromJson(json);
    } on FormatException {
      throw const FootballFieldException(code: 'invalid_response');
    }
  }

  Future<FootballFieldPage> _getPage(
    String path, {
    String? search,
    required int pageNumber,
    required int pageSize,
  }) async {
    final query = <String, String>{
      'PageNumber': '$pageNumber',
      'PageSize': '$pageSize',
    };
    final normalizedSearch = search?.trim() ?? '';
    if (normalizedSearch.isNotEmpty) query['Search'] = normalizedSearch;

    final queryString = Uri(queryParameters: query).query;
    final response = await _apiClient.request('GET', '$path?$queryString');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FootballFieldException(statusCode: response.statusCode);
    }

    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) throw const FormatException();
      return FootballFieldPage.fromJson(json);
    } on FormatException {
      throw const FootballFieldException(code: 'invalid_response');
    }
  }

  Future<void> addToFavorites(String footballFieldId) {
    return _changeFavorite('POST', footballFieldId);
  }

  Future<void> removeFromFavorites(String footballFieldId) {
    return _changeFavorite('DELETE', footballFieldId);
  }

  Future<void> _changeFavorite(String method, String footballFieldId) async {
    final response = await _apiClient.request(
      method,
      '/me/favorite-fields/${Uri.encodeComponent(footballFieldId)}',
      headers: const {'accept': '*/*'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FootballFieldException(statusCode: response.statusCode);
    }
  }
}

class FootballFieldException implements Exception {
  const FootballFieldException({this.code = 'request_failed', this.statusCode});

  final String code;
  final int? statusCode;
}
