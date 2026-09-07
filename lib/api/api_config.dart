class ApiConfig {
  static const baseUrl = 'https://lk.7rights.ru/api/v1/driver';
  static const timeout = Duration(seconds: 20);

  static Uri path(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }
}
