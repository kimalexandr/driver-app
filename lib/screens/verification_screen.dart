import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_exception.dart';
import '../models/auth_session.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  CodeRequest? get _challenge {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is CodeRequest ? args : null;
  }

  Future<void> _verify() async {
    final code = _controllers.map((controller) => controller.text).join();
    final challenge = _challenge;
    if (challenge == null || code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите 4-значный код'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final scope = AppScope.of(context);
      final session = await scope.api.verifyCode(
        phone: challenge.phone,
        code: code,
      );
      await scope.auth.applySession(session);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/trips', (route) => false);
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
    final debugCode = _challenge?.debugCode;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.sand,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Код из SMS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Введите 4-значный код',
                style: TextStyle(fontSize: 16, color: AppColors.muted),
              ),
              if (debugCode != null && debugCode.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8D2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Код для отладки: $debugCode',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                  (index) => SizedBox(
                    width: 68,
                    height: 72,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !_loading,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (index == 3 && value.isNotEmpty) {
                          _verify();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: Text(_loading ? 'Вход...' : 'Войти'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
