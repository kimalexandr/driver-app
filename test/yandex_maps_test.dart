import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/services/yandex_maps.dart';

void main() {
  test('точка открывается через text=', () {
    final url = yandexPlaceUrl('Санкт-Петербург, Невский проспект, 1');
    final uri = Uri.parse(url);

    expect(url, startsWith('https://yandex.ru/maps/?text='));
    expect(uri.queryParameters['text'], 'Санкт-Петербург, Невский проспект, 1');
    expect(uri.queryParameters.containsKey('rtext'), isFalse);
  });

  test('маршрут по координатам идёт в rtext без кодирования запятой', () {
    expect(
      yandexRouteUrl(
        from: '59.939095,30.315635',
        to: '59.957813,30.308714',
      ),
      'https://yandex.ru/maps/?rtext=59.939095,30.315635~59.957813,30.308714&rtt=auto',
    );
  });
}
