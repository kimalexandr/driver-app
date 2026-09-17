import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../models/driver_profile.dart';
import '../models/trip.dart';
import '../services/location_service.dart';
import '../services/pending_actions.dart';
import '../services/yandex_maps.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/etrn_titles.dart';
import '../widgets/ru_license_plate.dart';
import '../widgets/status_chip.dart';
import '../widgets/trip_deadline_banner.dart';
import '../widgets/trip_status_thread.dart';

class RequestDetailsScreen extends StatefulWidget {
  final Trip trip;
  final DriverApi? api;
  final PendingActionsQueue? pending;

  const RequestDetailsScreen({
    super.key,
    required this.trip,
    this.api,
    this.pending,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  late Trip _trip;
  bool _busy = false;
  List<PendingAction> _pending = const [];
  late final PendingActionsQueue _queue;

  DriverApi? get _api => widget.api ?? AppScope.maybeOf(context)?.api;

  LocationService get _location =>
      AppScope.maybeOf(context)?.locationService ?? LocationService();

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _queue = widget.pending ?? PendingActionsQueue();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _reload();
      await _loadPending();
      await _flushPending();
    });
  }

  Future<void> _loadPending() async {
    final items = await _queue.forTrip(_trip.id);
    if (!mounted) return;
    setState(() => _pending = items);
  }

  Future<void> _reload() async {
    final api = _api;
    if (api == null) return;
    try {
      final trip = await api.getTrip(_trip.id);
      if (!mounted) return;
      setState(() => _trip = trip.orFallback(_trip));
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    }
  }

  void _showError(String message, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: 'Повторить',
                textColor: Colors.white,
                onPressed: onRetry,
              ),
      ),
    );
  }

  void _showOk(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.navy),
    );
  }

  Future<bool> _confirmStatus(String status) async {
    final isStart = status == 'in_transit';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isStart ? 'Отметить «В пути»?' : 'Отметить «Доставлено»?'),
        content: Text(
          isStart
              ? 'Подтвердите, что вы выехали или уже на погрузке.'
              : 'Подтвердите, что груз сдан и рейс можно закрыть.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _setStatus(String status, {bool confirm = true}) async {
    if (_busy) return;
    if (confirm && !await _confirmStatus(status)) return;
    final api = _api;
    if (api == null) return;
    setState(() => _busy = true);
    try {
      final trip = await api.updateTripStatus(tripId: _trip.id, status: status);
      final pendingId = 'status:${_trip.id}:$status';
      await _queue.remove(pendingId);
      if (!mounted) return;
      setState(() => _trip = trip.orFallback(_trip));
      await _loadPending();
      HapticFeedback.mediumImpact();
    } catch (error) {
      if (!mounted) return;
      final action = PendingAction(
        id: 'status:${_trip.id}:$status',
        type: PendingActionType.status,
        tripId: _trip.id,
        status: status,
      );
      await _queue.enqueue(action);
      await _loadPending();
      _showError(
        error is ApiException
            ? '${error.message}. Сохранено для отправки.'
            : 'Не отправилось — повторить',
        onRetry: () => _setStatus(status, confirm: false),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPlace({
    required String address,
    double? lat,
    double? lng,
  }) async {
    HapticFeedback.lightImpact();
    final opened = await openYandexPlace(
      address: address,
      lat: lat,
      lng: lng,
    );
    if (!opened && mounted) {
      _showError('Нет адреса или координат для карты');
    }
  }

  Future<void> _openTripRoute() async {
    HapticFeedback.lightImpact();
    final opened = await openYandexNavigateTo(
      address: _trip.destination,
      lat: _trip.destinationLat,
      lng: _trip.destinationLng,
    );
    if (!opened && mounted) {
      _showError('Нет адреса или координат для навигации');
    }
  }

  Future<void> _copyText(String value, String okMessage) async {
    final text = value.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showOk(okMessage);
  }

  Future<void> _sendLocation({PendingAction? queued}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      late final double lat;
      late final double lng;
      if (queued?.lat != null && queued?.lng != null) {
        lat = queued!.lat!;
        lng = queued.lng!;
      } else {
        final point = await _location.current();
        if (point == null) {
          if (!mounted) return;
          _showError('Не удалось получить геолокацию. Проверьте разрешение.');
          return;
        }
        lat = point.lat;
        lng = point.lng;
      }
      final api = _api;
      if (api == null) return;
      await api.sendLocation(tripId: _trip.id, lat: lat, lng: lng);
      if (queued != null) await _queue.remove(queued.id);
      if (!mounted) return;
      await _loadPending();
      _showOk('Местоположение отправлено');
    } catch (_) {
      if (!mounted) return;
      final point = await _location.current();
      final action = PendingAction(
        id: queued?.id ??
            'location:${_trip.id}:${DateTime.now().millisecondsSinceEpoch}',
        type: PendingActionType.location,
        tripId: _trip.id,
        lat: point?.lat ?? queued?.lat,
        lng: point?.lng ?? queued?.lng,
      );
      if (action.lat != null && action.lng != null) {
        await _queue.enqueue(action);
        await _loadPending();
      }
      _showError(
        'Не отправилось — повторить',
        onRetry: () => _sendLocation(queued: action.lat != null ? action : null),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attachPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await _uploadPhoto(file.path);
  }

  Future<void> _uploadPhoto(String path, {PendingAction? queued}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = _api;
      if (api == null) return;
      await api.uploadFile(tripId: _trip.id, filePath: path);
      if (queued != null) await _queue.remove(queued.id);
      if (!mounted) return;
      await _loadPending();
      _showOk('Фото прикреплено');
    } catch (_) {
      if (!mounted) return;
      final action = queued ??
          PendingAction(
            id: 'photo:${_trip.id}:${path.hashCode}',
            type: PendingActionType.photo,
            tripId: _trip.id,
            filePath: path,
          );
      await _queue.enqueue(action);
      await _loadPending();
      _showError(
        'Не отправилось — повторить',
        onRetry: () => _uploadPhoto(path, queued: action),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _flushPending() async {
    final items = await _queue.forTrip(_trip.id);
    for (final action in items) {
      switch (action.type) {
        case PendingActionType.status:
          if (action.status != null) {
            await _setStatus(action.status!, confirm: false);
          }
        case PendingActionType.photo:
          if (action.filePath != null) {
            await _uploadPhoto(action.filePath!, queued: action);
          }
        case PendingActionType.location:
          await _sendLocation(queued: action);
      }
    }
    await _loadPending();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => _copyText(_trip.number, 'Номер рейса скопирован'),
          child: Text('Рейс №${_trip.number}'),
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          _pinnedBar(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.navy,
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_pending.isNotEmpty) ...[
                      Material(
                        color: const Color(0xFFF8D9D5),
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          leading: const Icon(Icons.cloud_off, color: AppColors.red),
                          title: Text(
                            'Не отправлено: ${_pending.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.red,
                            ),
                          ),
                          subtitle: const Text('Нажмите, чтобы повторить'),
                          trailing: const Icon(Icons.refresh, color: AppColors.red),
                          onTap: _busy ? null : _flushPending,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TripDeadlineBanner(trip: _trip),
                    TripStatusThread(trip: _trip, onOpenPlace: _openPlace),
                    if (_trip.statusHistory.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _statusHistoryCard(),
                    ],
                    const SizedBox(height: 16),
                    _card(
                      title: 'ЭТрН и договоры',
                      child: _trip.allEpdDocuments.isEmpty &&
                              _trip.allEtrnTitles.isEmpty
                          ? const Text(
                              'ЭТрН, ПЭ и ЭР появятся здесь, когда документы пришлют.',
                              style: TextStyle(color: AppColors.muted, height: 1.35),
                            )
                          : EtrnTitlesBlock(
                              documents: _trip.allEpdDocuments,
                              titles: _trip.allEtrnTitles,
                              compact: true,
                            ),
                    ),
                    if (_showAutoCard) ...[
                      const SizedBox(height: 16),
                      _autoCard(),
                    ],
                    if (_trip.hasAnyAttorney) ...[
                      const SizedBox(height: 16),
                      _attorneyCard(),
                    ],
                    if (_showTripComment) ...[
                      const SizedBox(height: 16),
                      _card(
                        title: 'Комментарий рейса',
                        child: Text(_trip.comment, style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                    if (_hasCargoBlock) ...[
                      const SizedBox(height: 16),
                      _cargoCard(),
                    ],
                    if (_showSender) ...[
                      const SizedBox(height: 16),
                      _partyCard(
                        'Отправитель',
                        _trip.sender,
                        hideCompany: _trip.startCompany,
                        hideAddress: _trip.startAddress,
                      ),
                    ],
                    if (_showRecipient) ...[
                      const SizedBox(height: 16),
                      _partyCard(
                        'Получатель',
                        _trip.recipient,
                        hideCompany: _trip.finishCompany,
                        hideAddress: _trip.finishAddress,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _actions(),
    );
  }

  bool _same(String a, String b) {
    final left = a.trim().toLowerCase();
    final right = b.trim().toLowerCase();
    return left.isNotEmpty && left == right;
  }

  bool get _showTripComment {
    if (_trip.comment.isEmpty) return false;
    return !_same(_trip.comment, _trip.startComment) &&
        !_same(_trip.comment, _trip.finishComment);
  }

  bool get _showSender =>
      _trip.sender.name.isNotEmpty || _trip.sender.phone.isNotEmpty;

  bool get _showRecipient =>
      _trip.recipient.name.isNotEmpty || _trip.recipient.phone.isNotEmpty;

  bool get _hasCargoBlock =>
      _trip.shipments.isNotEmpty ||
      _trip.cargo.isNotEmpty ||
      _trip.totalWeightKg != null ||
      _trip.totalVolumeM3 != null;

  DriverAuto? get _profileAuto => AppScope.maybeOf(context)?.auth.driver?.auto;

  /// Гос.номер как в списке заявок: с рейса, иначе из профиля.
  String get _plateNumber {
    if (_trip.vehicle.isNotEmpty) return _trip.vehicle;
    return _profileAuto?.stateNumber ?? '';
  }

  bool get _showAutoCard {
    if (_plateNumber.isNotEmpty) return true;
    final auto = _profileAuto;
    return auto != null && auto.hasContent;
  }

  bool get _cargoNameAddsInfo {
    if (_trip.cargo.isEmpty) return false;
    final names = _trip.shipments
        .map((item) => item.title)
        .where((item) => item.isNotEmpty)
        .join(', ');
    return names.isEmpty || !_same(_trip.cargo, names);
  }

  bool _shipmentRouteRepeatsTrip(Shipment item) {
    if (!item.hasRoute) return true;
    final fromKnown = item.from.isEmpty && item.fromAddress.isEmpty ||
        _same(item.from, _trip.from) ||
        _same(item.fromAddress, _trip.startAddress);
    final toKnown = item.to.isEmpty && item.toAddress.isEmpty ||
        _same(item.to, _trip.to) ||
        _same(item.toAddress, _trip.finishAddress);
    return fromKnown && toKnown;
  }

  bool _loadOpsOnStops(Shipment item) {
    return _trip.stops.any((stop) => stop.isLoad && (
          (item.loadQueue.isNotEmpty && _same(stop.queue, item.loadQueue)) ||
          (item.loadGate.number.isNotEmpty &&
              _same(stop.gate.number, item.loadGate.number))
        ));
  }

  bool _unloadOpsOnStops(Shipment item) {
    return _trip.stops.any((stop) => stop.isUnload && (
          (item.unloadQueue.isNotEmpty && _same(stop.queue, item.unloadQueue)) ||
          (item.unloadGate.number.isNotEmpty &&
              _same(stop.gate.number, item.unloadGate.number))
        ));
  }

  Widget _pinnedBar() {
    final hasDispatcher =
        _trip.dispatcherName.isNotEmpty || _trip.dispatcherPhone.isNotEmpty;
    final title = hasDispatcher && _trip.dispatcherName.isNotEmpty
        ? _trip.dispatcherName
        : (_trip.dateRange.isNotEmpty ? _trip.dateRange : 'Рейс');
    final subtitle = hasDispatcher
        ? 'Диспетчер'
        : (_trip.from.isNotEmpty || _trip.to.isNotEmpty
            ? '${_trip.from} → ${_trip.to}'
            : null);

    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        child: Row(
          children: [
            _statusWithTime(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (_trip.dispatcherPhone.isNotEmpty)
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Позвонить диспетчеру',
                  onPressed: () => _call(_trip.dispatcherPhone),
                  icon: const Icon(Icons.phone_outlined),
                  color: AppColors.navy,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusWithTime() {
    final changedAt = tripCurrentStatusChangedAt(_trip);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip(status: _trip.status, label: _trip.statusLabel),
        if (changedAt.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            changedAt,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ],
    );
  }

  Widget _statusHistoryCard() {
    final events = _trip.statusHistory
        .where((event) => event.at.isNotEmpty)
        .toList();
    if (events.isEmpty) return const SizedBox.shrink();
    return _card(
      title: 'История статусов',
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.schedule, size: 16, color: AppColors.navy),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        events[i].label.isNotEmpty
                            ? events[i].label
                            : (events[i].status.isNotEmpty
                                ? events[i].status
                                : 'Статус'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        events[i].at,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _autoCard() {
    final auto = _profileAuto;
    final plate = _plateNumber;
    return _card(
      title: 'Машина',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plate.isNotEmpty)
            GestureDetector(
              onTap: () => _copyText(plate, 'Гос. номер скопирован'),
              child: RuLicensePlateBadge(number: plate),
            ),
          if (auto != null &&
              [auto.brand, auto.model].any((part) => part.isNotEmpty)) ...[
            if (plate.isNotEmpty) const SizedBox(height: 10),
            Text(
              [auto.brand, auto.model].where((part) => part.isNotEmpty).join(' '),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
          if (auto != null &&
              (auto.bodyType.isNotEmpty ||
                  auto.color.isNotEmpty ||
                  auto.year.isNotEmpty)) ...[
            const SizedBox(height: 6),
            Text(
              [auto.bodyType, auto.color, auto.year]
                  .where((part) => part.isNotEmpty)
                  .join(' · '),
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _attorneyCard() {
    final number = _trip.resolvedAttorneyNumber;
    final date = _trip.resolvedAttorneyDate;
    final url = _trip.resolvedAttorneyUrl;
    return _card(
      title: 'Доверенность на водителя',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (number.isNotEmpty)
            Text(
              '№ $number',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('до $date', style: const TextStyle(color: AppColors.muted)),
          ],
          const SizedBox(height: 8),
          if (url.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Открыть файл'),
              ),
            ),
          TextButton.icon(
            onPressed: _showAttorney,
            icon: const Icon(Icons.notes_outlined, size: 18),
            label: Text(url.isNotEmpty ? 'Сводка' : 'Показать сводку'),
          ),
        ],
      ),
    );
  }

  void _showAttorney() {
    final driver = AppScope.maybeOf(context)?.auth.driver;
    final url = _trip.resolvedAttorneyUrl;
    final text = [
      'Доверенность на водителя',
      if (_trip.resolvedAttorneyNumber.isNotEmpty)
        'Номер: ${_trip.resolvedAttorneyNumber}',
      if (_trip.resolvedAttorneyDate.isNotEmpty)
        'Дата: ${_trip.resolvedAttorneyDate}',
      if (driver?.name.isNotEmpty ?? false) 'Водитель: ${driver!.name}',
      if (_plateNumber.isNotEmpty) 'ТС: $_plateNumber',
      if (_trip.cargoLabel.isNotEmpty) 'Груз: ${_trip.cargoLabel}',
      'Маршрут: ${_trip.from} → ${_trip.to}',
      if (_trip.dateStart.isNotEmpty) 'Погрузка: ${_trip.dateStart}',
      if (_trip.dateEnd.isNotEmpty) 'Выгрузка: ${_trip.dateEnd}',
    ].join('\n');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Доверенность',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 16, height: 1.45),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Скопировать'),
              ),
              if (url.isNotEmpty) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Скачать файл'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _cargoCard() {
    final leftoverWeight = _trip.totalWeightKg != null &&
        _trip.shipments.every((item) => item.weightKg == null);
    final leftoverVolume = _trip.totalVolumeM3 != null &&
        _trip.shipments.every((item) => item.volumeM3 == null);
    return _card(
      title: 'Груз',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_cargoNameAddsInfo)
            Text(
              _trip.cargo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          if (leftoverWeight || leftoverVolume) ...[
            if (_cargoNameAddsInfo) const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (leftoverWeight)
                  _metric(Icons.scale, formatKg(_trip.totalWeightKg)),
                if (leftoverVolume)
                  _metric(Icons.inventory_2_outlined, formatM3(_trip.totalVolumeM3)),
              ],
            ),
          ],
          for (var i = 0; i < _trip.shipments.length; i++) ...[
            if (i > 0 || _cargoNameAddsInfo || leftoverWeight || leftoverVolume)
              const Divider(height: 20),
            _shipmentRow(_trip.shipments[i]),
          ],
        ],
      ),
    );
  }

  Widget _card({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.navy),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _partyCard(
    String title,
    Party party, {
    String hideCompany = '',
    String hideAddress = '',
  }) {
    final company = _same(party.company, hideCompany) ? '' : party.company;
    final address = _same(party.address, hideAddress) ? '' : party.address;
    return _card(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (company.isNotEmpty) _infoLine('Компания', company),
          if (party.name.isNotEmpty) _infoLine('Контакт', party.name),
          if (party.phone.isNotEmpty) ...[
            _infoLine('Телефон', party.phone, onTap: () => _call(party.phone)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _call(party.phone),
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Позвонить'),
              ),
            ),
          ],
          if (address.isNotEmpty) _infoLine('Адрес', address),
          if (party.comment.isNotEmpty) _infoLine('Комментарий', party.comment),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onTap != null ? AppColors.ink : AppColors.navy,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shipmentRow(Shipment item) {
    final dates = [
      item.dateStart,
      if (item.dateEnd.isNotEmpty && item.dateEnd != item.dateStart) item.dateEnd,
    ].where((value) => value.isNotEmpty).join(' — ');
    final showRoute = !_shipmentRouteRepeatsTrip(item);
    final showConsignee = item.consignee.isNotEmpty &&
        !_same(item.consignee, _trip.recipient.name) &&
        !_same(item.consignee, _trip.recipient.company) &&
        !_same(item.consignee, _trip.finishCompany);
    final showLoadOps = (item.loadQueue.isNotEmpty || item.loadGate.hasContent) &&
        !_loadOpsOnStops(item);
    final showUnloadOps =
        (item.unloadQueue.isNotEmpty || item.unloadGate.hasContent) &&
            !_unloadOpsOnStops(item);
    final showLoadComment = item.loadComment.isNotEmpty &&
        !_same(item.loadComment, _trip.startComment);
    final showUnloadComment = item.unloadComment.isNotEmpty &&
        !_same(item.unloadComment, _trip.finishComment);
    final showDates = dates.isNotEmpty && !_same(dates, _trip.dateRange);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title.isNotEmpty ? item.title : 'Отгрузка',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (item.status.isNotEmpty)
              Text(item.status, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
        ),
        if (showRoute) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openPlace(
              address: item.fromAddress.isNotEmpty ? item.fromAddress : item.from,
              lat: item.fromLat,
              lng: item.fromLng,
            ),
            child: Text(
              [
                item.from,
                if (item.fromAddress.isNotEmpty && item.fromAddress != item.from)
                  item.fromAddress,
              ].where((value) => value.isNotEmpty).join(', '),
              style: const TextStyle(
                color: AppColors.ink,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          if (item.to.isNotEmpty || item.toAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _openPlace(
                address: item.toAddress.isNotEmpty ? item.toAddress : item.to,
                lat: item.toLat,
                lng: item.toLng,
              ),
              child: Text(
                [
                  item.to,
                  if (item.toAddress.isNotEmpty && item.toAddress != item.to)
                    item.toAddress,
                ].where((value) => value.isNotEmpty).join(', '),
                style: const TextStyle(
                  color: AppColors.ink,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
        if (showConsignee) ...[
          const SizedBox(height: 8),
          Text('Грузополучатель: ${item.consignee}'),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (item.weightKg != null) _metric(Icons.scale, formatKg(item.weightKg)),
            if (item.volumeM3 != null)
              _metric(Icons.inventory_2_outlined, formatM3(item.volumeM3)),
            if (item.units != null)
              _metric(Icons.inventory_2_outlined, formatUnits(item.units, item.measureUnit)),
            if (item.sizeLabel.isNotEmpty)
              _metric(Icons.straighten, item.sizeLabel),
          ],
        ),
        if (showLoadOps) ...[
          const SizedBox(height: 8),
          Text(
            [
              if (item.loadQueue.isNotEmpty) 'погрузка, очередь ${item.loadQueue}',
              if (item.loadGate.number.isNotEmpty) 'ворота ${item.loadGate.number}',
              if (item.loadGate.comment.isNotEmpty) item.loadGate.comment,
            ].join(' · '),
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
        if (showUnloadOps) ...[
          const SizedBox(height: 4),
          Text(
            [
              if (item.unloadQueue.isNotEmpty) 'выгрузка, очередь ${item.unloadQueue}',
              if (item.unloadGate.number.isNotEmpty) 'ворота ${item.unloadGate.number}',
              if (item.unloadGate.comment.isNotEmpty) item.unloadGate.comment,
            ].join(' · '),
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
        if (showLoadComment) ...[
          const SizedBox(height: 8),
          Text('Погрузка: ${item.loadComment}', style: const TextStyle(color: AppColors.muted)),
        ],
        if (showUnloadComment) ...[
          const SizedBox(height: 4),
          Text('Выгрузка: ${item.unloadComment}', style: const TextStyle(color: AppColors.muted)),
        ],
        if (showDates) ...[
          const SizedBox(height: 8),
          Text(dates, style: const TextStyle(color: AppColors.muted)),
        ],
        if (item.comment.isNotEmpty && !_same(item.comment, item.title)) ...[
          const SizedBox(height: 8),
          Text(item.comment, style: const TextStyle(color: AppColors.muted)),
        ],
      ],
    );
  }

  Future<void> _call(String phone) async {
    HapticFeedback.lightImpact();
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _actions() {
    final canAct = _trip.canStart || _trip.canDeliver;
    final primaryLabel = _trip.canStart
        ? 'В пути'
        : (_trip.canDeliver ? 'Доставлено' : '');
    final hint = _trip.nextActionHint;
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: canAct
                    ? ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () => _setStatus(
                                  _trip.canStart ? 'in_transit' : 'delivered',
                                ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(primaryLabel),
                      )
                    : Text(
                        hint,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              _iconAction(
                icon: Icons.navigation_outlined,
                tooltip: _trip.navigationLabel,
                onPressed: _openTripRoute,
              ),
              if (_trip.needsLocation)
                _iconAction(
                  icon: Icons.my_location,
                  tooltip: 'Отправить местоположение',
                  onPressed: _busy ? null : () => _sendLocation(),
                ),
              _iconAction(
                icon: Icons.photo_camera_outlined,
                tooltip: 'Прикрепить фото',
                onPressed: _busy ? null : _attachPhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      color: AppColors.navy,
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}
