import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../models/trip.dart';
import '../services/location_service.dart';
import '../services/yandex_maps.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/ru_license_plate.dart';
import '../widgets/status_chip.dart';

class RequestDetailsScreen extends StatefulWidget {
  final Trip trip;
  final DriverApi? api;

  const RequestDetailsScreen({
    super.key,
    required this.trip,
    this.api,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  late Trip _trip;
  bool _busy = false;

  DriverApi? get _api => widget.api ?? AppScope.maybeOf(context)?.api;

  LocationService get _location =>
      AppScope.maybeOf(context)?.locationService ?? LocationService();

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  void _showOk(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.green),
    );
  }

  Future<void> _setStatus(String status) async {
    if (_busy) return;
    final api = _api;
    if (api == null) return;
    setState(() => _busy = true);
    try {
      final trip = await api.updateTripStatus(tripId: _trip.id, status: status);
      if (!mounted) return;
      setState(() => _trip = trip.orFallback(_trip));
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPlace({
    required String address,
    double? lat,
    double? lng,
  }) async {
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
    final opened = await openYandexRoute(
      from: _trip.startAddress.isNotEmpty ? _trip.startAddress : _trip.from,
      to: _trip.finishAddress.isNotEmpty ? _trip.finishAddress : _trip.to,
      fromLat: _trip.startLat,
      fromLng: _trip.startLng,
      toLat: _trip.finishLat,
      toLng: _trip.finishLng,
    );
    if (!opened && mounted) {
      _showError('Нет адреса или координат для маршрута');
    }
  }

  Future<void> _sendLocation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final point = await _location.current();
      if (point == null) {
        if (!mounted) return;
        _showError('Не удалось получить геолокацию. Проверьте разрешение.');
        return;
      }
      final api = _api;
      if (api == null) return;
      await api.sendLocation(tripId: _trip.id, lat: point.lat, lng: point.lng);
      if (!mounted) return;
      _showOk('Местоположение отправлено');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attachPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final api = _api;
      if (api == null) return;
      await api.uploadFile(tripId: _trip.id, filePath: file.path);
      if (!mounted) return;
      _showOk('Фото прикреплено');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Рейс №${_trip.number}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(status: _trip.status, label: _trip.statusLabel),
                const Spacer(),
                if (_trip.dateRange.isNotEmpty)
                  Text(
                    _trip.dateRange,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _autoCard(),
            _taskCard(),
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
              _partyCard('Отправитель', _trip.sender, hideCompany: _trip.startCompany, hideAddress: _trip.startAddress),
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

  Widget _autoCard() {
    final auto = AppScope.maybeOf(context)?.auth.driver?.auto;
    if (auto == null || !auto.hasContent) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _card(
        title: 'Машина',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (auto.stateNumber.isNotEmpty)
              RuLicensePlateBadge(number: auto.stateNumber),
            if ([auto.brand, auto.model].any((part) => part.isNotEmpty)) ...[
              if (auto.stateNumber.isNotEmpty) const SizedBox(height: 10),
              Text(
                [auto.brand, auto.model].where((part) => part.isNotEmpty).join(' '),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
            if (auto.bodyType.isNotEmpty || auto.color.isNotEmpty) ...[
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
      ),
    );
  }

  Widget _taskCard() {
    return _card(
      title: 'Задача',
      child: _trip.stops.isNotEmpty ? _stopsTimeline() : _routeTimeline(),
    );
  }

  Widget _routeTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _point(
          icon: Icons.trip_origin,
          title: 'Погрузка',
          city: _trip.from,
          company: _trip.startCompany,
          address: _trip.startAddress,
          comment: _trip.startComment,
          onTap: () => _openPlace(
            address: _trip.startAddress.isNotEmpty ? _trip.startAddress : _trip.from,
            lat: _trip.startLat,
            lng: _trip.startLng,
          ),
        ),
        _routeLine(),
        _point(
          icon: Icons.flag_outlined,
          title: 'Выгрузка',
          city: _trip.to,
          company: _trip.finishCompany,
          address: _trip.finishAddress,
          comment: _trip.finishComment,
          onTap: () => _openPlace(
            address: _trip.finishAddress.isNotEmpty ? _trip.finishAddress : _trip.to,
            lat: _trip.finishLat,
            lng: _trip.finishLng,
          ),
        ),
      ],
    );
  }

  Widget _stopsTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _trip.stops.length; i++) ...[
          if (i > 0) _routeLine(),
          _stopRow(_trip.stops[i]),
        ],
      ],
    );
  }

  Widget _routeLine() {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      height: 18,
      width: 2,
      color: AppColors.line,
    );
  }

  Widget _stopRow(TripStop stop) {
    final kind = stop.isLoad ? 'Погрузка' : (stop.isUnload ? 'Выгрузка' : stop.type);
    final company = stop.isLoad
        ? _trip.startCompany
        : (stop.isUnload ? _trip.finishCompany : '');
    final comment = stop.comment.isNotEmpty
        ? stop.comment
        : (stop.isLoad
            ? _trip.startComment
            : (stop.isUnload ? _trip.finishComment : ''));
    final showCargo = stop.cargoName.isNotEmpty &&
        !_same(stop.cargoName, _trip.cargo) &&
        !_trip.shipments.any((item) => _same(item.title, stop.cargoName));
    return _point(
      icon: stop.isUnload ? Icons.flag_outlined : Icons.trip_origin,
      title: kind,
      city: stop.title.isNotEmpty ? stop.title : _cityFromStop(stop),
      company: company,
      address: stop.address.isNotEmpty && !_same(stop.address, stop.title)
          ? stop.address
          : '',
      comment: [
        if (stop.queue.isNotEmpty) 'очередь ${stop.queue}',
        if (stop.gate.number.isNotEmpty) 'ворота ${stop.gate.number}',
        if (stop.gate.comment.isNotEmpty) stop.gate.comment,
        if (showCargo) stop.cargoName,
        if (comment.isNotEmpty) comment,
      ].join(' · '),
      onTap: () => _openPlace(
        address: stop.address.isNotEmpty ? stop.address : stop.title,
        lat: stop.lat,
        lng: stop.lng,
      ),
    );
  }

  String _cityFromStop(TripStop stop) {
    if (stop.isLoad && _trip.from.isNotEmpty) return _trip.from;
    if (stop.isUnload && _trip.to.isNotEmpty) return _trip.to;
    return stop.address;
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

  Widget _point({
    required IconData icon,
    required String title,
    required String city,
    required String address,
    String company = '',
    String comment = '',
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  city.isNotEmpty ? city : 'Адрес не указан',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    decoration: TextDecoration.underline,
                  ),
                ),
                if (company.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(company, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.ink,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(comment, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ],
            ),
          ),
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
          if (party.phone.isNotEmpty)
            _infoLine('Телефон', party.phone, onTap: () => _call(party.phone)),
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
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _actions() {
    return Material(
      color: Colors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            if (_trip.canStart) ...[
              ElevatedButton(
                onPressed: _busy ? null : () => _setStatus('in_transit'),
                child: const Text('В пути'),
              ),
              const SizedBox(height: 10),
            ],
            if (_trip.canDeliver) ...[
              ElevatedButton(
                onPressed: _busy ? null : () => _setStatus('delivered'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                child: const Text('Доставлено'),
              ),
              const SizedBox(height: 10),
            ],
            if (_trip.canDeliver) ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : _sendLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Отправить местоположение'),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _openTripRoute,
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Маршрут'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _attachPhoto,
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Прикрепить фото'),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
