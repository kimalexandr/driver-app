import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../models/trip.dart';
import '../services/location_service.dart';
import '../state/app_scope.dart';

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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showOk(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Рейс №${_trip.number}')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Статус', _trip.statusLabel),
              _row('Откуда', _trip.from),
              _row('Куда', _trip.to),
              _row('Дата', _trip.dateStart),
              if (_trip.vehicle.isNotEmpty) _row('ТС', _trip.vehicle),
              if (_trip.startAddress.isNotEmpty)
                _row('Адрес погрузки', _trip.startAddress),
              if (_trip.finishAddress.isNotEmpty)
                _row('Адрес выгрузки', _trip.finishAddress),
              if (_trip.shipments.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Грузы',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._trip.shipments.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(item.title),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_trip.canStart)
                ElevatedButton(
                  onPressed: _busy ? null : () => _setStatus('in_transit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('В пути'),
                ),
              if (_trip.canDeliver) ...[
                ElevatedButton(
                  onPressed: _busy ? null : () => _setStatus('delivered'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Доставлено'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _sendLocation,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Отправить местоположение'),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _attachPhoto,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Прикрепить фото'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
