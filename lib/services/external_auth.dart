import 'package:url_launcher/url_launcher.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../models/auth_session.dart';
import '../models/external_auth.dart';

class ExternalAuthOutcome {
  final AuthSession? session;
  final bool openedExternal;
  final String? message;

  const ExternalAuthOutcome({
    this.session,
    this.openedExternal = false,
    this.message,
  });
}

class ExternalAuthService {
  final DriverApi api;

  const ExternalAuthService(this.api);

  Future<ExternalAuthOutcome> authenticate(AuthProviderKind provider) async {
    if (provider == AuthProviderKind.sms) {
      throw const ApiException('Для входа по телефону введите номер');
    }
    final start = await api.startExternalAuth(provider);
    if (start.demo) {
      final session = await api.completeExternalAuth(
        provider: provider.id,
        code: start.demoCode ?? 'demo',
        state: start.state,
      );
      return ExternalAuthOutcome(session: session);
    }

    final url = (start.authorizeUrl == null || start.authorizeUrl!.isEmpty)
        ? (provider == AuthProviderKind.goskey
            ? OfficialAuthLinks.goskey
            : OfficialAuthLinks.gosuslugi)
        : start.authorizeUrl!;
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw ApiException('Не удалось открыть ${provider.title}');
    }
    return ExternalAuthOutcome(
      openedExternal: true,
      message: provider == AuthProviderKind.goskey
          ? 'Откройте Госключ и подтвердите вход. Когда TMS подключит оператора, вход завершится автоматически.'
          : 'Откройте Госуслуги и подтвердите вход. Когда TMS подключит ЕСИА, вход завершится автоматически.',
    );
  }
}
