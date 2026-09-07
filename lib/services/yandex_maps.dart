import 'package:url_launcher/url_launcher.dart';

Future<void> openYandexRoute({
  String? from,
  required String to,
}) async {
  final destination = to.trim();
  if (destination.isEmpty) return;

  final origin = from?.trim() ?? '';
  final rtext = origin.isEmpty
      ? '~${Uri.encodeComponent(destination)}'
      : '${Uri.encodeComponent(origin)}~${Uri.encodeComponent(destination)}';
  final web = Uri.parse(
    'https://yandex.ru/maps/?mode=routes&rtt=auto&rtext=$rtext',
  );
  final app = Uri.parse(
    'yandexmaps://maps.yandex.ru/?mode=routes&rtt=auto&rtext=$rtext',
  );

  if (await canLaunchUrl(app)) {
    await launchUrl(app, mode: LaunchMode.externalApplication);
    return;
  }
  await launchUrl(web, mode: LaunchMode.externalApplication);
}
