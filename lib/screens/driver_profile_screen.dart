import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../models/driver_profile.dart';
import '../models/external_auth.dart';
import '../models/notification_prefs.dart';
import '../models/pep.dart';
import '../services/external_auth.dart';
import '../services/local_notifications.dart';
import '../services/max_digital_id.dart';
import '../services/notification_prefs_store.dart';
import '../services/pep_vault.dart';
import '../services/push_registration.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/id_document_card.dart';
import '../widgets/max_digital_id_card.dart';
import '../widgets/notification_settings_card.dart';
import '../widgets/pep_card.dart';
import '../widgets/ru_license_plate.dart';

class DriverProfileScreen extends StatefulWidget {
  final DriverApi? api;
  final PepVault? pep;
  final MaxDigitalIdService? maxDigitalId;
  final PushRegistration? push;

  const DriverProfileScreen({
    super.key,
    this.api,
    this.pep,
    this.maxDigitalId,
    this.push,
  });

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  DriverProfile? _driver;
  PepRecord? _pep;
  Set<AuthProviderKind> _linked = {};
  String? _error;
  bool _loading = true;
  bool _pepBusy = false;
  bool _maxBusy = false;
  NotificationPrefs _notifyPrefs = NotificationPrefs.defaults;
  bool _notifyPermission = false;
  bool _notifyBusy = false;
  String? _pushStatus;

  DriverApi? get _api => widget.api ?? AppScope.maybeOf(context)?.api;

  PepVault get _vault =>
      widget.pep ?? AppScope.maybeOf(context)?.pep ?? PepVault();

  MaxDigitalIdService get _maxId =>
      widget.maxDigitalId ?? MaxDigitalIdService();

  PushRegistration get _push =>
      widget.push ??
      AppScope.maybeOf(context)?.push ??
      PushRegistration(
        prefsStore: NotificationPrefsStore(),
        notifications: LocalNotifications(),
      );

  String get _owner {
    final driver = _driver;
    if (driver == null) return 'local';
    if (driver.id.isNotEmpty) return driver.id;
    if (driver.phone.isNotEmpty) return driver.phone;
    return 'local';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final scope = AppScope.maybeOf(context);
    final api = _api;
    if (api == null) {
      setState(() {
        _driver = const DriverProfile(id: '', name: '', phone: '');
        _loading = false;
      });
      await _reloadPep();
      return;
    }
    try {
      final loaded = await api.me();
      final driver = loaded.orFallback(scope?.auth.driver);
      scope?.auth.applyProfile(driver);
      if (!mounted) return;
      setState(() {
        _driver = driver;
        _loading = false;
      });
      await _reloadPep();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _driver = scope?.auth.driver;
        _error = error.message;
        _loading = false;
      });
      await _reloadPep();
    }
  }

  Future<void> _reloadPep() async {
    PepRecord? record;
    var linked = <AuthProviderKind>{};
    var notifyPrefs = NotificationPrefs.defaults;
    var notifyPermission = false;
    try {
      record = await _vault.read(_owner);
      linked = await _vault.linkedProviders();
    } catch (_) {}
    try {
      notifyPrefs = await _push.currentPrefs(_owner);
      notifyPermission = await _push.hasPermission();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _pep = record;
      _linked = linked;
      _notifyPrefs = notifyPrefs;
      _notifyPermission = notifyPermission;
      _pushStatus = _push.lastStatus;
    });
  }

  Future<void> _requestNotifyPermission() async {
    setState(() => _notifyBusy = true);
    try {
      final granted = await _push.ensurePermission();
      if (!mounted) return;
      setState(() => _notifyPermission = granted);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешение на уведомления не выдано'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }
      final api = _api;
      if (api != null) {
        await _push.sync(api: api, owner: _owner);
      }
      if (!mounted) return;
      setState(() => _pushStatus = _push.lastStatus);
    } finally {
      if (mounted) setState(() => _notifyBusy = false);
    }
  }

  Future<void> _saveNotifyPrefs(NotificationPrefs prefs) async {
    setState(() {
      _notifyBusy = true;
      _notifyPrefs = prefs;
    });
    try {
      await _push.savePrefs(_owner, prefs, api: _api);
      final api = _api;
      if (api != null && prefs.enabled) {
        await _push.sync(api: api, owner: _owner);
      }
      if (!mounted) return;
      setState(() => _pushStatus = _push.lastStatus);
    } finally {
      if (mounted) setState(() => _notifyBusy = false);
    }
  }

  Future<void> _testNotify() async {
    setState(() => _notifyBusy = true);
    try {
      if (!_notifyPermission) {
        final granted = await _push.ensurePermission();
        if (!mounted) return;
        setState(() => _notifyPermission = granted);
        if (!granted) return;
      }
      await _push.notifications.showTest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Тестовое уведомление отправлено'),
          backgroundColor: AppColors.navy,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось показать уведомление'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _notifyBusy = false);
    }
  }

  Future<void> _openMaxDigitalId() async {
    setState(() => _maxBusy = true);
    try {
      final opened = await _maxId.openInMax();
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть MAX. Установите мессенджер MAX.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _maxBusy = false);
    }
  }

  Future<void> _openMaxGuide() async {
    await _maxId.openGuide();
  }

  Future<void> _issuePep() async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => const _PepConsentDialog(),
    );
    if (agreed != true) return;
    setState(() => _pepBusy = true);
    try {
      final via = _linked.contains(AuthProviderKind.gosuslugi)
          ? AuthProviderKind.gosuslugi
          : _linked.contains(AuthProviderKind.goskey)
              ? AuthProviderKind.goskey
              : AuthProviderKind.sms;
      final record = await _vault.issue(driverId: _owner, via: via);
      try {
        await _api?.registerPep(record);
      } on ApiException {
        // ключ уже на устройстве — сервер может ещё не принимать ПЭП
      }
      await _reloadPep();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ПЭП выпущена и хранится на этом телефоне'),
          backgroundColor: AppColors.navy,
        ),
      );
    } finally {
      if (mounted) setState(() => _pepBusy = false);
    }
  }

  Future<void> _revokePep() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отозвать ПЭП?'),
        content: const Text(
          'Ключ будет удалён с этого телефона. Подписывать документы этим ключом больше нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отозвать'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _pepBusy = true);
    try {
      await _vault.revoke(_owner);
      await _reloadPep();
    } finally {
      if (mounted) setState(() => _pepBusy = false);
    }
  }

  Future<void> _external(AuthProviderKind provider) async {
    final api = _api;
    if (api == null) return;
    setState(() => _pepBusy = true);
    try {
      final outcome = await ExternalAuthService(api).authenticate(provider);
      if (outcome.session != null) {
        await _vault.linkProvider(provider);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            outcome.session != null
                ? '${provider.title} привязаны к этому телефону'
                : (outcome.message ?? 'Откройте ${provider.title}'),
          ),
          backgroundColor:
              outcome.session != null ? AppColors.navy : AppColors.ink,
        ),
      );
      await _reloadPep();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _pepBusy = false);
    }
  }

  Future<void> _logout() async {
    final scope = AppScope.maybeOf(context);
    scope?.locationTracker.stop();
    final api = scope?.api;
    final push = scope?.push;
    final owner = _owner;
    if (api != null && push != null) {
      try {
        await push.unregister(api: api, owner: owner);
      } catch (_) {}
    }
    await scope?.auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/phone', (route) => false);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'В';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final driver = _driver ?? AppScope.maybeOf(context)?.auth.driver;
    final license = driver?.license ?? const DriverLicense();
    final passport = driver?.passport ?? const DriverPassport();
    final auto = driver?.auto;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  _identity(driver),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  if (auto?.hasContent ?? false) ...[
                    const SizedBox(height: 16),
                    _vehicleCard(auto!),
                  ],
                  const SizedBox(height: 20),
                  _section('Документы'),
                  DocumentOpenTile(
                    icon: Icons.menu_book_rounded,
                    accent: const Color(0xFFBE123C),
                    title: 'Паспорт',
                    subtitle: passport.hasContent
                        ? passport.displaySeriesNumber
                        : 'Открыть карточку',
                    onOpen: () => showPassportSheet(
                      context: context,
                      passport: passport,
                      holderName: driver?.name ?? '',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DocumentOpenTile(
                    icon: Icons.badge_outlined,
                    accent: const Color(0xFF0D9488),
                    title: 'Водительское',
                    subtitle: license.hasContent
                        ? license.displayNumber
                        : 'Открыть карточку',
                    onOpen: () => showLicenseSheet(
                      context: context,
                      license: license,
                      holderName: driver?.name ?? '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _section('Уведомления'),
                  NotificationSettingsCard(
                    prefs: _notifyPrefs,
                    permissionGranted: _notifyPermission,
                    busy: _notifyBusy,
                    statusText: _pushStatus,
                    onChanged: _saveNotifyPrefs,
                    onRequestPermission: _requestNotifyPermission,
                    onTest: _testNotify,
                  ),
                  const SizedBox(height: 24),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      initiallyExpanded: false,
                      title: const Text(
                        'Подпись и MAX',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      subtitle: const Text(
                        'ПЭП, Госуслуги, Цифровой ID',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      children: [
                        PepCard(
                          record: _pep,
                          linked: _linked,
                          busy: _pepBusy,
                          onIssue: _issuePep,
                          onRevoke: _revokePep,
                          onGosuslugi: () =>
                              _external(AuthProviderKind.gosuslugi),
                          onGoskey: () => _external(AuthProviderKind.goskey),
                        ),
                        const SizedBox(height: 16),
                        MaxDigitalIdCard(
                          busy: _maxBusy,
                          onOpenMax: _openMaxDigitalId,
                          onGuide: _openMaxGuide,
                        ),
                      ],
                    ),
                  ),
                  if (_hasContacts(driver)) ...[
                    const SizedBox(height: 24),
                    _section('Контакты'),
                    _contactCard(driver),
                  ],
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                    ),
                  ),
                ],
                ),
              ),
            ),
    );
  }

  Widget _identity(DriverProfile? driver) {
    final name = (driver?.name ?? '').trim();
    final company = (driver?.carrierName ?? '').trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.navy,
          child: Text(
            _initials(name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Водитель' : name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  height: 1.2,
                ),
              ),
              if (company.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  company,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _hasContacts(DriverProfile? driver) {
    if (driver == null) return false;
    return driver.phone.isNotEmpty ||
        driver.phoneSecondary.isNotEmpty ||
        driver.email.isNotEmpty;
  }

  Widget _contactCard(DriverProfile? driver) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _row('Телефон', driver?.phone),
          _row('Доп. телефон', driver?.phoneSecondary),
          _row('Почта', driver?.email),
        ],
      ),
    );
  }

  Widget _vehicleCard(DriverAuto auto) {
    final spec = [
      if (auto.year.isNotEmpty) auto.year,
      if (auto.color.isNotEmpty) auto.color,
      if (auto.carCategory.isNotEmpty) 'кат. ${auto.carCategory}',
      if (auto.bodyType.isNotEmpty) auto.bodyType,
    ].join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (auto.stateNumber.isNotEmpty)
            RuLicensePlateBadge(number: auto.stateNumber),
          if (auto.title.isNotEmpty && auto.title != auto.stateNumber) ...[
            const SizedBox(height: 10),
            Text(
              [auto.brand, auto.model].where((part) => part.isNotEmpty).join(' '),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
          if (spec.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(spec, style: const TextStyle(color: AppColors.muted)),
          ],
          if (auto.stsNumber.isNotEmpty) _row('СТС', auto.stsNumber),
          if (auto.vin.isNotEmpty) _row('VIN', auto.vin),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
    );
  }

  Widget _row(String title, String? content) {
    if (content == null || content.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              title,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PepConsentDialog extends StatefulWidget {
  const _PepConsentDialog();

  @override
  State<_PepConsentDialog> createState() => _PepConsentDialogState();
}

class _PepConsentDialogState extends State<_PepConsentDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выпуск ПЭП'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Простая электронная подпись создаётся на этом телефоне. '
            'Ею подтверждаются ваши действия в приложении: приём и сдача груза. '
            'Закрытый ключ не передаётся на сервер.',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _agreed,
            onChanged: (value) => setState(() => _agreed = value ?? false),
            title: const Text(
              'Согласен, что действия с моей учётной записью подписываются этой ПЭП',
              style: TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _agreed ? () => Navigator.pop(context, true) : null,
          child: const Text('Выпустить'),
        ),
      ],
    );
  }
}
