class AuthSession {
  const AuthSession({
    required this.userId,
    required this.firstName,
    required this.phoneNumber,
    required this.preferredLanguage,
    required this.role,
    required this.accessToken,
    required this.expiresAtUtc,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  final String userId;
  final String firstName;
  final String phoneNumber;
  final String preferredLanguage;
  final String role;
  final String accessToken;
  final String expiresAtUtc;
  final String refreshToken;
  final String refreshTokenExpiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    userId: json['userId'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String? ?? '',
    preferredLanguage: json['preferredLanguage'] as String? ?? 'uzbek',
    role: json['role'] as String? ?? '',
    accessToken: json['accessToken'] as String? ?? '',
    expiresAtUtc: json['expiresAtUtc'] as String? ?? '',
    refreshToken: json['refreshToken'] as String? ?? '',
    refreshTokenExpiresAt: json['refreshTokenExpiresAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'firstName': firstName,
    'phoneNumber': phoneNumber,
    'preferredLanguage': preferredLanguage,
    'role': role,
    'accessToken': accessToken,
    'expiresAtUtc': expiresAtUtc,
    'refreshToken': refreshToken,
    'refreshTokenExpiresAt': refreshTokenExpiresAt,
  };
}
