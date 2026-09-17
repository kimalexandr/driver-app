import 'package:url_launcher/url_launcher.dart';

import '../models/external_auth.dart';

/// Открытие Цифрового ID в мессенджере MAX.
///
/// Публичный API MAX не отдаёт QR ВУ/СТС сторонним приложениям — предъявление
/// документов остаётся в MAX. Здесь только быстрый переход по официальной ссылке.
class MaxDigitalIdService {
  Future<bool> openInMax() async {
    final uri = Uri.parse(OfficialAuthLinks.maxDigitalId);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    final guide = Uri.parse(OfficialAuthLinks.maxDigitalIdGuide);
    return launchUrl(guide, mode: LaunchMode.externalApplication);
  }

  Future<bool> openGuide() {
    return launchUrl(
      Uri.parse(OfficialAuthLinks.maxDigitalIdGuide),
      mode: LaunchMode.externalApplication,
    );
  }
}
