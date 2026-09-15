import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Локальные уведомления (этап 1). Серверные пуши — позже.
class LocalNotifications {
  static const channelId = 'driver_alerts';
  static const channelName = 'Рейсы 7Rights';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  LocalNotifications({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Уведомления о рейсах и сроках',
        importance: Importance.high,
      ),
    );
    _ready = true;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> showTest() async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Уведомления о рейсах и сроках',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      71001,
      'Уведомления включены',
      'Тестовое сообщение приложения водителя 7Rights.',
      details,
    );
  }
}

/// Заглушка для widget-тестов без platform channels.
class FakeLocalNotifications extends LocalNotifications {
  bool permissionGranted;
  int testShown = 0;

  FakeLocalNotifications({this.permissionGranted = false});

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async {
    permissionGranted = true;
    return true;
  }

  @override
  Future<void> showTest() async {
    testShown += 1;
  }
}
