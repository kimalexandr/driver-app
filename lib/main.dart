import 'package:flutter/material.dart';

import 'screens/phone_input_screen.dart';
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

  AuthController get _auth => widget.dependencies.auth;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuth);
    _boot();
  }

  Future<void> _boot() async {
    await _auth.restore();
    if (!mounted) return;
    _wasLoggedIn = _auth.isLoggedIn;
    setState(() => _ready = true);
  }

  void _onAuth() {
    if (!_ready || !mounted) return;
    if (_wasLoggedIn && !_auth.isLoggedIn) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/phone',
        (route) => false,
      );
    }
    _wasLoggedIn = _auth.isLoggedIn;
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: widget.dependencies.api,
      tokenStore: widget.dependencies.tokenStore,
      locationService: widget.dependencies.locationService,
      auth: _auth,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: '7Rights Driver',
        theme: AppTheme.light(),
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
