import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureKv {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class MemorySecureKv implements SecureKv {
  final Map<String, String> _data;

  MemorySecureKv([Map<String, String>? data]) : _data = data ?? {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }
}

class FlutterSecureKv implements SecureKv {
  final FlutterSecureStorage _storage;

  FlutterSecureKv({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
