import 'package:url_launcher/url_launcher.dart';

String yandexPlaceUrl(String query) {
  return 'https://yandex.ru/maps/?text=${Uri.encodeQueryComponent(query.trim())}';
}

String yandexRouteUrl({required String from, required String to}) {
  return 'https://yandex.ru/maps/?rtext=${_rtext(from)}~${_rtext(to)}&rtt=auto';
}

Future<bool> openYandexPlace({
  String? address,
  double? lat,
  double? lng,
}) async {
  final query = _point(lat: lat, lng: lng, address: address, preferAddress: true);
  if (query.isEmpty) return false;
  return _openPair(
    app: 'yandexmaps://maps.yandex.ru/?text=${Uri.encodeQueryComponent(query)}',
    web: yandexPlaceUrl(query),
  );
}

Future<bool> openYandexRoute({
  String? from,
  String? to,
  double? fromLat,
  double? fromLng,
  double? toLat,
  double? toLng,
}) async {
  final start = _point(lat: fromLat, lng: fromLng, address: from);
  final end = _point(lat: toLat, lng: toLng, address: to);
  if (start.isEmpty && end.isEmpty) return false;
  if (start.isEmpty || end.isEmpty) {
    return openYandexPlace(address: start.isEmpty ? end : start);
  }
  return _openPair(
    app: 'yandexmaps://maps.yandex.ru/?rtext=${_rtext(start)}~${_rtext(end)}&rtt=auto',
    web: yandexRouteUrl(from: start, to: end),
  );
}

String _point({
  double? lat,
  double? lng,
  String? address,
  bool preferAddress = false,
}) {
  final text = address?.trim() ?? '';
  if (preferAddress && text.isNotEmpty) return text;
  if (lat != null && lng != null) return '$lat,$lng';
  return text;
}

String _rtext(String value) {
  if (_isLatLng(value)) return value;
  return Uri.encodeQueryComponent(value);
}

bool _isLatLng(String value) {
  return RegExp(r'^-?\d+(?:\.\d+)?,-?\d+(?:\.\d+)?$').hasMatch(value);
}

Future<bool> _openPair({required String app, required String web}) async {
  if (await _open(app)) return true;
  return _open(web);
}

Future<bool> _open(String url) async {
  try {
    return await launchUrlString(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
