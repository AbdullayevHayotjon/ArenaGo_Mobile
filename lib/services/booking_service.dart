import 'dart:convert';

import '../models/booking.dart';
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

  Future<Booking> create({
    required String footballFieldId,
    required String date,
    required String startTime,
  }) async {
    final response = await _apiClient.request(
      'POST',
      '/bookings',
      headers: const {'accept': 'text/plain'},
      body: {
        'footballFieldId': footballFieldId,
        'date': date,
        'startTime': startTime,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BookingException(
        statusCode: response.statusCode,
        message: _problemMessage(response.bodyBytes),
      );
    }

    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) throw const FormatException();
      return Booking.fromJson(json);
    } on FormatException {
      throw const BookingException(code: 'invalid_response');
    }
  }
}

class BookingException implements Exception {
  const BookingException({
    this.code = 'request_failed',
    this.statusCode,
    this.message,
  });

  final String code;
  final int? statusCode;
  final String? message;
}

String? _problemMessage(List<int> bodyBytes) {
  try {
    final json = jsonDecode(utf8.decode(bodyBytes));
    if (json is Map<String, dynamic>) {
      for (final key in ['detail', 'title', 'message']) {
        final value = json[key]?.toString().trim();
        if (value?.isNotEmpty == true) return value;
      }
    }
  } catch (_) {}
  return null;
}
