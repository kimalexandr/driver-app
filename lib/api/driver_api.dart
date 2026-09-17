import '../models/auth_session.dart';
import '../models/driver_profile.dart';
import '../models/external_auth.dart';
import '../models/json_fields.dart';
import '../models/notification_prefs.dart';
import '../models/pep.dart';
import '../models/trip.dart';
import 'api_client.dart';
import 'api_exception.dart';

abstract class DriverApi {
  Future<CodeRequest> requestCode(String phone);

  Future<AuthSession> verifyCode({
    required String phone,
    required String code,
  });

  Future<ExternalAuthStart> startExternalAuth(AuthProviderKind provider);

  Future<AuthSession> completeExternalAuth({
    required String provider,
    required String code,
    required String state,
  });

  Future<void> registerPep(PepRecord record);

  Future<DriverProfile> me();

  Future<List<Trip>> listTrips();

  Future<Trip> getTrip(String id);

  Future<Trip> updateTripStatus({
    required String tripId,
    required String status,
    String? comment,
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

  Future<void> registerDevice({
    required String token,
    required NotificationPrefs prefs,
    String provider = 'rustore',
    String platform = 'android',
    String? appVersion,
  });

  Future<void> unregisterDevice({
    required String token,
    String provider = 'rustore',
  });

  Future<void> updateNotificationPrefs(NotificationPrefs prefs);
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
    final driver = session.driver.orFallback(
      DriverProfile(id: session.driver.id, name: session.driver.name, phone: phone),
    );
    await client.tokenStore.saveAccessToken(session.accessToken);
    return AuthSession(
      accessToken: session.accessToken,
      tokenType: session.tokenType,
      driver: driver,
    );
  }

  @override
  Future<ExternalAuthStart> startExternalAuth(AuthProviderKind provider) async {
    try {
      final json = await client.post(
        '/auth/external/start',
        body: {'provider': provider.id},
        auth: false,
      );
      return ExternalAuthStart.fromJson(unwrapJson(json));
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 501) {
        return ExternalAuthStart(
          provider: provider.id,
          state: 'pending-esia',
          authorizeUrl: provider == AuthProviderKind.goskey
              ? OfficialAuthLinks.goskey
              : OfficialAuthLinks.gosuslugi,
        );
      }
      rethrow;
    }
  }

  @override
  Future<AuthSession> completeExternalAuth({
    required String provider,
    required String code,
    required String state,
  }) async {
    final json = await client.post(
      '/auth/external/complete',
      body: {'provider': provider, 'code': code, 'state': state},
      auth: false,
    );
    final session = AuthSession.fromJson(json);
    await client.tokenStore.saveAccessToken(session.accessToken);
    return session;
  }

  @override
  Future<void> registerPep(PepRecord record) async {
    try {
      await client.post('/me/pep', body: record.toJson());
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 501) {
        return;
      }
      rethrow;
    }
  }

  @override
  Future<DriverProfile> me() async {
    final json = await client.get('/me');
    return DriverProfile.fromJson(unwrapJson(json));
  }

  @override
  Future<List<Trip>> listTrips() async {
    final json = await client.get('/trips');
    final root = unwrapJson(json);
    final items = root['trips'] ?? root['items'] ?? json['trips'] ?? json['data'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => Trip.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<Trip> getTrip(String id) async {
    final json = await client.get('/trips/$id');
    final root = unwrapJson(json);
    final trip = root['trip'] ?? root;
    if (trip is Map) {
      return Trip.fromJson(Map<String, dynamic>.from(trip));
    }
    return Trip.fromJson(root);
  }

  @override
  Future<Trip> updateTripStatus({
    required String tripId,
    required String status,
    String? comment,
  }) async {
    final json = await client.patch(
      '/trips/$tripId/status',
      body: {
        'status': status,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
    );
    final root = unwrapJson(json);
    final trip = root['trip'];
    if (trip is Map) {
      return Trip.fromJson(Map<String, dynamic>.from(trip));
    }
    if (root['id'] != null || root['number'] != null) {
      return Trip.fromJson(root);
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

  @override
  Future<void> registerDevice({
    required String token,
    required NotificationPrefs prefs,
    String provider = 'rustore',
    String platform = 'android',
    String? appVersion,
  }) {
    return client.post(
      '/me/device',
      body: {
        'token': token,
        'provider': provider,
        'platform': platform,
        if (appVersion != null && appVersion.isNotEmpty)
          'app_version': appVersion,
        ...prefs.toJson(),
      },
    );
  }

  @override
  Future<void> unregisterDevice({
    required String token,
    String provider = 'rustore',
  }) {
    return client.delete(
      '/me/device',
      body: {
        'token': token,
        'provider': provider,
      },
    );
  }

  @override
  Future<void> updateNotificationPrefs(NotificationPrefs prefs) {
    return client.put(
      '/me/notification-prefs',
      body: prefs.toJson(),
    );
  }
}
