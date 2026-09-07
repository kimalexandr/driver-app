Map<String, dynamic> unwrapJson(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return json;
}

List<Map<String, dynamic>> jsonMaps(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
  }
  return const [];
}

String jsonText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is Map) {
      final nested = jsonText(Map<String, dynamic>.from(value), const [
        'full_address',
        'address',
        'formatted',
        'full_name',
        'name',
        'title',
        'city',
        'value',
        'text',
        'label',
        'number',
        'cargo',
        'product',
      ]);
      if (nested.isNotEmpty) return nested;
      continue;
    }
    if (value is List) {
      final text = value
          .where((item) => item != null && item is! Map)
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty && item != 'null')
          .join(', ');
      if (text.isNotEmpty) return text;
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

num? jsonNumber(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
      if (parsed != null) return parsed;
    }
    if (value is Map) {
      final nested = jsonNumber(Map<String, dynamic>.from(value), const [
        'value',
        'amount',
        'kg',
        'm3',
        'weight',
        'volume',
      ]);
      if (nested != null) return nested;
    }
  }
  return null;
}

Map<String, dynamic>? jsonMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return null;
}
