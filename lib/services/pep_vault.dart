import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/external_auth.dart';
import '../models/pep.dart';
import 'secure_kv.dart';

class PepVault {
  static const _secretPrefix = 'pep.v1.secret.';
  static const _metaPrefix = 'pep.v1.meta.';
  static const _linksKey = 'identity.v1.providers';

  final SecureKv kv;
  final DateTime Function() _now;
  final Random _random;

  PepVault({
    SecureKv? kv,
    DateTime Function()? now,
    Random? random,
  })  : kv = kv ?? FlutterSecureKv(),
        _now = now ?? DateTime.now,
        _random = random ?? Random.secure();

  Future<PepRecord?> read(String driverId) async {
    final raw = await kv.read(_metaPrefix + driverId);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      return PepRecord.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return null;
    }
  }

  Future<PepRecord> issue({
    required String driverId,
    AuthProviderKind via = AuthProviderKind.sms,
  }) async {
    final id = driverId.trim().isEmpty ? 'local' : driverId.trim();
    final secret = List<int>.generate(32, (_) => _random.nextInt(256));
    final digest = sha256.convert(secret);
    final kid = digest.toString().substring(0, 16);
    final record = PepRecord(
      kid: kid,
      driverId: id,
      thumbprint: digest.toString(),
      issuedAt: _now().toUtc(),
      issuedVia: via,
    );
    await kv.write(_secretPrefix + id, base64Encode(secret));
    await kv.write(_metaPrefix + id, jsonEncode(record.toJson()));
    await linkProvider(via);
    return record;
  }

  Future<void> revoke(String driverId) async {
    final id = driverId.trim().isEmpty ? 'local' : driverId.trim();
    await kv.delete(_secretPrefix + id);
    await kv.delete(_metaPrefix + id);
  }

  Future<PepSignature> sign({
    required String driverId,
    required String payload,
  }) async {
    final id = driverId.trim().isEmpty ? 'local' : driverId.trim();
    final record = await read(id);
    final secretRaw = await kv.read(_secretPrefix + id);
    if (record == null || secretRaw == null || secretRaw.isEmpty) {
      throw StateError('ПЭП не выпущена на этом устройстве');
    }
    final secret = base64Decode(secretRaw);
    final signedAt = _now().toUtc();
    final canonical = '${record.kid}.${signedAt.toIso8601String()}.$payload';
    final signature = Hmac(sha256, secret).convert(utf8.encode(canonical));
    return PepSignature(
      kid: record.kid,
      payload: payload,
      signature: base64UrlEncode(signature.bytes),
      signedAt: signedAt,
      algorithm: record.algorithm,
    );
  }

  Future<Set<AuthProviderKind>> linkedProviders() async {
    final raw = await kv.read(_linksKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded
          .map((item) => AuthProviderKind.tryParse('$item'))
          .whereType<AuthProviderKind>()
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> linkProvider(AuthProviderKind provider) async {
    final current = await linkedProviders();
    current.add(provider);
    await kv.write(
      _linksKey,
      jsonEncode(current.map((item) => item.id).toList()..sort()),
    );
  }
}
