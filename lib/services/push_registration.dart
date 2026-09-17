import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../models/notification_prefs.dart';
import 'local_notifications.dart';
import 'notification_prefs_store.dart';
import 'rustore_push_gateway.dart';
import 'rustore_push_sdk_gateway.dart';
import 'secure_kv.dart';

/// Регистрация RuStore push-токена и синхронизация prefs с бэкендом.
class PushRegistration {
  static const _tokenKeyPrefix = 'notify.rustore.token.v1.';

  final NotificationPrefsStore prefsStore;
  final LocalNotifications notifications;
  final RuStorePushGateway rustore;
  final SecureKv _kv;
  final String appVersion;

  /// Вызывается при открытии пуша (tap) или cold-start с trip_id.
  void Function(String tripId)? onOpenTrip;

  String? lastStatus;
  String? lastToken;

  PushRegistration({
    NotificationPrefsStore? prefsStore,
    LocalNotifications? notifications,
    RuStorePushGateway? rustore,
    SecureKv? kv,
    this.appVersion = '1.0.3',
    this.onOpenTrip,
  })  : prefsStore = prefsStore ?? NotificationPrefsStore(),
        notifications = notifications ?? LocalNotifications(),
        rustore = rustore ??
            (kIsWeb || defaultTargetPlatform != TargetPlatform.android
                ? NoOpRuStorePushGateway()
                : SdkRuStorePushGateway()),
        _kv = kv ?? FlutterSecureKv();

  Future<NotificationPrefs> currentPrefs(String owner) {
    return prefsStore.read(owner);
  }

  Future<void> savePrefs(
    String owner,
    NotificationPrefs prefs, {
    DriverApi? api,
  }) async {
    await prefsStore.write(owner, prefs);
    if (api == null) return;
    try {
      await api.updateNotificationPrefs(prefs);
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 501) return;
    } catch (_) {}
  }

  Future<bool> ensurePermission() {
    return notifications.requestPermission();
  }

  Future<bool> hasPermission() {
    return notifications.hasPermission();
  }

  Future<void> sync({
    required DriverApi api,
    required String owner,
  }) async {
    final prefs = await prefsStore.read(owner);
    final permission = await notifications.hasPermission();
    if (!permission || !prefs.enabled) {
      lastStatus = permission
          ? 'Уведомления выключены в настройках'
          : 'Нет разрешения ОС';
      return;
    }

    final available = await rustore.available();
    if (!available) {
      lastStatus = 'RuStore Push недоступен на устройстве';
      return;
    }

    await rustore.listen(
      onNewToken: (token) {
        lastToken = token;
        // ignore: discarded_futures
        _registerToken(api: api, owner: owner, token: token);
      },
      onMessage: (title, body, data) async {
        await notifications.showRemote(
          title: title ?? '7Rights',
          body: body ?? '',
        );
      },
      onOpenMessage: (data) {
        final tripId = _tripIdFrom(data);
        if (tripId != null) {
          onOpenTrip?.call(tripId);
        }
      },
    );

    final initial = await rustore.initialMessageData();
    final initialTripId = _tripIdFrom(initial);
    if (initialTripId != null) {
      onOpenTrip?.call(initialTripId);
    }

    final token = await rustore.getToken();
    if (token == null || token.isEmpty) {
      lastStatus = 'Не удалось получить push-токен';
      return;
    }
    await _registerToken(api: api, owner: owner, token: token);
  }

  Future<void> unregister({
    required DriverApi api,
    required String owner,
  }) async {
    final token = lastToken ?? await _kv.read('$_tokenKeyPrefix$owner');
    if (token == null || token.isEmpty) return;
    try {
      await api.unregisterDevice(token: token);
    } catch (_) {}
    await _kv.delete('$_tokenKeyPrefix$owner');
    lastToken = null;
    lastStatus = 'Токен снят';
  }

  String? _tripIdFrom(Map<String, String>? data) {
    if (data == null) return null;
    final tripId = (data['trip_id'] ?? data['tripId'] ?? '').trim();
    return tripId.isEmpty ? null : tripId;
  }

  Future<void> _registerToken({
    required DriverApi api,
    required String owner,
    required String token,
  }) async {
    final prefs = await prefsStore.read(owner);
    lastToken = token;
    await _kv.write('$_tokenKeyPrefix$owner', token);
    try {
      await api.registerDevice(
        token: token,
        prefs: prefs,
        platform: defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : 'unknown',
        appVersion: appVersion,
      );
      lastStatus = 'RuStore Push подключён';
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 501) {
        lastStatus = 'Сервер ещё без push API';
        return;
      }
      lastStatus = 'Ошибка регистрации: ${error.message}';
    } catch (_) {
      lastStatus = 'Ошибка регистрации токена';
    }
  }
}
