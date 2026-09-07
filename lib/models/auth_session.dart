import 'driver_profile.dart';

class CodeRequest {
  final String phone;
  final String? debugCode;

  const CodeRequest({
    required this.phone,
    this.debugCode,
  });
}

class AuthSession {
  final String accessToken;
  final String tokenType;
  final DriverProfile driver;

  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.driver,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('В ответе нет access_token');
    }
    return AuthSession(
      accessToken: token,
      tokenType: '${json['token_type'] ?? 'Bearer'}',
      driver: DriverProfile.fromJson(json),
    );
  }
}
