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
  }) async {
    final query = <String, String>{
      'PageNumber': '$pageNumber',
      'PageSize': '$pageSize',
    };
    final normalizedSearch = search?.trim() ?? '';
    if (normalizedSearch.isNotEmpty) query['Search'] = normalizedSearch;

    final queryString = Uri(queryParameters: query).query;
    final response = await _apiClient.request(
      'GET',
      '/football-fields?$queryString',
    );

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
}

class FootballFieldException implements Exception {
  const FootballFieldException({this.code = 'request_failed', this.statusCode});

  final String code;
  final int? statusCode;
}
