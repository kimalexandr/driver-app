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
    final api = _TrackingApi();
    final push = PushRegistration(
      prefsStore: NotificationPrefsStore(kv: kv),
      notifications: FakeLocalNotifications(permissionGranted: true),
      rustore: gateway,
      kv: kv,
    );

    await push.sync(api: api, owner: 'd1');

    expect(push.lastToken, 'tok-1');
    expect(push.lastStatus, 'RuStore Push подключён');
    expect(gateway.listenCalls, 1);
    expect(api.registerCalls, greaterThanOrEqualTo(1));
    expect(api.lastToken, 'tok-1');
  });

  test('PushRegistration запрашивает разрешение и всё равно регистрирует токен',
      () async {
    final kv = MemorySecureKv();
    final notifications = FakeLocalNotifications(permissionGranted: false);
    final api = _TrackingApi();
    final push = PushRegistration(
      prefsStore: NotificationPrefsStore(kv: kv),
      notifications: notifications,
      rustore: FakeRuStorePushGateway(token: 'tok-2'),
      kv: kv,
    );

    await push.sync(api: api, owner: '155');

    expect(notifications.permissionGranted, isTrue);
    expect(api.registerCalls, greaterThanOrEqualTo(1));
    expect(api.lastToken, 'tok-2');
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

  test('PushRegistration открывает рейс по trip_id из пуша', () async {
    final kv = MemorySecureKv();
    String? opened;
    final push = PushRegistration(
      prefsStore: NotificationPrefsStore(kv: kv),
      notifications: FakeLocalNotifications(permissionGranted: true),
      rustore: FakeRuStorePushGateway(
        initialData: {'trip_id': 'trip-42'},
      ),
      kv: kv,
      onOpenTrip: (id) => opened = id,
    );

    await push.sync(api: MockDriverApi(), owner: 'd1');
    expect(opened, 'trip-42');
  });
}

class _TrackingApi extends MockDriverApi {
  int registerCalls = 0;
  String? lastToken;

  @override
  Future<void> registerDevice({
    required String token,
    required NotificationPrefs prefs,
    String provider = 'rustore',
    String platform = 'android',
    String? appVersion,
  }) async {
    registerCalls += 1;
    lastToken = token;
  }
}
