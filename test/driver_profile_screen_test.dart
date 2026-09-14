import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_auth_app/api/mock_driver_api.dart';
import 'package:phone_auth_app/screens/driver_profile_screen.dart';
import 'package:phone_auth_app/services/pep_vault.dart';
import 'package:phone_auth_app/services/secure_kv.dart';
import 'package:phone_auth_app/widgets/id_document_card.dart';
import 'package:phone_auth_app/widgets/ru_license_plate.dart';

void main() {
  testWidgets('профиль показывает паспорт и ВУ карточками', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DriverProfileScreen(
        api: MockDriverApi(),
        pep: PepVault(kv: MemorySecureKv()),
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Подпись'), findsOneWidget);
    expect(find.text('Выпустить ПЭП'), findsOneWidget);
    expect(find.text('Документы'), findsOneWidget);
    expect(find.text('ПАСПОРТ'), findsOneWidget);
    expect(find.text('ВОДИТЕЛЬСКОЕ УДОСТОВЕРЕНИЕ'), findsOneWidget);
    expect(find.text('Повернуть'), findsOneWidget);
    expect(find.text('Копировать'), findsOneWidget);
    expect(find.text('45 10  123456'), findsOneWidget);
    expect(find.textContaining('12 34 567890'), findsWidgets);
    expect(find.text('Дата выдачи'), findsOneWidget);
    expect(find.text('01.03.2015'), findsOneWidget);
    expect(find.textContaining('12.05.2020'), findsWidgets);
    expect(find.textContaining('ГИБДД, Москва'), findsWidgets);
    expect(find.text('Иванов Иван Иванович'), findsOneWidget);
    expect(find.text('ООО Перевозчик'), findsOneWidget);
    expect(find.byType(PassportDocumentCard), findsOneWidget);
    expect(find.byType(LicenseDocumentCard), findsOneWidget);
    expect(find.byType(RuLicensePlateBadge), findsOneWidget);

    await tester.ensureVisible(find.text('Повернуть'));
    await tester.pump();
    await tester.tap(find.text('Повернуть'));
    await tester.pump();

    expect(find.text('ОТКРЫТЫЕ КАТЕГОРИИ'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('CE'), findsOneWidget);
    expect(find.textContaining('12 34 567890'), findsNothing);
  });

  testWidgets('в профиле можно выпустить ПЭП', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DriverProfileScreen(
        api: MockDriverApi(),
        pep: PepVault(kv: MemorySecureKv()),
      ),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Выпустить ПЭП'));
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Выпустить'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Ключ'), findsOneWidget);
    expect(find.text('Отозвать подпись'), findsOneWidget);
  });
}
