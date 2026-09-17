import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/services/pending_actions.dart';
import 'package:phone_auth_app/services/secure_kv.dart';

void main() {
  test('PendingActionsQueue сохраняет и отдаёт действия по рейсу', () async {
    final queue = PendingActionsQueue(kv: MemorySecureKv());
    await queue.enqueue(
      const PendingAction(
        id: 'status:1:in_transit',
        type: PendingActionType.status,
        tripId: '1',
        status: 'in_transit',
      ),
    );
    await queue.enqueue(
      const PendingAction(
        id: 'photo:2:x',
        type: PendingActionType.photo,
        tripId: '2',
        filePath: '/tmp/a.jpg',
      ),
    );

    expect((await queue.forTrip('1')).single.status, 'in_transit');
    expect((await queue.list()).length, 2);

    await queue.remove('status:1:in_transit');
    expect(await queue.forTrip('1'), isEmpty);
    expect((await queue.list()).single.tripId, '2');
  });
}
