import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/driver_profile.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';

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
      final loaded = await scope.api.me();
      final previous = scope.auth.driver;
      final driver = loaded.phone.isEmpty && (previous?.phone.isNotEmpty ?? false)
          ? loaded.copyWith(phone: previous!.phone)
          : loaded;
      scope.auth.applyProfile(driver);
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'В';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final driver = _driver ?? AppScope.maybeOf(context)?.auth.driver;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.navy,
                    child: Text(
                      _initials(driver?.name ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                  ),
                _card('ФИО', driver?.name),
                _card('Телефон', driver?.phone),
                _card('Перевозчик', driver?.carrierName),
                _card('ТС', driver?.vehicle),
                _card('ВУ, серия и номер', driver?.licenseNumber),
                _card('Категории ВУ', driver?.licenseCategories),
                _card('Дата выдачи ВУ', driver?.licenseIssuedAt),
                _card('Паспорт', driver?.passportNumber),
                _card('ИНН', driver?.inn),
                _card('Комментарий', driver?.comment),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Выйти'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card(String title, String? content) {
    if (content == null || content.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
