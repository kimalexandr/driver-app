import 'package:flutter_rustore_push/flutter_rustore_push.dart';

/// Тонкая обёртка над `flutter_rustore_push`.
class RuStorePushSdkBridge {
  static Future<bool> available() async {
    final result = await RustorePushClient.available();
    return result == true;
  }

  static Future<String?> getToken() async {
    final token = await RustorePushClient.getToken();
    if (token.isEmpty) return null;
    return token;
  }

  static Future<Map<String, String>?> initialMessageData() async {
    final message = await RustorePushClient.getInitialMessage();
    return _messageData(message);
  }

  static Future<void> attach({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
    void Function(Map<String, String>? data)? onOpenMessage,
  }) {
    return RustorePushClient.attachCallbacks(
      onNewToken: (token) {
        final value = '$token';
        if (value.isNotEmpty) {
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
      onError: (_) {},
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
