import 'dart:convert';

import '../models/notification_prefs.dart';
import 'secure_kv.dart';

class NotificationPrefsStore {
  static const _keyPrefix = 'notify.prefs.v1.';

  final SecureKv _kv;

  NotificationPrefsStore({SecureKv? kv}) : _kv = kv ?? FlutterSecureKv();

  Future<NotificationPrefs> read(String owner) async {
    final raw = await _kv.read('$_keyPrefix$owner');
    if (raw == null || raw.isEmpty) return NotificationPrefs.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return NotificationPrefs.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return NotificationPrefs.defaults;
  }

  Future<void> write(String owner, NotificationPrefs prefs) {
    return _kv.write('$_keyPrefix$owner', jsonEncode(prefs.toJson()));
  }
}
