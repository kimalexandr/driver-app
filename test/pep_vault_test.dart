import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/models/external_auth.dart';
import 'package:phone_auth_app/services/pep_vault.dart';
import 'package:phone_auth_app/services/secure_kv.dart';

void main() {
  test('выпускает, хранит и подписывает ПЭП на устройстве', () async {
    final vault = PepVault(
      kv: MemorySecureKv(),
      random: Random(7),
      now: () => DateTime.utc(2026, 9, 13, 12),
    );

    expect(await vault.read('1'), isNull);

    final record = await vault.issue(
      driverId: '1',
      via: AuthProviderKind.gosuslugi,
    );
    expect(record.kid, isNotEmpty);
    expect(record.issuedVia, AuthProviderKind.gosuslugi);
    expect((await vault.read('1'))?.kid, record.kid);
    expect(await vault.linkedProviders(), {AuthProviderKind.gosuslugi});

    final signature = await vault.sign(driverId: '1', payload: 'T2:trip-1');
    expect(signature.kid, record.kid);
    expect(signature.signature, isNotEmpty);

    await vault.revoke('1');
    expect(await vault.read('1'), isNull);
    expect(
      () => vault.sign(driverId: '1', payload: 'T2:trip-1'),
      throwsStateError,
    );
  });
}
