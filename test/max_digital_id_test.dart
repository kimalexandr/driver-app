import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/external_auth.dart';
import 'package:phone_auth_app/services/max_digital_id.dart';

void main() {
  test('MaxDigitalIdService знает официальные ссылки MAX', () {
    expect(OfficialAuthLinks.maxDigitalId, contains('max.ru'));
    expect(OfficialAuthLinks.maxDigitalIdGuide, contains('max.ru'));
    expect(MaxDigitalIdService(), isA<MaxDigitalIdService>());
  });
}
