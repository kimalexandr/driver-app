import 'package:url_launcher/url_launcher.dart';

import '../models/external_auth.dart';
import 'secure_kv.dart';

/// Локальная связка с Цифровым ID MAX.
///
/// Публичный API MAX не отдаёт QR ВУ/СТС сторонним приложениям — предъявление
/// документов остаётся в мессенджере. Здесь храним только отметку водителя
/// и открываем MAX по официальной ссылке.
class MaxDigitalIdService {
  static const _keyPrefix = 'max.digital_id.linked.';

  final SecureKv _kv;

  MaxDigitalIdService({SecureKv? kv}) : _kv = kv ?? FlutterSecureKv();

  Future<bool> isLinked(String owner) async {
    final value = await _kv.read('$_keyPrefix$owner');
    return value == '1';
  }

  Future<void> setLinked(String owner, bool linked) async {
    final key = '$_keyPrefix$owner';
    if (linked) {
      await _kv.write(key, '1');
    } else {
      await _kv.delete(key);
    }
  }

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
