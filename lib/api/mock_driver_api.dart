import '../models/auth_session.dart';
import '../models/driver_profile.dart';
import '../models/trip.dart';
import 'api_exception.dart';
import 'driver_api.dart';
import 'service_login.dart';
import 'token_store.dart';

class MockDriverApi implements DriverApi {
  final TokenStore? tokenStore;

  MockDriverApi({this.tokenStore});

  static const mockCode = ServiceLogin.code;

  DriverProfile _driver = const DriverProfile(
    id: '1',
    name: 'Иванов Иван Иванович',
    phone: '79991234567',
    carrierName: 'ООО Перевозчик',
    vehicle: 'КАМАЗ · А123БВ777',
    licenseNumber: '99 00 123456',
    licenseCategories: 'C, CE',
    licenseIssuedAt: '2019-04-12',
  );

  final List<Trip> _trips = [
    const Trip(
      id: '1',
      number: '001',
      status: 'assigned',
      statusLabel: 'Назначен',
      from: 'Москва',
      to: 'Санкт-Петербург',
      dateStart: '15.03.2024 10:00',
      vehicle: 'А001АА77',
      startAddress: 'г. Москва, ул. Ленина, д. 1',
      finishAddress: 'г. Санкт-Петербург, пр. Невский, д. 1',
      comment: 'Вход со стороны двора, звонить за час',
      cargo: 'Паллеты с запчастями',
      weightKg: 1000,
      volumeM3: 5,
      sender: Party(
        name: 'Иванов Иван Иванович',
        company: 'ООО «Грузовик»',
        phone: '+7 (999) 123-45-67',
        address: 'г. Москва, ул. Ленина, д. 1',
        comment: 'Погрузка у ворот №1',
      ),
      recipient: Party(
        name: 'Петров Пётр Петрович',
        company: 'ООО «Получатель»',
        phone: '+7 (999) 765-43-21',
        address: 'г. Санкт-Петербург, пр. Невский, д. 1',
        comment: 'Разгрузка на складе №2',
      ),
      shipments: [
        Shipment(
          id: 's1',
          title: 'Груз 1',
          weightKg: 1000,
          volumeM3: 5,
          comment: 'Не кантовать',
        ),
      ],
    ),
    const Trip(
      id: '2',
      number: '002',
      status: 'in_transit',
      statusLabel: 'В пути',
      from: 'Казань',
      to: 'Екатеринбург',
      dateStart: '17.03.2024 09:00',
      vehicle: 'В002ВВ16',
      startAddress: 'г. Казань, ул. Баумана, д. 1',
      finishAddress: 'г. Екатеринбург, ул. Ленина, д. 1',
      comment: 'Погрузка на складе №1',
      cargo: 'Коробки с оборудованием',
      weightKg: 2000,
      volumeM3: 8,
      sender: Party(
        name: 'Сергеев Сергей',
        company: 'ООО «Грузовик»',
        phone: '+7 (903) 111-22-33',
        address: 'г. Казань, ул. Баумана, д. 1',
      ),
      recipient: Party(
        name: 'Алексеев Алексей',
        company: 'ООО «Получатель»',
        phone: '+7 (912) 444-55-66',
        address: 'г. Екатеринбург, ул. Ленина, д. 1',
      ),
      shipments: [
        Shipment(
          id: 's2',
          title: 'Груз 2',
          weightKg: 2000,
          volumeM3: 8,
        ),
      ],
    ),
    const Trip(
      id: '3',
      number: '003',
      status: 'delivered',
      statusLabel: 'Доставлено',
      from: 'Тула',
      to: 'Рязань',
      dateStart: '10.03.2024 08:00',
      vehicle: 'С003СС71',
      cargo: 'Упаковка',
      weightKg: 400,
      volumeM3: 2,
    ),
  ];

  @override
  Future<CodeRequest> requestCode(String phone) async {
    if (phone.length != 11 || !phone.startsWith('7')) {
      throw const ApiException('Некорректный телефон', statusCode: 422);
    }
    return CodeRequest(phone: phone, debugCode: mockCode);
  }

  @override
  Future<AuthSession> verifyCode({
    required String phone,
    required String code,
  }) async {
    final resolved = ServiceLogin.resolve(entered: code, debugCode: mockCode);
    if (resolved != mockCode && code != mockCode) {
      throw const ApiException('Неверный код', statusCode: 422);
    }
    _driver = DriverProfile(id: _driver.id, name: _driver.name, phone: phone);
    await tokenStore?.saveAccessToken('mock-access-token');
    return AuthSession(
      accessToken: 'mock-access-token',
      tokenType: 'Bearer',
      driver: _driver,
    );
  }

  @override
  Future<DriverProfile> me() async => _driver;

  @override
  Future<List<Trip>> listTrips() async => List.unmodifiable(_trips);

  @override
  Future<Trip> getTrip(String id) async {
    return _trips.firstWhere(
      (trip) => trip.id == id || trip.number == id,
      orElse: () => throw const ApiException('Рейс не найден', statusCode: 404),
    );
  }

  @override
  Future<Trip> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    if (status != 'in_transit' && status != 'delivered') {
      throw const ApiException('Недопустимый статус', statusCode: 422);
    }
    final index = _trips.indexWhere((trip) => trip.id == tripId);
    if (index < 0) {
      throw const ApiException('Рейс не найден', statusCode: 404);
    }
    final current = _trips[index];
    final updated = current.copyWith(
      status: status,
      statusLabel: status == 'in_transit' ? 'В пути' : 'Доставлено',
    );
    _trips[index] = updated;
    return updated;
  }

  @override
  Future<void> sendLocation({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    await getTrip(tripId);
  }

  @override
  Future<void> uploadFile({
    required String tripId,
    required String filePath,
  }) async {
    await getTrip(tripId);
  }
}
