import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/trip.dart';

void main() {
  test('читает товар, вес, объём и отгрузки из JSON', () {
    final trip = Trip.fromJson({
      'id': 10,
      'number': 'A-10',
      'status': 'assigned',
      'from': 'Москва',
      'to': 'Казань',
      'date_start': '2024-03-15T10:00:00',
      'comment': 'Звонить за час',
      'cargo': 'Запчасти',
      'weight_kg': 1200,
      'volume_m3': 6.5,
      'start_company': 'ООО Отправитель',
      'shipments': [
        {
          'id': 1,
          'cargo': {'name': 'Паллета 1', 'weight_kg': 800, 'units': 2, 'measure_unit': 'пал'},
          'comment': 'Хрупкое',
          'consignee': 'Петров',
        },
      ],
    });

    expect(trip.comment, 'Звонить за час');
    expect(trip.cargo, 'Запчасти');
    expect(trip.weightKg, 1200);
    expect(trip.volumeM3, 6.5);
    expect(trip.startCompany, 'ООО Отправитель');
    expect(trip.recipient.name, 'Петров');
    expect(trip.shipments.single.title, 'Паллета 1');
    expect(trip.shipments.single.weightKg, 800);
    expect(formatKg(trip.weightKg), '1200 кг');
    expect(formatM3(trip.volumeM3), '6.5 м³');
    expect(trip.destination, 'Москва');
    expect(trip.copyWith(status: 'in_transit').destination, 'Казань');
    expect(trip.copyWith(status: 'delivered').isCompleted, isTrue);
  });

  test('читает data-обёртку, города погрузки и точки маршрута', () {
    final trip = Trip.fromJson({
      'status': 'ok',
      'data': {
        'id': 4,
        'number': 'B-4',
        'status': 'assigned',
        'from': 'Тула',
        'start_address': 'Тула, ул. Советская, 1',
        'to': 'Орёл',
        'finish_address': 'Орёл, пр. Ленина, 10',
        'cargo': 'Металлопрокат',
        'weight_kg': 2400,
        'shipments': [
          {
            'cargo': {'name': 'Лист 3мм', 'weight_kg': 2400},
          },
        ],
        'stops': [
          {'type': 'load', 'lat': 54.19, 'lng': 37.61},
          {
            'type': 'unload',
            'address': 'Орёл, пр. Ленина, 10',
            'lat': 52.97,
            'lng': 36.06,
          },
        ],
      },
    });

    expect(trip.from, 'Тула');
    expect(trip.startAddress, 'Тула, ул. Советская, 1');
    expect(trip.to, 'Орёл');
    expect(trip.finishAddress, 'Орёл, пр. Ленина, 10');
    expect(trip.cargo, 'Металлопрокат');
    expect(trip.weightKg, 2400);
    expect(trip.shipments.single.title, 'Лист 3мм');
    expect(trip.startLat, 54.19);
    expect(trip.finishLng, 36.06);
  });

  test('читает карточку рейса DriverTripController', () {
    final trip = Trip.fromJson({
      'id': 100,
      'number': 'SAP-100',
      'status': 'assigned',
      'status_label': 'Назначен',
      'from': 'Москва',
      'to': 'Казань',
      'start_address': 'Москва, ул. Ленина, 1',
      'finish_address': 'Казань, пр. Победы, 10',
      'start_city': 'Москва',
      'finish_city': 'Казань',
      'start_company': 'ООО Склад',
      'finish_company': 'ООО Магазин',
      'start_comment': 'Ворота 4',
      'finish_comment': 'Рампа 2',
      'date_start': '2026-09-08T10:00:00',
      'date_end': '2026-09-09T18:00:00',
      'cargo': 'Запчасти, Паллеты',
      'weight_kg': 1200,
      'comment': 'Звонить за час',
      'vehicle': 'А123БВ777',
      'shipments': [
        {
          'id': 1,
          'status': 'ready',
          'date_start': '2026-09-08T10:00:00',
          'date_end': '2026-09-08T12:00:00',
          'from': 'Москва',
          'to': 'Казань',
          'from_address': 'Москва, ул. Ленина, 1',
          'to_address': 'Казань, пр. Победы, 10',
          'from_lat': 55.75,
          'from_lng': 37.62,
          'to_lat': 55.79,
          'to_lng': 49.12,
          'cargo': {
            'name': 'Запчасти',
            'weight_kg': 800,
            'units': 12,
            'measure_unit': 'пал',
            'width_m': 1.2,
            'depth_m': 0.8,
            'height_m': 1.5,
          },
          'load_queue': '3',
          'unload_queue': '1',
          'load_gate': {'number': '4', 'comment': 'слева'},
          'unload_gate': {'number': '2'},
          'load_comment': 'Ждать пропуска',
          'unload_comment': 'Рампа',
          'consignee': 'ООО Магазин',
          'comment': 'Хрупкое',
        },
      ],
      'stops': [
        {
          'type': 'load',
          'address': 'Москва, ул. Ленина, 1',
          'lat': 55.75,
          'lng': 37.62,
        },
        {
          'type': 'unload',
          'address': 'Казань, пр. Победы, 10',
          'lat': 55.79,
          'lng': 49.12,
        },
      ],
    });

    expect(trip.number, 'SAP-100');
    expect(trip.from, 'Москва');
    expect(trip.startAddress, 'Москва, ул. Ленина, 1');
    expect(trip.startCompany, 'ООО Склад');
    expect(trip.finishCompany, 'ООО Магазин');
    expect(trip.startComment, 'Ворота 4');
    expect(trip.finishComment, 'Рампа 2');
    expect(trip.cargo, 'Запчасти, Паллеты');
    expect(trip.weightKg, 1200);
    expect(trip.vehicle, 'А123БВ777');
    expect(trip.dateRange, contains('08.09.2026'));
    expect(trip.shipments.single.title, 'Запчасти');
    expect(trip.shipments.single.weightKg, 800);
    expect(trip.shipments.single.units, 12);
    expect(trip.shipments.single.measureUnit, 'пал');
    expect(trip.shipments.single.sizeLabel, '1.2 × 0.8 × 1.5 м');
    expect(trip.shipments.single.loadGate.number, '4');
    expect(trip.shipments.single.consignee, 'ООО Магазин');
    expect(trip.startLat, 55.75);
    expect(trip.finishLng, 49.12);
    expect(trip.stops.length, 2);
    expect(formatUnits(12, 'пал'), '12 пал');
  });

  test('считает опоздание и расстояние', () {
    const trip = Trip(
      id: '1',
      number: '1',
      status: 'assigned',
      statusLabel: 'Назначен',
      from: 'Москва',
      to: 'Тула',
      dateStart: '15.03.2024 10:00',
      dateEnd: '16.03.2024 18:00',
      loadWindowFrom: '09:00',
      loadWindowTo: '12:00',
      startLat: 55.75,
      startLng: 37.61,
      finishLat: 54.19,
      finishLng: 37.61,
    );
    final deadline = tripDeadline(trip, DateTime(2026, 9, 13, 12));
    expect(deadline, isNotNull);
    expect(deadline!.late, isTrue);
    expect(deadline.urgency, DeadlineUrgency.late);
    expect(deadline.headline, contains('погрузк'));
    expect(trip.nextActionHint, contains('В пути'));
    expect(trip.copyWith(status: 'delivered').nextActionHint, 'Рейс закрыт');
    expect(trip.loadWindowLabel, '09:00–12:00');
    expect(tripDistanceKm(trip), greaterThan(100));

    final soonTrip = Trip(
      id: trip.id,
      number: trip.number,
      status: trip.status,
      statusLabel: trip.statusLabel,
      from: trip.from,
      to: trip.to,
      dateStart: '13.09.2026 13:00',
    );
    expect(
      tripDeadline(soonTrip, DateTime(2026, 9, 13, 12))?.urgency,
      DeadlineUrgency.soon,
    );

    final okTrip = Trip(
      id: trip.id,
      number: trip.number,
      status: trip.status,
      statusLabel: trip.statusLabel,
      from: trip.from,
      to: trip.to,
      dateStart: '14.09.2026 12:00',
    );
    expect(
      tripDeadline(okTrip, DateTime(2026, 9, 13, 12))?.urgency,
      DeadlineUrgency.ok,
    );
  });

  test('читает историю статусов и титулы ЭТрН', () {
    final trip = Trip.fromJson({
      'id': 8,
      'number': 'E-8',
      'status': 'in_transit',
      'from': 'Москва',
      'to': 'Тверь',
      'assigned_at': '2024-03-14T18:40:00',
      'in_transit_at': '2024-03-15T10:20:00',
      'etrn': {
        'titles': [
          {
            'code': 'T1',
            'signed': true,
            'signed_at': '2024-03-14T17:05:00',
            'signed_by': 'ООО Склад',
          },
          {'code': 'T2', 'signed': false},
        ],
      },
      'shipments': [
        {
          'id': 's1',
          'title': 'Паллета',
          'titles': [
            {
              'code': 'T3',
              'signed_at': '2024-03-16T12:00:00',
              'signed_by': 'ООО Магазин',
            },
          ],
        },
      ],
    });

    expect(trip.statusHistory.map((item) => item.status), ['assigned', 'in_transit']);
    expect(tripStatusChangedAt(trip, 'assigned'), '14.03.2024 18:40');
    expect(tripStatusChangedAt(trip, 'transit'), '15.03.2024 10:20');
    expect(trip.etrnTitles.map((item) => item.code), ['T1', 'T2']);
    expect(trip.etrnTitles.first.signed, isTrue);
    expect(trip.shipments.single.titles.single.code, 'T3');
    expect(tripMatchesQuery(trip, 'твер'), isTrue);
    expect(tripMatchesQuery(trip, 'E-8'), isTrue);
    expect(tripMatchesQuery(trip, '14.03'), isTrue);
    expect(tripMatchesQuery(trip, 'Казань'), isFalse);
  });

  test('читает доверенность поставки и время выезда как смену статуса', () {
    final trip = Trip.fromJson({
      'id': 9,
      'number': 'E-9',
      'status': 'in_transit',
      'from': 'Москва',
      'to': 'Тверь',
      'status_history': [
        {'status': 'assigned', 'at': '2024-03-14T18:40:00'},
        {'status': 'in_transit', 'at': '2024-03-15T10:20:00'},
      ],
      'shipments': [
        {
          'id': 's1',
          'title': 'Паллета',
          'attorney': {'number': 'Д-22', 'date': '2024-03-01'},
        },
      ],
    });

    expect(trip.shipments.single.attorneyNumber, 'Д-22');
    expect(trip.shipments.single.attorneyDate, '01.03.2024');
    expect(tripStatusChangedAt(trip, 'assigned'), '14.03.2024 18:40');
    expect(tripStatusChangedAt(trip, 'load'), '15.03.2024 10:20');
    expect(tripStatusChangedAt(trip, 'transit'), '15.03.2024 10:20');
  });
}
