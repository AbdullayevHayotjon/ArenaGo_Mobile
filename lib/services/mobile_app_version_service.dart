import 'dart:convert';

import '../models/mobile_app_version_status.dart';
import 'api_client.dart';

class MobileAppVersionService {
  const MobileAppVersionService(this._apiClient);

  final ApiClient _apiClient;

  Future<MobileAppVersionStatus> getStatus({
    required String platform,
    required String version,
  }) async {
    final query = Uri(
      queryParameters: {'Platform': platform, 'Version': version},
    ).query;
    final response = await _apiClient.request(
      'GET',
      '/mobile-app-versions/status?$query',
      authenticated: false,
      headers: const {'accept': 'text/plain'},
      timeout: const Duration(seconds: 6),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MobileAppVersionException(response.statusCode);
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid mobile app version response');
    }
    if (json['isActive'] is! bool) {
      throw const FormatException('Missing isActive in version response');
    }
    return MobileAppVersionStatus.fromJson(json);
  }
}

class MobileAppVersionException implements Exception {
  const MobileAppVersionException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'MobileAppVersionException($statusCode)';
}
