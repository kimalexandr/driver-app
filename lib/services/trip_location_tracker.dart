import 'dart:async';

import '../api/driver_api.dart';
import 'location_service.dart';

class TripLocationTracker {
  static const interval = Duration(minutes: 5);

  final DriverApi api;
  final LocationService location;

  Timer? _timer;
  bool _busy = false;

  TripLocationTracker({
    required this.api,
    required this.location,
  });

  void start() {
    stop();
    unawaited(sendNow());
    _timer = Timer.periodic(interval, (_) => sendNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> sendNow() async {
    if (_busy) return;
    _busy = true;
    try {
      final trips = await api.listTrips();
      final active = trips.where((trip) => trip.needsLocation).toList();
      if (active.isEmpty) return;
      final point = await location.current();
      if (point == null) return;
      for (final trip in active) {
        await api.sendLocation(tripId: trip.id, lat: point.lat, lng: point.lng);
      }
    } catch (_) {
      // сеть или отказ геолокации — следующая попытка через 5 минут
    } finally {
      _busy = false;
    }
  }
}
