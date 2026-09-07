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
}
