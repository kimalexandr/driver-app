import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/trip.dart';

void main() {
  test('читает товар, вес, объём и стороны из JSON', () {
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
      'sender': {
        'company': 'ООО Отправитель',
        'name': 'Иванов',
        'phone': '79991112233',
        'address': 'Москва, 1',
      },
      'recipient': {
        'company': 'ООО Получатель',
        'name': 'Петров',
        'phone': '79993334455',
      },
      'shipments': [
        {
          'id': 1,
          'name': 'Паллета 1',
          'weight_kg': 800,
          'volume_m3': 4,
          'comment': 'Хрупкое',
        },
      ],
    });

    expect(trip.comment, 'Звонить за час');
    expect(trip.cargo, 'Запчасти');
    expect(trip.weightKg, 1200);
    expect(trip.volumeM3, 6.5);
    expect(trip.sender.company, 'ООО Отправитель');
    expect(trip.sender.phone, '79991112233');
    expect(trip.recipient.name, 'Петров');
    expect(trip.shipments.single.title, 'Паллета 1');
    expect(trip.shipments.single.weightKg, 800);
    expect(formatKg(trip.weightKg), '1200 кг');
    expect(formatM3(trip.volumeM3), '6.5 м³');
    expect(trip.destination, 'Москва');
    expect(trip.copyWith(status: 'in_transit').destination, 'Казань');
    expect(trip.copyWith(status: 'delivered').isCompleted, isTrue);
  });
}
