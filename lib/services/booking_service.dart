import 'dart:convert';

import '../models/field_availability_slot.dart';
import 'api_client.dart';

class BookingService {
  const BookingService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<FieldAvailabilitySlot>> getAvailability({
    required String footballFieldId,
    required String from,
    required String to,
  }) async {
    final query = Uri(queryParameters: {'From': from, 'To': to}).query;
    final response = await _apiClient.request(
      'GET',
      '/football-fields/${Uri.encodeComponent(footballFieldId)}/availability?$query',
      headers: const {'accept': 'text/plain'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingException(statusCode: response.statusCode);
    }

    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! List) throw const FormatException();
      return json
          .whereType<Map<String, dynamic>>()
          .map(FieldAvailabilitySlot.fromJson)
          .toList(growable: false);
    } on FormatException {
      throw const BookingException(code: 'invalid_response');
    }
  }
}

class BookingException implements Exception {
  const BookingException({this.code = 'request_failed', this.statusCode});

  final String code;
  final int? statusCode;
}
