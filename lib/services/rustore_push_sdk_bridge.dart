import 'package:flutter_rustore_push/flutter_rustore_push.dart';

/// Тонкая обёртка над `flutter_rustore_push`.
class RuStorePushSdkBridge {
  static Future<bool> available() async {
    final result = await RustorePushClient.available();
    return result == true;
  }

  static Future<String?> getToken() async {
    final token = await RustorePushClient.getToken();
    if (token is! String || token.isEmpty) return null;
    return token;
  }

  static Future<void> attach({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
  }) {
    return RustorePushClient.attachCallbacks(
      onNewToken: (token) {
        if (token is String && token.isNotEmpty) {
          onNewToken(token);
        }
      },
      onMessageReceived: (message) {
        if (onMessage == null) return;
        final notification = message.notification;
        final rawData = message.data;
        Map<String, String>? data;
        if (rawData is Map) {
          data = {
            for (final entry in rawData.entries)
              if (entry.key != null) '${entry.key}': '${entry.value ?? ''}',
          };
        }
        onMessage(
          notification?.title?.toString(),
          notification?.body?.toString(),
          data,
        );
      },
      onDeletedMessages: () {},
      onError: (_) {},
      onMessageOpenedApp: (_) {},
    );
  }
}
