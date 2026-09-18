import 'package:flutter/foundation.dart';

import 'rustore_push_gateway.dart';
import 'rustore_push_sdk_bridge.dart';

/// Реальный RuStore Push SDK. На не-Android — no-op.
class SdkRuStorePushGateway implements RuStorePushGateway {
  bool _listening = false;

  @override
  Future<bool> available() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await RuStorePushSdkBridge.available();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await RuStorePushSdkBridge.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, String>?> initialMessageData() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await RuStorePushSdkBridge.initialMessageData();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> listen({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
    void Function(Map<String, String>? data)? onOpenMessage,
  }) async {
    if (_listening) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _listening = true;
    try {
      await RuStorePushSdkBridge.attach(
        onNewToken: onNewToken,
        onMessage: onMessage,
        onOpenMessage: onOpenMessage,
        onError: (error) {
          RuStorePushSdkBridge.lastError = '$error';
        },
      );
    } catch (error) {
      _listening = false;
      RuStorePushSdkBridge.lastError = '$error';
    }
  }
}
