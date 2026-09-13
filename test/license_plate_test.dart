import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/license_plate.dart';

void main() {
  test('разбирает российский госномер и латиницу', () {
    final cyr = parseRuLicensePlate('А123ВС77');
    expect(cyr.parsed, isTrue);
    expect(cyr.letter, 'А');
    expect(cyr.digits, '123');
    expect(cyr.series, 'ВС');
    expect(cyr.region, '77');

    final spaced = parseRuLicensePlate('А 123 ВС 777');
    expect(spaced.parsed, isTrue);
    expect(spaced.region, '777');

    final latin = parseRuLicensePlate('A123BC77');
    expect(latin.parsed, isTrue);
    expect(latin.letter, 'А');
    expect(latin.series, 'ВС');
    expect(latin.region, '77');
  });

  test('не ломается на неизвестном формате', () {
    final plate = parseRuLicensePlate('без номера');
    expect(plate.parsed, isFalse);
    expect(plate.raw, 'без номера');
  });
}
