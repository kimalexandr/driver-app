import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/external_auth.dart';
import '../services/external_auth.dart';
import '../services/phone.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/ru_phone_field.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final phone = normalizePhone(_phoneController.text);
      final challenge = await AppScope.of(context).api.requestCode(phone);
      if (!mounted) return;
      Navigator.pushNamed(context, '/verify', arguments: challenge);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _external(AuthProviderKind provider) async {
    setState(() => _loading = true);
    try {
      final scope = AppScope.of(context);
      final outcome = await ExternalAuthService(scope.api).authenticate(provider);
      if (outcome.session != null) {
        await scope.pep.linkProvider(provider);
        await scope.auth.applySession(outcome.session!);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/trips', (route) => false);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(outcome.message ?? 'Откройте ${provider.title}')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  '7Rights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Вход водителя',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Введите номер телефона, указанный в TMS',
                  style: TextStyle(fontSize: 16, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 32),
                RuPhoneField(
                  controller: _phoneController,
                  validator: (value) {
                    final phone = normalizePhone(value ?? '');
                    if (phone.length != 11 || !phone.startsWith('7')) {
                      return 'Введите номер полностью: +7 (999) 123-45-67';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? 'Отправка...' : 'Получить код'),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.line)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'или войти через',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.line)),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _external(AuthProviderKind.gosuslugi),
                  icon: const Icon(Icons.account_balance_outlined),
                  label: const Text('Госуслуги'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _external(AuthProviderKind.goskey),
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('Госключ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
