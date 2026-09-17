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
      dateEnd: '16.03.2024 18:00',
      loadWindowFrom: '09:00',
      loadWindowTo: '12:00',
      distanceKm: 705,
      dispatcherName: 'Смирнов Алексей',
      dispatcherPhone: '+79990001122',
      attorneyNumber: 'Д-17',
      attorneyDate: '01.03.2024',
      statusHistory: [
        StatusEvent(status: 'assigned', label: 'Назначен', at: '14.03.2024 18:40'),
      ],
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
      shipments: [
        Shipment(
          id: 's1',
          title: 'Груз 1',
          weightKg: 1000,
          volumeM3: 5,
          attorneyNumber: 'Д-17',
          attorneyDate: '01.03.2024',
          titles: [
            EtrnTitle(
              code: 'T1',
              name: 'Грузоотправитель',
              signed: true,
              signedAt: '14.03.2024 17:05',
              signedBy: 'ООО «Грузовик»',
            ),
            EtrnTitle(code: 'T2', name: 'Перевозчик, приём'),
          ],
        ),
      ],
    );

    await tester.pumpWidget(const MaterialApp(
      home: RequestDetailsScreen(trip: trip),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Рейс №001'), findsOneWidget);
    expect(find.text('Назначен'), findsWidgets);
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
    expect(find.text('Ход рейса'), findsOneWidget);
    expect(find.text('Для исполнения'), findsNothing);
    expect(find.text('Задача'), findsNothing);
    expect(find.text('Груз'), findsOneWidget);
    expect(find.text('Погрузка'), findsOneWidget);
    expect(find.text('Выгрузка'), findsOneWidget);
    expect(find.text('Сейчас'), findsOneWidget);
    expect(find.text('14.03.2024 18:40'), findsOneWidget);
    expect(find.text('Документы ЭТрН'), findsOneWidget);
    expect(find.text('T1'), findsOneWidget);
    expect(find.text('T2'), findsOneWidget);
    expect(find.text('Подписан'), findsWidgets);
    expect(find.textContaining('Ожидает подпись водителя'), findsOneWidget);
    expect(find.textContaining('Опаздываете'), findsWidgets);
    expect(find.textContaining('705 км'), findsWidgets);
    expect(find.text('Диспетчер'), findsOneWidget);
    expect(find.text('Машина'), findsOneWidget);
    expect(find.text('Доверенность на водителя'), findsOneWidget);
    expect(find.textContaining('№ Д-17'), findsOneWidget);
    expect(find.text('Показать сводку'), findsOneWidget);
    expect(find.textContaining('окно 09:00–12:00'), findsOneWidget);
    expect(find.text('Отправитель'), findsOneWidget);
    expect(find.text('Получатель'), findsOneWidget);
    expect(find.text('ООО «Грузовик»'), findsOneWidget);
    expect(find.text('ООО «Получатель»'), findsOneWidget);
    expect(find.text('В пути'), findsWidgets);
    expect(find.byTooltip('Прикрепить фото'), findsOneWidget);
  });
}
