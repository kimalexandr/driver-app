import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../models/trip.dart';
import '../services/location_service.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
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
      setState(() => _trip = trip);
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
      setState(() => _trip = trip);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusChip(status: _trip.status, label: _trip.statusLabel),
                      const Spacer(),
                      if (_trip.vehicle.isNotEmpty)
                        Text(
                          _trip.vehicle,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _routeCard(),
                  if (_trip.shipments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _card(
                      title: 'Грузы',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _trip.shipments
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _actions(),
        ],
      ),
    );
  }

  Widget _routeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _point(
            icon: Icons.trip_origin,
            title: 'Откуда',
            city: _trip.from,
            address: _trip.startAddress,
          ),
          Container(
            margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
            height: 18,
            width: 2,
            color: AppColors.line,
          ),
          _point(
            icon: Icons.flag_outlined,
            title: 'Куда',
            city: _trip.to,
            address: _trip.finishAddress,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                _trip.dateStart,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _point({
    required IconData icon,
    required String title,
    required String city,
    required String address,
  }) {
    return Row(
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
                city,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(address, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
              ],
            ],
          ),
        ),
      ],
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

  Widget _actions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_trip.canStart)
              ElevatedButton(
                onPressed: _busy ? null : () => _setStatus('in_transit'),
                child: const Text('В пути'),
              ),
            if (_trip.canDeliver)
              ElevatedButton(
                onPressed: _busy ? null : () => _setStatus('delivered'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                child: const Text('Доставлено'),
              ),
            if (_trip.canDeliver) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _sendLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Отправить местоположение'),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _attachPhoto,
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Прикрепить фото'),
            ),
          ],
        ),
      ),
    );
  }
}
