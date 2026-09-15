import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/notification_prefs.dart';
import 'package:phone_auth_app/services/notification_prefs_store.dart';
import 'package:phone_auth_app/services/secure_kv.dart';

void main() {
  test('NotificationPrefsStore сохраняет и читает настройки', () async {
    final store = NotificationPrefsStore(kv: MemorySecureKv());
    expect(await store.read('d1'), NotificationPrefs.defaults);

    const prefs = NotificationPrefs(
      enabled: true,
      newTrips: false,
      statusChanges: true,
      dispatcher: false,
      deadlines: true,
    );
    await store.write('d1', prefs);

    final loaded = await store.read('d1');
    expect(loaded.enabled, isTrue);
    expect(loaded.newTrips, isFalse);
    expect(loaded.statusChanges, isTrue);
    expect(loaded.dispatcher, isFalse);
    expect(loaded.deadlines, isTrue);
    expect(await store.read('other'), NotificationPrefs.defaults);
  });

  test('NotificationPrefs.fromJson терпим к битым данным', () {
    final prefs = NotificationPrefs.fromJson({
      'enabled': 'true',
      'new_trips': 0,
      'status_changes': 'false',
    });
    expect(prefs.enabled, isTrue);
    expect(prefs.newTrips, isTrue);
    expect(prefs.statusChanges, isFalse);
  });
}
