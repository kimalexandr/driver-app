import '../models/notification_prefs.dart';
import 'local_notifications.dart';
import 'notification_prefs_store.dart';

/// Точка расширения под FCM / RuStore Push на следующем этапе.
/// Сейчас только разрешение ОС и локальные предпочтения, без сети.
class PushRegistration {
  final NotificationPrefsStore prefsStore;
  final LocalNotifications notifications;

  PushRegistration({
    NotificationPrefsStore? prefsStore,
    LocalNotifications? notifications,
  })  : prefsStore = prefsStore ?? NotificationPrefsStore(),
        notifications = notifications ?? LocalNotifications();

  Future<NotificationPrefs> currentPrefs(String owner) {
    return prefsStore.read(owner);
  }

  Future<void> savePrefs(String owner, NotificationPrefs prefs) {
    return prefsStore.write(owner, prefs);
  }

  Future<bool> ensurePermission() {
    return notifications.requestPermission();
  }

  Future<bool> hasPermission() {
    return notifications.hasPermission();
  }
}
