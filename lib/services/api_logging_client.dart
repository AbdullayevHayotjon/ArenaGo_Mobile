import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiLoggingClient extends http.BaseClient {
  ApiLoggingClient({http.Client? inner}) : _inner = inner ?? http.Client();

  static const _maxLoggedResponseBytes = 256 * 1024;
  static int _lastRequestId = 0;

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!kDebugMode) return _inner.send(request);

    final requestId = ++_lastRequestId;
    final stopwatch = Stopwatch()..start();
    _logRequest(requestId, request);

    try {
      final response = await _inner.send(request);
      final contentType = response.headers['content-type'] ?? '';
      final canLogBody =
          _isTextResponse(contentType) &&
          (response.contentLength == null ||
              response.contentLength! <= _maxLoggedResponseBytes);

      if (!canLogBody) {
        stopwatch.stop();
        _logResponse(requestId, response, stopwatch.elapsed, null);
        return response;
      }

      final bytes = await response.stream.toBytes();
      stopwatch.stop();
      final body = utf8.decode(bytes, allowMalformed: true);
      _logResponse(requestId, response, stopwatch.elapsed, body);

      return http.StreamedResponse(
        Stream<List<int>>.value(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      _write([
        '[API #$requestId] ERROR (${stopwatch.elapsedMilliseconds} ms)',
        error.toString(),
        stackTrace.toString(),
      ]);
      rethrow;
    }
  }

  @override
  void close() => _inner.close();

  void _logRequest(int requestId, http.BaseRequest request) {
    Object? body;
    if (request is http.Request && request.body.isNotEmpty) {
      body = _decodePayload(request.body);
    } else if (request is http.MultipartRequest) {
      body = {
        ...request.fields,
        'files': request.files
            .map(
              (file) => {
                'field': file.field,
                'filename': file.filename,
                'length': file.length,
              },
            )
            .toList(),
      };
    }

    _write([
      '[API #$requestId] REQUEST',
      '${request.method} ${request.url}',
      'Headers: ${_pretty(_redact(request.headers))}',
      if (body != null) 'Body: ${_pretty(_redact(body))}',
    ]);
  }

  void _logResponse(
    int requestId,
    http.StreamedResponse response,
    Duration elapsed,
    String? body,
  ) {
    _write([
      '[API #$requestId] RESPONSE ${response.statusCode} '
          '(${elapsed.inMilliseconds} ms)',
      'Headers: ${_pretty(_redact(response.headers))}',
      if (body != null && body.isNotEmpty)
        'Body: ${_pretty(_redact(_decodePayload(body)))}'
      else if (body == null)
        'Body: <binary or larger than 256 KB>',
    ]);
  }

  bool _isTextResponse(String contentType) {
    final type = contentType.toLowerCase();
    return type.isEmpty ||
        type.contains('json') ||
        type.contains('text') ||
        type.contains('xml');
  }

  Object? _decodePayload(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  Object? _redact(Object? value, [String? parentKey]) {
    if (parentKey != null && _isSecretKey(parentKey)) return '<hidden>';
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _redact(item, key.toString())),
      );
    }
    if (value is Iterable) {
      return value.map((item) => _redact(item)).toList();
    }
    return value;
  }

  bool _isSecretKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return normalized.contains('password') ||
        normalized.contains('token') ||
        normalized == 'authorization';
  }

  String _pretty(Object? value) {
    if (value is Map || value is Iterable) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

  void _write(List<String> lines) {
    for (final line in lines) {
      debugPrint(line);
    }
  }
}
