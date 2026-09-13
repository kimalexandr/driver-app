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
  );

  test('assigned trip highlights loading as current step', () {
    final steps = tripThreadSteps(base);
    expect(steps.map((step) => step.id).toList(),
        ['assigned', 'load', 'transit', 'unload', 'delivered']);
    expect(steps[0].phase, ThreadPhase.done);
    expect(steps[1].phase, ThreadPhase.current);
    expect(steps[1].title, 'Погрузка');
    expect(steps[1].window, '09:00–12:00');
    expect(steps[2].phase, ThreadPhase.upcoming);
    expect(steps[2].hint, '705 км между пунктами');
  });

  test('in-transit trip highlights the road to unload', () {
    final steps = tripThreadSteps(base.copyWith(
      status: 'in_transit',
      statusLabel: 'В пути',
    ));
    expect(steps[1].phase, ThreadPhase.done);
    expect(steps[2].phase, ThreadPhase.current);
    expect(steps[2].hint, '705 км до Санкт-Петербург');
    expect(steps[3].phase, ThreadPhase.upcoming);
  });

  test('delivered trip marks the whole thread done', () {
    final steps = tripThreadSteps(base.copyWith(
      status: 'delivered',
      statusLabel: 'Доставлено',
    ));
    expect(steps.every((step) => step.phase == ThreadPhase.done), isTrue);
  });
}
