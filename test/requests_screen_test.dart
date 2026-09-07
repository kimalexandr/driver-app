import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/api/mock_driver_api.dart';
import 'package:phone_auth_app/screens/requests_screen.dart';

void main() {
  testWidgets('RequestsScreen displays trips and opens details', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RequestsScreen(
        companyName: 'Рейсы',
        api: MockDriverApi(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Рейсы'), findsOneWidget);
    expect(find.text('Рейс №001'), findsOneWidget);
    expect(find.text('Рейс №002'), findsOneWidget);
    expect(find.text('Москва → Санкт-Петербург'), findsOneWidget);
    expect(find.text('Казань → Екатеринбург'), findsOneWidget);
    expect(find.text('15.03.2024 10:00'), findsOneWidget);
    expect(find.text('Назначен'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    await tester.tap(find.text('Рейс №001'));
    await tester.pumpAndSettle();

    expect(find.text('Рейс №001'), findsOneWidget);
    expect(find.text('Откуда'), findsOneWidget);
  });
}
