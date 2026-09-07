import '../models/auth_session.dart';
import '../models/driver_profile.dart';
import '../models/trip.dart';
import 'api_exception.dart';
import 'driver_api.dart';
import 'token_store.dart';

class MockDriverApi implements DriverApi {
  final TokenStore? tokenStore;

  MockDriverApi({this.tokenStore});

  static const mockCode = '1234';

  DriverProfile _driver = const DriverProfile(
    id: '1',
    name: 'Иванов Иван Иванович',
    phone: '79991234567',
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
      shipments: [Shipment(id: 's1', title: 'Груз 1')],
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
      shipments: [Shipment(id: 's2', title: 'Груз 2')],
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
    if (code != mockCode) {
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
    final updated = Trip(
      id: current.id,
      number: current.number,
      status: status,
      statusLabel: status == 'in_transit' ? 'В пути' : 'Доставлено',
      from: current.from,
      to: current.to,
      dateStart: current.dateStart,
      vehicle: current.vehicle,
      startAddress: current.startAddress,
      finishAddress: current.finishAddress,
      shipments: current.shipments,
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
