import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/services/phone.dart';

void main() {
  test('маскирует набор как российский мобильный', () {
    expect(formatRuPhoneLocal(''), '');
    expect(formatRuPhoneLocal('9'), '(9');
    expect(formatRuPhoneLocal('999'), '(999) ');
    expect(formatRuPhoneLocal('999123'), '(999) 123');
    expect(formatRuPhoneLocal('9991234567'), '(999) 123-45-67');
    expect(formatRuPhoneLocal('79991234567'), '(999) 123-45-67');
    expect(formatRuPhoneLocal('8 (999) 123-45-67'), '(999) 123-45-67');
  });

  test('показывает шаблон +7 (___) ___-__-__ по мере ввода', () {
    expect(formatRuPhonePretty(''), '+7 (___) ___-__-__');
    expect(formatRuPhonePretty('999'), '+7 (999) ___-__-__');
    expect(formatRuPhonePretty('9991234'), '+7 (999) 123-4_-__');
    expect(formatRuPhonePretty('9991234567'), '+7 (999) 123-45-67');
  });
}
