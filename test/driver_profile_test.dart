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

  test('читает data-обёртку и ФИО из частей', () {
    final driver = DriverProfile.fromJson({
      'status': 'ok',
      'data': {
        'id': 9,
        'last_name': 'Сидоров',
        'first_name': 'Сидор',
        'patronymic': 'Сидорович',
        'mobile_phone': '79995554433',
        'company': {'name': 'ООО Север'},
      },
    });

    expect(driver.name, 'Сидоров Сидор Сидорович');
    expect(driver.phone, '79995554433');
    expect(driver.carrierName, 'ООО Север');
  });

  test('читает поля DriverAuthService::profile', () {
    final driver = DriverProfile.fromJson({
      'id': 12,
      'full_name': 'Иванов Иван Иванович',
      'name': 'Иванов Иван Иванович',
      'last_name': 'Иванов',
      'first_name': 'Иван',
      'patronymic': 'Иванович',
      'phone': '79991234567',
      'phone_secondary': '79990001122',
      'email': 'driver@7rights.ru',
      'license_number': '99 00 123456',
      'company_name': 'ООО Перевозчик',
      'team_id': 5,
    });

    expect(driver.id, '12');
    expect(driver.name, 'Иванов Иван Иванович');
    expect(driver.phone, '79991234567');
    expect(driver.phoneSecondary, '79990001122');
    expect(driver.email, 'driver@7rights.ru');
    expect(driver.licenseNumber, '99 00 123456');
    expect(driver.carrierName, 'ООО Перевозчик');
  });
}
