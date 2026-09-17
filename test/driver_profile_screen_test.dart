import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/api/mock_driver_api.dart';
import 'package:phone_auth_app/screens/driver_profile_screen.dart';
import 'package:phone_auth_app/services/local_notifications.dart';
import 'package:phone_auth_app/services/max_digital_id.dart';
import 'package:phone_auth_app/services/notification_prefs_store.dart';
import 'package:phone_auth_app/services/pep_vault.dart';
import 'package:phone_auth_app/services/push_registration.dart';
import 'package:phone_auth_app/services/rustore_push_gateway.dart';
import 'package:phone_auth_app/services/secure_kv.dart';
import 'package:phone_auth_app/widgets/id_document_card.dart';
import 'package:phone_auth_app/widgets/ru_license_plate.dart';

PushRegistration _push(MemorySecureKv kv, {bool permission = true}) {
  return PushRegistration(
    prefsStore: NotificationPrefsStore(kv: kv),
    notifications: FakeLocalNotifications(permissionGranted: permission),
    rustore: FakeRuStorePushGateway(),
    kv: kv,
  );
}

void main() {
  testWidgets('профиль открывает паспорт и ВУ из плиток', (tester) async {
    final kv = MemorySecureKv();
    await tester.pumpWidget(MaterialApp(
      home: DriverProfileScreen(
        api: MockDriverApi(),
        pep: PepVault(kv: kv),
        maxDigitalId: MaxDigitalIdService(),
        push: _push(kv),
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Уведомления'), findsOneWidget);
    expect(find.text('Документы'), findsOneWidget);
    expect(find.text('Паспорт'), findsOneWidget);
    expect(find.text('Водительское'), findsOneWidget);
    expect(find.text('Подпись и MAX'), findsOneWidget);
    expect(find.text('Выйти'), findsOneWidget);
    expect(find.byType(RuLicensePlateBadge), findsOneWidget);
    expect(find.text('Иванов Иван Иванович'), findsOneWidget);
    expect(find.text('ООО Перевозчик'), findsOneWidget);

    await tester.tap(find.text('Паспорт'));
    await tester.pumpAndSettle();
    expect(find.text('ПАСПОРТ'), findsOneWidget);
    expect(find.text('45 10  123456'), findsOneWidget);
    expect(find.text('Дата выдачи'), findsOneWidget);
    expect(find.text('01.03.2015'), findsOneWidget);
    expect(find.byType(PassportDocumentCard), findsOneWidget);
    Navigator.of(tester.element(find.byType(PassportDocumentCard))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Водительское'));
    await tester.pumpAndSettle();
    expect(find.text('ВОДИТЕЛЬСКОЕ УДОСТОВЕРЕНИЕ'), findsOneWidget);
    expect(find.textContaining('12 34 567890'), findsWidgets);
    expect(find.textContaining('12.05.2020'), findsWidgets);
    expect(find.textContaining('ГИБДД, Москва'), findsWidgets);
    expect(find.byType(LicenseDocumentCard), findsOneWidget);

    await tester.ensureVisible(find.text('Повернуть'));
    await tester.tap(find.text('Повернуть'));
    await tester.pumpAndSettle();

    expect(find.text('ОТКРЫТЫЕ КАТЕГОРИИ'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('CE'), findsOneWidget);
    expect(find.textContaining('12 34 567890'), findsNothing);
  });

  testWidgets('в профиле можно выпустить ПЭП', (tester) async {
    final kv = MemorySecureKv();
    await tester.pumpWidget(MaterialApp(
      home: DriverProfileScreen(
        api: MockDriverApi(),
        pep: PepVault(kv: kv),
        maxDigitalId: MaxDigitalIdService(),
        push: _push(kv),
      ),
    ));
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('Подпись и MAX'));
    await tester.tap(find.text('Подпись и MAX'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Выпустить ПЭП'));
    await tester.tap(find.text('Выпустить ПЭП'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Выпустить'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ключ '), findsOneWidget);
    expect(find.text('Отозвать подпись'), findsOneWidget);
  });

  testWidgets('в профиле есть управление уведомлениями', (tester) async {
    final kv = MemorySecureKv();
    final notifications = FakeLocalNotifications(permissionGranted: true);
    await tester.pumpWidget(MaterialApp(
      home: DriverProfileScreen(
        api: MockDriverApi(),
        pep: PepVault(kv: kv),
        maxDigitalId: MaxDigitalIdService(),
        push: PushRegistration(
          prefsStore: NotificationPrefsStore(kv: kv),
          notifications: notifications,
          rustore: FakeRuStorePushGateway(),
          kv: kv,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Уведомления'), findsOneWidget);
    expect(find.text('Включить'), findsOneWidget);
    expect(find.text('Новые рейсы'), findsOneWidget);
    expect(find.text('Сроки погрузки и выгрузки'), findsOneWidget);
    expect(find.text('Проверить уведомление'), findsOneWidget);

    await tester.ensureVisible(find.text('Проверить уведомление'));
    await tester.tap(find.text('Проверить уведомление'));
    await tester.pump();
    expect(notifications.testShown, 1);
  });
}
