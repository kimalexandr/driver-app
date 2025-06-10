import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/screens/requests_screen.dart';

void main() {
  testWidgets(
      'RequestsScreen displays list of requests and navigates to details',
      (WidgetTester tester) async {
    // Используем companyName, который реально используется в приложении
    const testCompanyName = 'Компания 1';

    // Создаем экран заявок
    await tester.pumpWidget(const MaterialApp(
      home: RequestsScreen(companyName: testCompanyName),
    ));
    await tester.pumpAndSettle(); // Ждем полной отрисовки

    // Проверяем, что заголовок отображается
    expect(find.text(testCompanyName), findsOneWidget);

    // Проверяем, что список заявок отображается
    expect(find.text('Заявка №001'), findsOneWidget);
    expect(find.text('Заявка №002'), findsOneWidget);

    // Проверяем, что отображаются города погрузки и разгрузки
    expect(find.text('Москва'), findsOneWidget);
    expect(find.text('Санкт-Петербург'), findsOneWidget);
    expect(find.text('Казань'), findsOneWidget);
    expect(find.text('Екатеринбург'), findsOneWidget);

    // Проверяем, что отображаются даты и время
    expect(find.text('15.03.2024 10:00'), findsOneWidget);
    expect(find.text('16.03.2024 14:00'), findsOneWidget);
    expect(find.text('17.03.2024 09:00'), findsOneWidget);
    expect(find.text('18.03.2024 15:00'), findsOneWidget);

    // Проверяем наличие кнопки профиля
    expect(find.byIcon(Icons.person), findsOneWidget);

    // Нажимаем на первую заявку
    await tester.tap(find.text('Заявка №001'));
    await tester.pumpAndSettle();

    // Проверяем, что произошел переход на экран деталей заявки
    expect(find.text('Заявка №001'), findsOneWidget);
    expect(find.text('Погрузка'), findsOneWidget);
    expect(find.text('Разгрузка'), findsOneWidget);
  });
}
