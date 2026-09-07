import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/driver_profile.dart';

void main() {
  test('читает профиль водителя из плоского JSON', () {
    final driver = DriverProfile.fromJson({
      'id': 7,
      'name': 'Иванов Иван Иванович',
      'mobile_phone': '79991234567',
      'carrier_name': 'ООО Перевозчик',
      'vehicle_number': 'А123БВ777',
      'license_number': '99 00 123456',
      'license_categories': ['C', 'CE'],
      'inn': '7701234567',
    });

    expect(driver.id, '7');
    expect(driver.name, 'Иванов Иван Иванович');
    expect(driver.phone, '79991234567');
    expect(driver.carrierName, 'ООО Перевозчик');
    expect(driver.vehicle, 'А123БВ777');
    expect(driver.licenseNumber, '99 00 123456');
    expect(driver.licenseCategories, 'C, CE');
    expect(driver.inn, '7701234567');
  });

  test('читает вложенные объекты driver, carrier, vehicle, license', () {
    final driver = DriverProfile.fromJson({
      'driver': {
        'id': 3,
        'full_name': 'Петров Пётр',
        'phone': '79990001122',
        'carrier': {'name': 'ИП Петров'},
        'vehicle': {'brand': 'КАМАЗ', 'number': 'К001КК199'},
        'license': {
          'number': '12 34 567890',
          'categories': 'CE',
          'issued_at': '2020-01-15',
        },
        'passport_number': '4510 123456',
        'comment': 'Работает ночью',
      },
    });

    expect(driver.name, 'Петров Пётр');
    expect(driver.phone, '79990001122');
    expect(driver.carrierName, 'ИП Петров');
    expect(driver.vehicle, 'КАМАЗ · К001КК199');
    expect(driver.licenseNumber, '12 34 567890');
    expect(driver.licenseCategories, 'CE');
    expect(driver.licenseIssuedAt, '2020-01-15');
    expect(driver.passportNumber, '4510 123456');
    expect(driver.comment, 'Работает ночью');
  });
}
