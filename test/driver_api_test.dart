import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phone_auth_app/api/api_client.dart';
import 'package:phone_auth_app/api/api_exception.dart';
import 'package:phone_auth_app/api/driver_api.dart';
import 'package:phone_auth_app/api/mock_driver_api.dart';
import 'package:phone_auth_app/api/token_store.dart';
import 'package:phone_auth_app/services/phone.dart';

void main() {
  test('нормализует телефон в 79991234567', () {
    expect(normalizePhone('8 (999) 123-45-67'), '79991234567');
    expect(normalizePhone('+7 999 123-45-67'), '79991234567');
    expect(normalizePhone('79991234567'), '79991234567');
  });

  test('mock выдаёт debug_code и пускает с кодом 1234', () async {
    final api = MockDriverApi();
    final challenge = await api.requestCode('79991234567');
    expect(challenge.debugCode, '1234');

    await expectLater(
      api.verifyCode(phone: '79991234567', code: '0000'),
      throwsA(isA<ApiException>()),
    );

    final session = await api.verifyCode(phone: '79991234567', code: '1234');
    expect(session.accessToken, isNotEmpty);
    expect(session.driver.name, isNotEmpty);
  });

  test('HTTP клиент читает message из 422', () async {
    final store = MemoryTokenStore();
    final client = ApiClient(
      tokenStore: store,
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/driver/auth/request-code');
        expect(request.headers['Accept'], 'application/json');
        return http.Response(
          jsonEncode({'status': 'error', 'message': 'Водитель с таким телефоном не найден'}),
          422,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final api = HttpDriverApi(client);

    await expectLater(
      api.requestCode('79991234567'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Водитель с таким телефоном не найден',
        ),
      ),
    );
  });

  test('401 очищает токен', () async {
    final store = MemoryTokenStore();
    await store.saveAccessToken('old-token');
    var unauthorized = false;
    final client = ApiClient(
      tokenStore: store,
      onUnauthorized: () async {
        unauthorized = true;
      },
      httpClient: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer old-token');
        return http.Response('Unauthorized', 401);
      }),
    );

    await expectLater(client.get('/me'), throwsA(isA<ApiException>()));
    expect(await store.accessToken, isNull);
    expect(unauthorized, isTrue);
  });

  test('не JSON отвечает понятной ошибкой', () async {
    final client = ApiClient(
      tokenStore: MemoryTokenStore(),
      httpClient: MockClient((request) async {
        return http.Response('<html>oops</html>', 200);
      }),
    );

    await expectLater(
      client.get('/trips'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Сервер вернул некорректный ответ',
        ),
      ),
    );
  });
}
