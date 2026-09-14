import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/services/max_digital_id.dart';
import 'package:phone_auth_app/services/secure_kv.dart';

void main() {
  test('MaxDigitalIdService хранит локальную отметку связки', () async {
    final service = MaxDigitalIdService(kv: MemorySecureKv());
    expect(await service.isLinked('driver-1'), isFalse);

    await service.setLinked('driver-1', true);
    expect(await service.isLinked('driver-1'), isTrue);
    expect(await service.isLinked('driver-2'), isFalse);

    await service.setLinked('driver-1', false);
    expect(await service.isLinked('driver-1'), isFalse);
  });
}
