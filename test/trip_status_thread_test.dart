import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/trip.dart';
import 'package:phone_auth_app/widgets/trip_status_thread.dart';

void main() {
  const base = Trip(
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
    statusHistory: [
      StatusEvent(status: 'assigned', label: 'Назначен', at: '14.03.2024 18:40'),
    ],
  );

  test('assigned trip highlights loading as current step', () {
    final steps = tripThreadSteps(base);
    expect(steps.map((step) => step.id).toList(),
        ['assigned', 'load', 'transit', 'unload', 'delivered']);
    expect(steps[0].phase, ThreadPhase.done);
    expect(steps[0].changedAt, '14.03.2024 18:40');
    expect(steps[1].phase, ThreadPhase.current);
    expect(steps[1].changedAt, '');
    expect(steps[1].title, 'Погрузка');
    expect(steps[1].window, '09:00–12:00');
    expect(steps[2].phase, ThreadPhase.upcoming);
    expect(steps[2].hint, '705 км между пунктами');
  });

  test('in-transit trip highlights the road to unload', () {
    final steps = tripThreadSteps(base.copyWith(
      status: 'in_transit',
      statusLabel: 'В пути',
      statusHistory: const [
        StatusEvent(status: 'assigned', label: 'Назначен', at: '14.03.2024 18:40'),
        StatusEvent(status: 'in_transit', label: 'В пути', at: '15.03.2024 10:20'),
      ],
    ));
    expect(steps[1].phase, ThreadPhase.done);
    expect(steps[1].changedAt, '15.03.2024 10:20');
    expect(steps[2].phase, ThreadPhase.current);
    expect(steps[2].hint, '705 км до Санкт-Петербург');
    expect(steps[2].changedAt, '15.03.2024 10:20');
    expect(steps[3].phase, ThreadPhase.upcoming);
  });

  test('assigned with only unload stop still highlights loading, not unload', () {
    final steps = tripThreadSteps(base.copyWith(
      stops: const [
        TripStop(type: 'unload', title: 'СПб', address: 'Невский'),
      ],
    ));
    final current = steps.where((step) => step.phase == ThreadPhase.current).toList();
    expect(current, isNotEmpty);
    expect(current.single.id, 'assigned');
    expect(
      steps.where((step) => step.title == 'Выгрузка' && step.phase == ThreadPhase.current),
      isEmpty,
    );
  });

  test('in_transit with stops keeps transit as current, not unload', () {
    final steps = tripThreadSteps(base.copyWith(
      status: 'in_transit',
      statusLabel: 'В пути',
      stops: const [
        TripStop(type: 'load', title: 'Москва'),
        TripStop(type: 'unload', title: 'СПб'),
      ],
      statusHistory: const [
        StatusEvent(status: 'in_transit', label: 'В пути', at: '15.03.2024 10:20'),
      ],
    ));
    final current = steps.where((step) => step.phase == ThreadPhase.current).single;
    expect(current.id, 'transit');
    expect(current.changedAt, '15.03.2024 10:20');
  });

  test('delivered trip marks the whole thread done', () {
    final steps = tripThreadSteps(base.copyWith(
      status: 'delivered',
      statusLabel: 'Доставлено',
    ));
    expect(steps.every((step) => step.phase == ThreadPhase.done), isTrue);
  });
}
