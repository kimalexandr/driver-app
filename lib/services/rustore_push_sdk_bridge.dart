import 'package:flutter_rustore_push/flutter_rustore_push.dart';

/// Тонкая обёртка над `flutter_rustore_push`.
class RuStorePushSdkBridge {
  static bool _setupDone = false;
  static String? lastError;

  static void ensureSetup() {
    if (_setupDone) return;
    try {
      RustorePushClient.setup();
    } catch (error) {
      lastError = '$error';
    }
    _setupDone = true;
  }

  static Future<bool> available() async {
    ensureSetup();
    lastError = null;
    try {
      final result = await RustorePushClient.available();
      return result == true;
    } catch (error) {
      lastError = '$error';
      return false;
    }
  }

  static Future<String?> getToken() async {
    ensureSetup();
    lastError = null;
    try {
      final token = await RustorePushClient.getToken();
      final value = '$token'.trim();
      if (value.isEmpty || value == 'null') return null;
      return value;
    } catch (error) {
      lastError = '$error';
      return null;
    }
  }

  static Future<Map<String, String>?> initialMessageData() async {
    ensureSetup();
    try {
      final message = await RustorePushClient.getInitialMessage();
      return _messageData(message);
    } catch (error) {
      lastError = '$error';
      return null;
    }
  }

  static Future<void> attach({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
    void Function(Map<String, String>? data)? onOpenMessage,
    void Function(Object error)? onError,
  }) {
    ensureSetup();
    return RustorePushClient.attachCallbacks(
      onNewToken: (token) {
        final value = '$token'.trim();
        if (value.isNotEmpty && value != 'null') {
          onNewToken(value);
        }
      },
      onMessageReceived: (message) {
        if (onMessage == null) return;
        final notification = message.notification;
        onMessage(
          notification?.title?.toString(),
          notification?.body?.toString(),
          _messageData(message),
        );
      },
      onDeletedMessages: () {},
      onError: (err) {
        lastError = '$err';
        onError?.call(err);
      },
      onMessageOpenedApp: (message) {
        onOpenMessage?.call(_messageData(message));
      },
    );
  }

  static Map<String, String>? _messageData(dynamic message) {
    if (message == null) return null;
    final rawData = message.data;
    if (rawData is! Map) return null;
    return {
      for (final entry in rawData.entries)
        if (entry.key != null) '${entry.key}': '${entry.value ?? ''}',
    };
  }
}
