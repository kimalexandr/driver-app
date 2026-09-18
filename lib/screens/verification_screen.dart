import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_exception.dart';
import '../api/service_login.dart';
import '../models/auth_session.dart';
import '../models/external_auth.dart';
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
  bool _resending = false;
  CodeRequest? _challenge;
  Timer? _resendTimer;
  int _resendIn = 45;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is CodeRequest) {
        setState(() => _challenge = args);
      }
      _focusNodes.first.requestFocus();
      _startResendTimer();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer([int seconds = 45]) {
    _resendTimer?.cancel();
    setState(() => _resendIn = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
        return;
      }
      setState(() => _resendIn -= 1);
    });
  }

  Future<void> _resend() async {
    final phone = _challenge?.phone;
    if (phone == null || _resendIn > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      final challenge = await AppScope.of(context).api.requestCode(phone);
      if (!mounted) return;
      setState(() => _challenge = challenge);
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Код отправлен повторно'),
          backgroundColor: AppColors.navy,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _applyDigits(String raw, {int startIndex = 0}) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    for (var i = 0; i < digits.length && startIndex + i < 4; i++) {
      _controllers[startIndex + i].text = digits[i];
    }
    final filled = _controllers.map((c) => c.text).join();
    if (filled.length >= 4) {
      _focusNodes[3].unfocus();
      _verify();
      return;
    }
    final next = (startIndex + digits.length).clamp(0, 3);
    _focusNodes[next].requestFocus();
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
        code: ServiceLogin.resolve(
          entered: code,
          debugCode: challenge.debugCode,
        ),
      );
      await scope.pep.linkProvider(AuthProviderKind.sms);
      await scope.auth.applySession(session);
      final driverId = session.driver.id.trim();
      String? pushStatus;
      if (driverId.isNotEmpty) {
        try {
          await scope.push.sync(api: scope.api, owner: driverId);
        } catch (_) {}
        pushStatus = scope.push.lastStatus;
      } else {
        pushStatus = 'Нет id водителя — push не зарегистрирован';
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/trips', (route) => false);
      if (pushStatus != null && pushStatus.isNotEmpty) {
        final ok = pushStatus.contains('подключён') ||
            pushStatus.contains('на сервере');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pushStatus),
            backgroundColor: ok ? AppColors.navy : AppColors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
    const showDebugHints = kDebugMode;
    final mm = (_resendIn ~/ 60).toString();
    final ss = (_resendIn % 60).toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                showDebugHints
                    ? 'Введите 4-значный код из SMS или служебный код'
                    : 'Введите 4-значный код из SMS',
                style: TextStyle(fontSize: 16, color: AppColors.muted),
              ),
              if (showDebugHints) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.softTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    debugCode != null &&
                            debugCode.isNotEmpty &&
                            debugCode != ServiceLogin.code
                        ? 'Служебный код: ${ServiceLogin.code}  ·  код сервера: $debugCode'
                        : 'Служебный код: ${ServiceLogin.code}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0F766E),
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
                      autofocus: index == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: index == 3
                          ? TextInputAction.done
                          : TextInputAction.next,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (value) {
                        if (value.length > 1) {
                          _controllers[index].text = '';
                          _applyDigits(value, startIndex: index);
                          return;
                        }
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
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_resendIn > 0 || _resending || _loading)
                    ? null
                    : _resend,
                child: Text(
                  _resendIn > 0
                      ? 'Отправить снова через $mm:$ss'
                      : (_resending ? 'Отправка...' : 'Отправить код снова'),
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
