import '../models/auth_session.dart';
import '../models/driver_profile.dart';
import '../models/trip.dart';
import 'api_client.dart';
import 'api_exception.dart';

abstract class DriverApi {
  Future<CodeRequest> requestCode(String phone);

  Future<AuthSession> verifyCode({
    required String phone,
    required String code,
  });

  Future<DriverProfile> me();

  Future<List<Trip>> listTrips();

  Future<Trip> getTrip(String id);

  Future<Trip> updateTripStatus({
    required String tripId,
    required String status,
  });

  Future<void> sendLocation({
    required String tripId,
    required double lat,
    required double lng,
  });

  Future<void> uploadFile({
    required String tripId,
    required String filePath,
  });
}

class HttpDriverApi implements DriverApi {
  final ApiClient client;

  HttpDriverApi(this.client);

  @override
  Future<CodeRequest> requestCode(String phone) async {
    final json = await client.post(
      '/auth/request-code',
      body: {'phone': phone},
      auth: false,
    );
    final debug = json['debug_code'];
    return CodeRequest(
      phone: phone,
      debugCode: debug == null ? null : '$debug',
    );
  }

  @override
  Future<AuthSession> verifyCode({
    required String phone,
    required String code,
  }) async {
    final json = await client.post(
      '/auth/verify',
      body: {'phone': phone, 'code': code},
      auth: false,
    );
    late final AuthSession session;
    try {
      session = AuthSession.fromJson(json);
    } on FormatException {
      throw const ApiException('Сервер вернул некорректный ответ');
    }
    final driver = session.driver.phone.isEmpty
        ? DriverProfile(id: session.driver.id, name: session.driver.name, phone: phone)
        : session.driver;
    await client.tokenStore.saveAccessToken(session.accessToken);
    return AuthSession(
      accessToken: session.accessToken,
      tokenType: session.tokenType,
      driver: driver,
    );
  }

  @override
  Future<DriverProfile> me() async {
    final json = await client.get('/me');
    return DriverProfile.fromJson(json);
  }

  @override
  Future<List<Trip>> listTrips() async {
    final json = await client.get('/trips');
    final items = json['trips'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => Trip.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<Trip> getTrip(String id) async {
    final json = await client.get('/trips/$id');
    final trip = json['trip'];
    if (trip is Map) {
      return Trip.fromJson(Map<String, dynamic>.from(trip));
    }
    return Trip.fromJson(json);
  }

  @override
  Future<Trip> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    final json = await client.patch(
      '/trips/$tripId/status',
      body: {'status': status},
    );
    final trip = json['trip'];
    if (trip is Map) {
      return Trip.fromJson(Map<String, dynamic>.from(trip));
    }
    return getTrip(tripId);
  }

  @override
  Future<void> sendLocation({
    required String tripId,
    required double lat,
    required double lng,
  }) {
    return client.post(
      '/trips/$tripId/location',
      body: {'lat': lat, 'lng': lng},
    );
  }

  @override
  Future<void> uploadFile({
    required String tripId,
    required String filePath,
  }) {
    return client.postMultipart(
      '/trips/$tripId/files',
      fileField: 'file',
      filePath: filePath,
    );
  }
}
