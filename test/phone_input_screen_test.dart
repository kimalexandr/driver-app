import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/api/mock_driver_api.dart';
import 'package:phone_auth_app/api/token_store.dart';
import 'package:phone_auth_app/screens/phone_input_screen.dart';
import 'package:phone_auth_app/services/location_service.dart';
import 'package:phone_auth_app/services/pep_vault.dart';
import 'package:phone_auth_app/services/secure_kv.dart';
import 'package:phone_auth_app/services/trip_location_tracker.dart';
import 'package:phone_auth_app/state/app_scope.dart';
import 'package:phone_auth_app/state/auth_controller.dart';

void main() {
  testWidgets('на входе есть Госуслуги и Госключ, mock пускает сразу', (tester) async {
    final api = MockDriverApi();
    final store = MemoryTokenStore();
    final auth = AuthController(api: api, tokenStore: store);
    final pep = PepVault(kv: MemorySecureKv());
    final location = LocationService();
    await tester.pumpWidget(
      AppScope(
        api: api,
        tokenStore: store,
        locationService: location,
        locationTracker: TripLocationTracker(api: api, location: location),
        pep: pep,
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

    await tester.tap(find.text('Госуслуги'));
    await tester.pumpAndSettle();

    expect(find.text('Рейсы'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);
  });
}
