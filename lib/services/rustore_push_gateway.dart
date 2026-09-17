/// Абстракция над RuStore Push SDK (удобно подменять в тестах).
abstract class RuStorePushGateway {
  Future<bool> available();

  Future<String?> getToken();

  Future<Map<String, String>?> initialMessageData();

  Future<void> listen({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
    void Function(Map<String, String>? data)? onOpenMessage,
  });
}

class NoOpRuStorePushGateway implements RuStorePushGateway {
  @override
  Future<bool> available() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<Map<String, String>?> initialMessageData() async => null;

  @override
  Future<void> listen({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
    void Function(Map<String, String>? data)? onOpenMessage,
  }) async {}
}

class FakeRuStorePushGateway implements RuStorePushGateway {
  FakeRuStorePushGateway({
    this.availableValue = true,
    this.token = 'fake-rustore-token',
    this.initialData,
  });

  bool availableValue;
  String? token;
  Map<String, String>? initialData;
  int listenCalls = 0;

  @override
  Future<bool> available() async => availableValue;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<Map<String, String>?> initialMessageData() async => initialData;

  @override
  Future<void> listen({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
    void Function(Map<String, String>? data)? onOpenMessage,
  }) async {
    listenCalls += 1;
    final current = token;
    if (current != null && current.isNotEmpty) {
      onNewToken(current);
    }
  }
}
