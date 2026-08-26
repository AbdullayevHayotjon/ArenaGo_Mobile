class MobileAppVersionStatus {
  const MobileAppVersionStatus({
    required this.platform,
    required this.version,
    required this.isActive,
  });

  factory MobileAppVersionStatus.fromJson(Map<String, dynamic> json) {
    return MobileAppVersionStatus(
      platform: json['platform']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }

  final String platform;
  final String version;
  final bool isActive;
}
