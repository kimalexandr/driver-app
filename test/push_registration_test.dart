import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/api/mock_driver_api.dart';
import 'package:phone_auth_app/models/notification_prefs.dart';
import 'package:phone_auth_app/services/local_notifications.dart';
import 'package:phone_auth_app/services/notification_prefs_store.dart';
import 'package:phone_auth_app/services/push_registration.dart';
import 'package:phone_auth_app/services/rustore_push_gateway.dart';
import 'package:phone_auth_app/services/secure_kv.dart';

void main() {
  test('PushRegistration регистрирует RuStore-токен на API', () async {
    final kv = MemorySecureKv();
    final gateway = FakeRuStorePushGateway(token: 'tok-1');
    final push = PushRegistration(
      prefsStore: NotificationPrefsStore(kv: kv),
      notifications: FakeLocalNotifications(permissionGranted: true),
      rustore: gateway,
      kv: kv,
    );
    final api = MockDriverApi();

    await push.sync(api: api, owner: 'd1');

    expect(push.lastToken, 'tok-1');
    expect(push.lastStatus, 'RuStore Push подключён');
    expect(gateway.listenCalls, 1);
  });

  test('PushRegistration сохраняет prefs локально и на API', () async {
    final kv = MemorySecureKv();
    final store = NotificationPrefsStore(kv: kv);
    final push = PushRegistration(
      prefsStore: store,
      notifications: FakeLocalNotifications(permissionGranted: true),
      rustore: FakeRuStorePushGateway(),
      kv: kv,
    );

    const prefs = NotificationPrefs(enabled: true, newTrips: false);
    await push.savePrefs('d1', prefs, api: MockDriverApi());
    expect(await store.read('d1'), prefs);
  });
}
