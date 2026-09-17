import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/driver_api.dart';
import '../api/token_store.dart';
import '../services/local_notifications.dart';
import '../services/location_service.dart';
import '../services/notification_prefs_store.dart';
import '../services/pep_vault.dart';
import '../services/push_registration.dart';
import '../services/trip_location_tracker.dart';
import 'auth_controller.dart';

class AppScope extends InheritedNotifier<AuthController> {
  final DriverApi api;
  final TokenStore tokenStore;
  final LocationService locationService;
  final TripLocationTracker locationTracker;
  final PepVault pep;
  final PushRegistration push;

  const AppScope({
    super.key,
    required this.api,
    required this.tokenStore,
    required this.locationService,
    required this.locationTracker,
    required this.pep,
    required this.push,
    required AuthController auth,
    required super.child,
  }) : super(notifier: auth);

  AuthController get auth => notifier!;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope не найден');
    return scope!;
  }

  static AppScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>();
  }
}

class AppDependencies {
  final TokenStore tokenStore;
  final ApiClient client;
  final DriverApi api;
  final AuthController auth;
  final LocationService locationService;
  final TripLocationTracker locationTracker;
  final PepVault pep;
  final PushRegistration push;

  AppDependencies._({
    required this.tokenStore,
    required this.client,
    required this.api,
    required this.auth,
    required this.locationService,
    required this.locationTracker,
    required this.pep,
    required this.push,
  });

  factory AppDependencies({
    TokenStore? tokenStore,
    DriverApi? api,
    ApiClient? client,
    LocationService? locationService,
    PepVault? pep,
    PushRegistration? push,
  }) {
    final store = tokenStore ?? SecureTokenStore();
    final resolvedClient = client ?? ApiClient(tokenStore: store);
    final resolvedApi = api ?? HttpDriverApi(resolvedClient);
    final auth = AuthController(api: resolvedApi, tokenStore: store);
    final resolvedLocation = locationService ?? LocationService();
    final tracker = TripLocationTracker(api: resolvedApi, location: resolvedLocation);
    final resolvedPush = push ??
        PushRegistration(
          prefsStore: NotificationPrefsStore(),
          notifications: LocalNotifications(),
        );
    resolvedClient.onUnauthorized = () async {
      tracker.stop();
      final owner = auth.driver?.id ?? 'local';
      try {
        await resolvedPush.unregister(api: resolvedApi, owner: owner);
      } catch (_) {}
      await auth.onUnauthorized();
    };
    return AppDependencies._(
      tokenStore: store,
      client: resolvedClient,
      api: resolvedApi,
      auth: auth,
      locationService: resolvedLocation,
      locationTracker: tracker,
      pep: pep ?? PepVault(),
      push: resolvedPush,
    );
  }
}
