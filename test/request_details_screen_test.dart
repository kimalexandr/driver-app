import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/screens/request_details_screen.dart';

void main() {
  testWidgets('RequestDetailsScreen displays request details correctly',
      (WidgetTester tester) async {
    // Создаем тестовые данные заявки
    final testRequest = {
      'number': '001',
      'loading_city': 'Москва',
      'loading_date': '15.03.2024',
      'loading_time': '10:00',
      'unloading_city': 'Санкт-Петербург',
      'unloading_date': '16.03.2024',
      'unloading_time': '14:00',
      'loading_address': 'г. Москва, ул. Ленина, д. 1',
      'loading_company': 'ООО "Грузовик"',
      'loading_weight': 1000,
      'loading_volume': 5,
      'loading_comment': 'Вход со стороны двора',
      'loading_gates': 'Ворота №1',
      'loading_time_from': '09:00',
      'loading_time_to': '11:00',
      'loading_dispatcher': 'Иванов Иван Иванович',
      'loading_dispatcher_phone': '+7 (999) 123-45-67',
      'unloading_address': 'г. Санкт-Петербург, пр. Невский, д. 1',
      'unloading_company': 'ООО "Получатель"',
      'unloading_weight': 1000,
      'unloading_volume': 5,
      'unloading_comment': 'Разгрузка на складе №2',
    };

    // Создаем экран деталей заявки
    await tester.pumpWidget(MaterialApp(
      home: RequestDetailsScreen(request: testRequest),
    ));
    await tester.pumpAndSettle(); // Ждем полной отрисовки

    // Проверяем заголовок
    expect(find.text('Заявка №001'), findsOneWidget);

    // Проверяем секцию погрузки и разгрузки
    expect(find.text('Погрузка'), findsOneWidget);
    expect(find.text('Разгрузка'), findsOneWidget);
    expect(find.text('Адрес'), findsNWidgets(2));
    expect(find.text('Дата и время'), findsNWidgets(2));
    expect(find.text('Компания'), findsOneWidget);
    expect(find.text('Компания получатель'), findsOneWidget);
    expect(find.text('Масса'), findsNWidgets(2));
    expect(find.text('Объем'), findsNWidgets(2));
    expect(find.text('Комментарий'), findsNWidgets(2));
    expect(find.text(testRequest['loading_address'] as String), findsOneWidget);
    expect(
        find.text(testRequest['unloading_address'] as String), findsOneWidget);
    expect(
        find.text(
            '${testRequest['loading_date']} ${testRequest['loading_time']}'),
        findsOneWidget);
    expect(
        find.text(
            '${testRequest['unloading_date']} ${testRequest['unloading_time']}'),
        findsOneWidget);
    expect(find.text(testRequest['loading_company'] as String), findsOneWidget);
    expect(
        find.text(testRequest['unloading_company'] as String), findsOneWidget);
    expect(find.text('${testRequest['loading_weight']} кг'), findsNWidgets(2));
    expect(
        find.text('${testRequest['unloading_weight']} кг'), findsNWidgets(2));
    expect(find.text('${testRequest['loading_volume']} м³'), findsNWidgets(2));
    expect(
        find.text('${testRequest['unloading_volume']} м³'), findsNWidgets(2));
    expect(find.text(testRequest['loading_comment'] as String), findsOneWidget);
    expect(
        find.text(testRequest['unloading_comment'] as String), findsOneWidget);
    expect(find.text('В путь на погрузку'), findsOneWidget);
  });
}
