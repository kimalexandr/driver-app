import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/api/mock_driver_api.dart';
import 'package:phone_auth_app/api/token_store.dart';
import 'package:phone_auth_app/screens/phone_input_screen.dart';
import 'package:phone_auth_app/services/location_service.dart';
import 'package:phone_auth_app/services/local_notifications.dart';
import 'package:phone_auth_app/services/notification_prefs_store.dart';
import 'package:phone_auth_app/services/pep_vault.dart';
import 'package:phone_auth_app/services/push_registration.dart';
import 'package:phone_auth_app/services/rustore_push_gateway.dart';
import 'package:phone_auth_app/services/secure_kv.dart';
import 'package:phone_auth_app/services/trip_location_tracker.dart';
import 'package:phone_auth_app/state/app_scope.dart';
import 'package:phone_auth_app/state/auth_controller.dart';

void main() {
  testWidgets('на входе есть Госуслуги и Госключ, mock пускает сразу', (tester) async {
    final api = MockDriverApi();
    final store = MemoryTokenStore();
    final auth = AuthController(api: api, tokenStore: store);
    final kv = MemorySecureKv();
    final pep = PepVault(kv: kv);
    final location = LocationService();
    final push = PushRegistration(
      prefsStore: NotificationPrefsStore(kv: kv),
      notifications: FakeLocalNotifications(permissionGranted: true),
      rustore: FakeRuStorePushGateway(),
      kv: kv,
    );
    await tester.pumpWidget(
      AppScope(
        api: api,
        tokenStore: store,
        locationService: location,
        locationTracker: TripLocationTracker(api: api, location: location),
        pep: pep,
        push: push,
        auth: auth,
        child: MaterialApp(
          home: const PhoneInputScreen(),
          routes: {
            '/trips': (_) => const Scaffold(body: Text('Рейсы')),
          },
        ),
      ),
    );

    expect(find.text('Госуслуги'), findsOneWidget);
    expect(find.text('Госключ'), findsOneWidget);
    expect(find.text('+7'), findsOneWidget);
    expect(find.text('(999) 123-45-67'), findsOneWidget);
    expect(find.text('+7 (___) ___-__-__'), findsNothing);

    await tester.enterText(find.byType(TextFormField), '9991234567');
    await tester.pump();

    expect(find.text('(999) 123-45-67'), findsWidgets);
    expect(find.textContaining('Код придёт на'), findsNothing);

    await tester.tap(find.text('Госуслуги'));
    await tester.pumpAndSettle();

    expect(find.text('Рейсы'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);
  });
}
