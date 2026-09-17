/// Абстракция над RuStore Push SDK (удобно подменять в тестах).
abstract class RuStorePushGateway {
  Future<bool> available();

  Future<String?> getToken();

  Future<void> listen({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
  });
}

class NoOpRuStorePushGateway implements RuStorePushGateway {
  @override
  Future<bool> available() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> listen({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
  }) async {}
}

class FakeRuStorePushGateway implements RuStorePushGateway {
  FakeRuStorePushGateway({
    this.availableValue = true,
    this.token = 'fake-rustore-token',
  });

  bool availableValue;
  String? token;
  int listenCalls = 0;

  @override
  Future<bool> available() async => availableValue;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> listen({
    required void Function(String token) onNewToken,
    void Function(String? title, String? body, Map<String, String>? data)?
        onMessage,
  }) async {
    listenCalls += 1;
    final current = token;
    if (current != null && current.isNotEmpty) {
      onNewToken(current);
    }
  }
}
