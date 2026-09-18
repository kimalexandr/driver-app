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
  bool _listening = false;

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

  /// После логина / restore: запросить разрешение, получить токен, POST /me/device.
  Future<void> sync({
    required DriverApi api,
    required String owner,
  }) async {
    if (owner.trim().isEmpty) {
      lastStatus = 'Нет id водителя';
      return;
    }

    await notifications.init();

    final prefs = await prefsStore.read(owner);
    if (!prefs.enabled) {
      lastStatus = 'Уведомления выключены в настройках';
      return;
    }

    var permission = await notifications.hasPermission();
    if (!permission) {
      permission = await notifications.requestPermission();
    }
    // Токен регистрируем даже без разрешения показа: иначе /me/device
    // никогда не вызывается, и серверу некуда слать пуш.

    await _ensureListen(api: api, owner: owner);

    final initial = await rustore.initialMessageData();
    final initialTripId = _tripIdFrom(initial);
    if (initialTripId != null) {
      onOpenTrip?.call(initialTripId);
    }

    final token = await _waitForToken();
    if (token == null || token.isEmpty) {
      final available = await rustore.available();
      lastStatus = available
          ? 'Не удалось получить push-токен'
          : 'RuStore Push недоступен на устройстве';
      if (!permission) {
        lastStatus = 'Нет разрешения ОС и нет push-токена';
      }
      return;
    }

    await _registerToken(api: api, owner: owner, token: token);
    if (!permission) {
      lastStatus = 'Токен зарегистрирован, включите уведомления в ОС';
    }
  }

  Future<void> _ensureListen({
    required DriverApi api,
    required String owner,
  }) async {
    if (_listening) return;
    _listening = true;
    try {
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
    } catch (_) {
      _listening = false;
    }
  }

  Future<String?> _waitForToken() async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final token = await rustore.getToken();
      if (token != null && token.isNotEmpty) return token;
      if (lastToken != null && lastToken!.isNotEmpty) return lastToken;
      await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
    }
    final fallback = await rustore.getToken();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return lastToken;
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
