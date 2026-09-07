import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  final TokenStore tokenStore;
  final http.Client _http;
  Future<void> Function()? onUnauthorized;

  ApiClient({
    required this.tokenStore,
    http.Client? httpClient,
    this.onUnauthorized,
  }) : _http = httpClient ?? http.Client();

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) {
    return _send(method: 'GET', uri: ApiConfig.path(path), auth: auth);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _send(
      method: 'POST',
      uri: ApiConfig.path(path),
      body: body,
      auth: auth,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send(
      method: 'PATCH',
      uri: ApiConfig.path(path),
      body: body,
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
  }) async {
    try {
      final request = http.MultipartRequest('POST', ApiConfig.path(path));
      request.headers.addAll(await _headers(auth: true, json: false));
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      final streamed = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed);
      return await _decode(response);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw _mapTransportError(error);
    }
  }

  Future<Map<String, dynamic>> _send({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final headers = await _headers(auth: auth);
      final encoded = body == null ? null : jsonEncode(body);
      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers).timeout(ApiConfig.timeout);
        case 'POST':
          response = await _http
              .post(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.timeout);
        case 'PATCH':
          response = await _http
              .patch(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.timeout);
        default:
          throw ApiException('Неподдерживаемый метод $method');
      }
      return await _decode(response);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw _mapTransportError(error);
    }
  }

  Future<Map<String, String>> _headers({
    required bool auth,
    bool json = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await tokenStore.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    if (response.statusCode == 401) {
      await tokenStore.clear();
      await onUnauthorized?.call();
      throw const ApiException('Сессия истекла', statusCode: 401);
    }

    final body = _parseJson(response.body);
    if (response.statusCode >= 400) {
      throw ApiException.fromBody(response.statusCode, body);
    }
    return body;
  }

  Map<String, dynamic> _parseJson(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      if (decoded is List) return {'data': decoded};
    } on FormatException {
      throw const ApiException('Сервер вернул некорректный ответ');
    }
    throw const ApiException('Сервер вернул некорректный ответ');
  }

  ApiException _mapTransportError(Object error) {
    if (error is TimeoutException) {
      return const ApiException('Превышено время ожидания сервера');
    }
    if (error is SocketException || error is http.ClientException) {
      return const ApiException('Нет соединения с сетью');
    }
    if (error is ApiException) return error;
    return const ApiException('Не удалось выполнить запрос');
  }
}
