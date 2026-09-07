import 'package:url_launcher/url_launcher.dart';

Future<bool> openYandexRoute({
  String? from,
  String? to,
  double? toLat,
  double? toLng,
}) async {
  final destination = _destination(to: to, lat: toLat, lng: toLng);
  if (destination.isEmpty) return false;

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

  if (await _open(app)) return true;
  return _open(web);
}

String _destination({String? to, double? lat, double? lng}) {
  if (lat != null && lng != null) return '$lat,$lng';
  return to?.trim() ?? '';
}

Future<bool> _open(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
