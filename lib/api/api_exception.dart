class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromBody(int statusCode, Object? body) {
    if (body is Map && body['message'] is String) {
      return ApiException(body['message'] as String, statusCode: statusCode);
    }
    return ApiException(
      'Ошибка сервера ($statusCode)',
      statusCode: statusCode,
    );
  }

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
