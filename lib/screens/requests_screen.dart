import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../models/trip.dart';
import '../services/yandex_maps.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import 'driver_profile_screen.dart';
import 'request_details_screen.dart';

class RequestsScreen extends StatefulWidget {
  final String? companyName;
  final DriverApi? api;

  const RequestsScreen({
    super.key,
    this.companyName,
    this.api,
  });

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<Trip> _trips = [];
  bool _loading = true;
  String? _error;

  DriverApi? get _api => widget.api ?? AppScope.maybeOf(context)?.api;

  List<Trip> get _active =>
      _trips.where((trip) => !trip.isCompleted).toList();

  List<Trip> get _completed =>
      _trips.where((trip) => trip.isCompleted).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = _api;
      if (api == null) {
        setState(() {
          _error = 'Нет подключения к API';
          _loading = false;
        });
        return;
      }
      final trips = await api.listTrips();
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : 'Не удалось загрузить рейсы';
        _loading = false;
      });
    }
  }

  Future<void> _openTrip(Trip trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailsScreen(
          trip: trip,
          api: widget.api,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.companyName ?? 'Рейсы'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverProfileScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Активные'),
              Tab(text: 'Завершённые'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off, size: 40, color: AppColors.muted),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    children: [
                      _list(_active, 'Нет назначенных рейсов'),
                      _list(_completed, 'Нет завершённых рейсов'),
                    ],
                  ),
      ),
    );
  }

  Widget _list(List<Trip> trips, String emptyText) {
    return RefreshIndicator(
      color: AppColors.navy,
      onRefresh: _load,
      child: trips.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 140),
                const Icon(Icons.route_outlined, size: 48, color: AppColors.muted),
                const SizedBox(height: 16),
                Center(child: Text(emptyText)),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openTrip(trip),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Рейс №${trip.number}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                StatusChip(
                                  status: trip.status,
                                  label: trip.statusLabel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => openYandexRoute(to: trip.destination),
                              child: Text(
                                '${trip.from} → ${trip.to}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    trip.dateStart,
                                    style: const TextStyle(color: AppColors.muted),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => openYandexRoute(to: trip.destination),
                                  icon: const Icon(Icons.navigation_outlined, size: 18),
                                  label: const Text('Маршрут'),
                                ),
                              ],
                            ),
                            if (trip.cargoLabel.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                trip.cargoLabel,
                                style: const TextStyle(color: AppColors.ink),
                              ),
                            ],
                            if (trip.totalWeightKg != null ||
                                trip.totalVolumeM3 != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                [
                                  if (trip.totalWeightKg != null)
                                    formatKg(trip.totalWeightKg),
                                  if (trip.totalVolumeM3 != null)
                                    formatM3(trip.totalVolumeM3),
                                ].join(' · '),
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
