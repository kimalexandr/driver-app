import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/screens/company_selection_screen.dart';
import 'package:phone_auth_app/screens/requests_screen.dart';

void main() {
  testWidgets(
      'CompanySelectionScreen displays list of companies and navigates to RequestsScreen',
      (WidgetTester tester) async {
    // Создаем экран выбора компании
    await tester.pumpWidget(const MaterialApp(
      home: CompanySelectionScreen(),
    ));
    await tester.pumpAndSettle(); // Ждем полной отрисовки

    // Проверяем, что заголовок отображается
    expect(find.text('Выбор компании'), findsOneWidget);
    expect(find.text('Выберите вашу компанию:'), findsOneWidget);

    // Проверяем, что список компаний отображается
    expect(find.text('Компания 1'), findsOneWidget);
    expect(find.text('Компания 2'), findsOneWidget);
    expect(find.text('Компания 3'), findsOneWidget);
    expect(find.text('Компания 4'), findsOneWidget);
    expect(find.text('Компания 5'), findsOneWidget);

    // Проверяем, что кнопка "Подтвердить" изначально неактивна
    final confirmButton = find.widgetWithText(ElevatedButton, 'Подтвердить');
    expect(confirmButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);

    // Выбираем компанию
    await tester.tap(find.text('Компания 1'));
    await tester.pumpAndSettle();

    // Проверяем, что кнопка стала активной
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNotNull);

    // Нажимаем кнопку "Подтвердить"
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Проверяем, что произошел переход на экран заявок
    expect(find.byType(RequestsScreen), findsOneWidget);
    expect(find.text('Компания 1'), findsOneWidget);
  });
}
