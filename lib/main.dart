import 'package:flutter/material.dart';

import 'api/api_exception.dart';
import 'models/trip.dart';
import 'screens/phone_input_screen.dart';
import 'screens/request_details_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/verification_screen.dart';
import 'state/app_scope.dart';
import 'state/auth_controller.dart';
import 'theme/app_theme.dart';

final appDependencies = AppDependencies();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DriverApp(dependencies: appDependencies));
}

class DriverApp extends StatefulWidget {
  final AppDependencies dependencies;

  const DriverApp({super.key, required this.dependencies});

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _ready = false;
  bool _wasLoggedIn = false;
  String? _pendingTripId;

  AuthController get _auth => widget.dependencies.auth;

  @override
  void initState() {
    super.initState();
    widget.dependencies.push.onOpenTrip = _onOpenTripFromPush;
    _auth.addListener(_onAuth);
    _boot();
  }

  Future<void> _boot() async {
    await _auth.restore();
    if (!mounted) return;
    _wasLoggedIn = _auth.isLoggedIn;
    setState(() => _ready = true);
    _syncTracker();
    _flushPendingTrip();
  }

  void _onOpenTripFromPush(String tripId) {
    _pendingTripId = tripId;
    _flushPendingTrip();
  }

  void _flushPendingTrip() {
    if (!_ready || !_auth.isLoggedIn) return;
    final tripId = _pendingTripId;
    if (tripId == null || tripId.isEmpty) return;
    _pendingTripId = null;
    // ignore: discarded_futures
    _openTripById(tripId);
  }

  Future<void> _openTripById(String tripId) async {
    final nav = _navigatorKey.currentState;
    if (nav == null) return;
    try {
      final trip = await widget.dependencies.api.getTrip(tripId);
      nav.push(
        MaterialPageRoute(
          builder: (context) => RequestDetailsScreen(trip: trip),
        ),
      );
    } on ApiException {
      nav.push(
        MaterialPageRoute(
          builder: (context) => RequestDetailsScreen(
            trip: Trip(
              id: tripId,
              number: tripId,
              status: 'assigned',
              statusLabel: 'Рейс',
              from: '',
              to: '',
              dateStart: '',
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  void _onAuth() {
    if (!_ready || !mounted) return;
    if (_wasLoggedIn && !_auth.isLoggedIn) {
      widget.dependencies.locationTracker.stop();
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/phone',
        (route) => false,
      );
    }
    _wasLoggedIn = _auth.isLoggedIn;
    _syncTracker();
    if (_auth.isLoggedIn) {
      _flushPendingTrip();
    }
  }

  void _syncTracker() {
    if (_auth.isLoggedIn) {
      widget.dependencies.locationTracker.start();
      final owner = (_auth.driver?.id ?? '').trim();
      if (owner.isNotEmpty) {
        // ignore: discarded_futures
        widget.dependencies.push.sync(
          api: widget.dependencies.api,
          owner: owner,
        );
      }
    } else {
      widget.dependencies.locationTracker.stop();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    widget.dependencies.locationTracker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: widget.dependencies.api,
      tokenStore: widget.dependencies.tokenStore,
      locationService: widget.dependencies.locationService,
      locationTracker: widget.dependencies.locationTracker,
      pep: widget.dependencies.pep,
      push: widget.dependencies.push,
      auth: _auth,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: '7Rights Driver',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        // Светлая по умолчанию: тёмный текст всегда читаем на дороге.
        // Системная тёмная тема тоже поддерживается с высоким контрастом.
        themeMode: ThemeMode.light,
        home: !_ready
            ? const Scaffold(
                backgroundColor: AppColors.sand,
                body: Center(child: CircularProgressIndicator()),
              )
            : (_auth.isLoggedIn
                ? const RequestsScreen()
                : const PhoneInputScreen()),
        routes: {
          '/phone': (context) => const PhoneInputScreen(),
          '/verify': (context) => const VerificationScreen(),
          '/trips': (context) => const RequestsScreen(),
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DriverApp(dependencies: appDependencies);
  }
}
