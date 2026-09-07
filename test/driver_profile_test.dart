import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/driver_profile.dart';

void main() {
  test('читает профиль водителя из driver и auto рядом', () {
    final driver = DriverProfile.fromJson({
      'driver': {
        'id': 1,
        'name': 'Иванов Иван Иванович',
        'phone': '79001234567',
        'license': {
          'number': '1234567890',
          'issue_date': '2020-05-12',
          'issued_by': 'ГИБДД',
          'issue_city': 'Москва',
        },
        'passport': {
          'series': '4510',
          'number': '123456',
          'issue_date': '2015-03-01',
        },
      },
      'auto': {
        'id': 10,
        'state_number': 'А123ВС77',
        'brand': 'Volvo',
        'model': 'FH',
        'vin': 'X123',
        'year': '2019',
        'color': 'белый',
        'sts_number': '99АА123456',
        'car_category': 'C',
        'body_type': 'Тягач',
      },
    });

    expect(driver.id, '1');
    expect(driver.name, 'Иванов Иван Иванович');
    expect(driver.phone, '79001234567');
    expect(driver.license.number, '1234567890');
    expect(driver.license.issueDate, '12.05.2020');
    expect(driver.license.issuedBy, 'ГИБДД');
    expect(driver.license.issueCity, 'Москва');
    expect(driver.passport.seriesNumber, '4510 123456');
    expect(driver.passport.issueDate, '01.03.2015');
    expect(driver.auto?.stateNumber, 'А123ВС77');
    expect(driver.auto?.brand, 'Volvo');
    expect(driver.auto?.model, 'FH');
    expect(driver.vehicle, 'Volvo FH · А123ВС77');
  });

  test('auto null если машина не назначена', () {
    final driver = DriverProfile.fromJson({
      'driver': {
        'id': 3,
        'full_name': 'Петров Пётр',
        'phone': '79990001122',
        'company_name': 'ИП Петров',
        'license': {'number': '12 34 567890', 'issue_date': '2020-01-15'},
      },
      'auto': null,
    });

    expect(driver.name, 'Петров Пётр');
    expect(driver.phone, '79990001122');
    expect(driver.carrierName, 'ИП Петров');
    expect(driver.license.number, '12 34 567890');
    expect(driver.license.issueDate, '15.01.2020');
    expect(driver.auto, isNull);
    expect(driver.vehicle, '');
  });

  test('читает data-обёртку и ФИО из частей', () {
    final driver = DriverProfile.fromJson({
      'status': 'ok',
      'data': {
        'driver': {
          'id': 9,
          'last_name': 'Сидоров',
          'first_name': 'Сидор',
          'patronymic': 'Сидорович',
          'mobile_phone': '79995554433',
          'company_name': 'ООО Север',
        },
        'auto': null,
      },
    });

    expect(driver.name, 'Сидоров Сидор Сидорович');
    expect(driver.phone, '79995554433');
    expect(driver.carrierName, 'ООО Север');
  });

  test('читает поля DriverAuthService::profile', () {
    final driver = DriverProfile.fromJson({
      'driver': {
        'id': 12,
        'full_name': 'Иванов Иван Иванович',
        'name': 'Иванов Иван Иванович',
        'last_name': 'Иванов',
        'first_name': 'Иван',
        'patronymic': 'Иванович',
        'phone': '79991234567',
        'phone_secondary': '79990001122',
        'email': 'driver@7rights.ru',
        'company_name': 'ООО Перевозчик',
        'license': {'number': '99 00 123456'},
        'team_id': 5,
      },
    });

    expect(driver.id, '12');
    expect(driver.name, 'Иванов Иван Иванович');
    expect(driver.phone, '79991234567');
    expect(driver.phoneSecondary, '79990001122');
    expect(driver.email, 'driver@7rights.ru');
    expect(driver.license.number, '99 00 123456');
    expect(driver.carrierName, 'ООО Перевозчик');
  });
}
