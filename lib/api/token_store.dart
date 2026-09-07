import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStore {
  Future<String?> get accessToken;
  Future<void> saveAccessToken(String accessToken);
  Future<void> clear();
}

class MemoryTokenStore implements TokenStore {
  String? _access;

  @override
  Future<String?> get accessToken async => _access;

  @override
  Future<void> saveAccessToken(String accessToken) async {
    _access = accessToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
  }
}

class SecureTokenStore implements TokenStore {
  static const _accessKey = 'driver_access_token';

  final FlutterSecureStorage _storage;

  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> get accessToken => _storage.read(key: _accessKey);

  @override
  Future<void> saveAccessToken(String accessToken) {
    return _storage.write(key: _accessKey, value: accessToken);
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _accessKey);
  }
}
