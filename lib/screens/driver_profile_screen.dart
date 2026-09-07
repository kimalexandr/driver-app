import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/driver_profile.dart';
import '../state/app_scope.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  DriverProfile? _driver;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final scope = AppScope.maybeOf(context);
    if (scope == null) {
      setState(() {
        _driver = const DriverProfile(id: '', name: '', phone: '');
        _loading = false;
      });
      return;
    }
    try {
      final driver = await scope.api.me();
      if (!mounted) return;
      setState(() {
        _driver = driver;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _driver = scope.auth.driver;
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final scope = AppScope.maybeOf(context);
    await scope?.auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/phone', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final driver = _driver ?? AppScope.maybeOf(context)?.auth.driver;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    _card('ФИО', driver?.name ?? '—'),
                    _card('Телефон', driver?.phone ?? '—'),
                    const Spacer(),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Выйти'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(180, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _card(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        subtitle: Text(
          content,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
    );
  }
}
