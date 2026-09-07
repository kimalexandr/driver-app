import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/trip.dart';
import 'package:phone_auth_app/screens/request_details_screen.dart';

void main() {
  testWidgets('RequestDetailsScreen displays trip details', (tester) async {
    const trip = Trip(
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
      comment: 'Вход со стороны двора, звонить за час',
      cargo: 'Паллеты с запчастями',
      weightKg: 1000,
      volumeM3: 5,
      sender: Party(
        name: 'Иванов Иван Иванович',
        company: 'ООО «Грузовик»',
        phone: '+7 (999) 123-45-67',
      ),
      recipient: Party(
        name: 'Петров Пётр Петрович',
        company: 'ООО «Получатель»',
        phone: '+7 (999) 765-43-21',
      ),
      shipments: [Shipment(id: 's1', title: 'Груз 1', weightKg: 1000, volumeM3: 5)],
    );

    await tester.pumpWidget(const MaterialApp(
      home: RequestDetailsScreen(trip: trip),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Рейс №001'), findsOneWidget);
    expect(find.text('Назначен'), findsOneWidget);
    expect(find.text('Москва'), findsOneWidget);
    expect(find.text('Санкт-Петербург'), findsOneWidget);
    expect(find.text('г. Москва, ул. Ленина, д. 1'), findsOneWidget);
    expect(find.text('г. Санкт-Петербург, пр. Невский, д. 1'), findsOneWidget);
    expect(find.text('Груз 1'), findsOneWidget);
    expect(find.text('Комментарий рейса'), findsOneWidget);
    expect(find.text('Вход со стороны двора, звонить за час'), findsOneWidget);
    expect(find.text('Паллеты с запчастями'), findsOneWidget);
    expect(find.text('1000 кг'), findsWidgets);
    expect(find.text('5 м³'), findsWidgets);
    expect(find.text('Отправитель'), findsOneWidget);
    expect(find.text('Получатель'), findsOneWidget);
    expect(find.text('ООО «Грузовик»'), findsOneWidget);
    expect(find.text('ООО «Получатель»'), findsOneWidget);
    expect(find.text('В пути'), findsOneWidget);
    expect(find.text('Прикрепить фото'), findsOneWidget);
  });
}
