import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../models/trip.dart';
import '../services/yandex_maps.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/trip_deadline_banner.dart';
import '../widgets/trip_list_skeleton.dart';
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
  String _completedQuery = '';
  DateTime? _lastUpdated;
  final TextEditingController _completedSearch = TextEditingController();

  DriverApi? get _api => widget.api ?? AppScope.maybeOf(context)?.api;

  List<Trip> get _active =>
      _trips.where((trip) => !trip.isCompleted).toList();

  List<Trip> get _completed =>
      _trips.where((trip) => trip.isCompleted).toList();

  List<Trip> get _completedVisible => _completed
      .where((trip) => tripMatchesQuery(trip, _completedQuery))
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _completedSearch.dispose();
    super.dispose();
  }

  void _setCompletedQuery(String value) {
    setState(() => _completedQuery = value);
  }

  void _clearCompletedSearch() {
    _completedSearch.clear();
    _setCompletedQuery('');
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
        _lastUpdated = DateTime.now();
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

  Future<void> _openRoute(Trip trip) async {
    HapticFeedback.lightImpact();
    final opened = await openYandexNavigateTo(
      address: trip.destination,
      lat: trip.destinationLat,
      lng: trip.destinationLng,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет адреса или координат для навигации'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _callDispatcher(Trip trip) async {
    HapticFeedback.lightImpact();
    final phone = trip.dispatcherPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatUpdated(DateTime at) {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.companyName ?? 'Рейсы'),
              if (_lastUpdated != null && !_loading)
                Text(
                  'Обновлено ${_formatUpdated(_lastUpdated!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Профиль',
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
        body: _loading && _trips.isEmpty
            ? const TripListSkeleton()
            : _error != null && _trips.isEmpty
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
                      _list(
                        _active,
                        'Пока нет рейсов',
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: TextField(
                              controller: _completedSearch,
                              onChanged: _setCompletedQuery,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Номер, дата или точка',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _completedQuery.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Сбросить поиск',
                                        onPressed: _clearCompletedSearch,
                                        icon: const Icon(Icons.close),
                                      ),
                              ),
                            ),
                          ),
                          if (_completedQuery.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Найдено: ${_completedVisible.length}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: _list(
                              _completedVisible,
                              _completedQuery.trim().isEmpty
                                  ? 'Нет завершённых рейсов'
                                  : 'Нет рейсов по запросу',
                            ),
                          ),
                        ],
                      ),
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
                const SizedBox(height: 120),
                Icon(
                  emptyText == 'Пока нет рейсов'
                      ? Icons.notifications_active_outlined
                      : Icons.route_outlined,
                  size: 48,
                  color: AppColors.muted,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (emptyText == 'Пока нет рейсов') ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      'Когда диспетчер назначит рейс — придёт уведомление.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DriverProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_outlined),
                      label: const Text('Проверить уведомления'),
                    ),
                  ),
                ],
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                final statusAt = tripCurrentStatusChangedAt(trip);
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
                                if (statusAt.isNotEmpty)
                                  Text(
                                    statusAt,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.muted,
                                    ),
                                  )
                                else if (trip.statusLabel.isNotEmpty)
                                  Text(
                                    trip.statusLabel,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.muted,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${trip.from.isNotEmpty ? trip.from : trip.startAddress} → ${trip.to.isNotEmpty ? trip.to : trip.finishAddress}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trip.dateRange,
                                        style: const TextStyle(color: AppColors.muted),
                                      ),
                                      TripDeadlineBanner(trip: trip, compact: true),
                                    ],
                                  ),
                                ),
                                if (trip.dispatcherPhone.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Позвонить диспетчеру',
                                    onPressed: () => _callDispatcher(trip),
                                    icon: const Icon(Icons.phone_outlined, size: 24),
                                    color: AppColors.navy,
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                    ),
                                  ),
                                IconButton(
                                  tooltip: trip.navigationLabel,
                                  onPressed: () => _openRoute(trip),
                                  icon: const Icon(Icons.navigation_outlined, size: 24),
                                  color: AppColors.navy,
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                  ),
                                ),
                              ],
                            ),
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
