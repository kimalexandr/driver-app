import 'json_fields.dart';

class DriverLicense {
  final String number;
  final String issueDate;
  final String issuedBy;
  final String issueCity;
  final List<String> categories;

  const DriverLicense({
    this.number = '',
    this.issueDate = '',
    this.issuedBy = '',
    this.issueCity = '',
    this.categories = const [],
  });

  bool get hasContent =>
      number.isNotEmpty ||
      issueDate.isNotEmpty ||
      issuedBy.isNotEmpty ||
      issueCity.isNotEmpty ||
      categories.isNotEmpty;

  String get displayNumber => formatRuLicenseNumber(number);

  List<String> get openCategories {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in categories) {
      final code = raw.trim().toUpperCase();
      if (code.isEmpty || !seen.add(code)) continue;
      result.add(code);
    }
    return result;
  }

  factory DriverLicense.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DriverLicense();
    return DriverLicense(
      number: jsonText(json, ['number']),
      issueDate: formatDay(json['issue_date'] ?? json['issued_at'] ?? json['date']),
      issuedBy: jsonText(json, ['issued_by', 'issuer']),
      issueCity: jsonText(json, ['issue_city', 'city']),
      categories: parseLicenseCategories(json),
    );
  }
}

List<String> parseLicenseCategories(Map<String, dynamic> json) {
  final fromList = <String>[];
  for (final key in ['categories', 'open_categories', 'category_list']) {
    final value = json[key];
    if (value is List) {
      for (final item in value) {
        if (item == null) continue;
        if (item is Map) {
          final code = jsonText(Map<String, dynamic>.from(item), [
            'code',
            'category',
            'name',
            'title',
          ]);
          if (code.isNotEmpty) fromList.add(code);
        } else {
          final text = item.toString().trim();
          if (text.isNotEmpty && text != 'null') fromList.add(text);
        }
      }
    }
  }
  if (fromList.isNotEmpty) return fromList;
  final joined = jsonText(json, ['categories', 'category', 'categories_open']);
  if (joined.isEmpty) return const [];
  return joined
      .split(RegExp(r'[,;/|\s]+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

class DriverPassport {
  final String series;
  final String number;
  final String issueDate;

  const DriverPassport({
    this.series = '',
    this.number = '',
    this.issueDate = '',
  });

  bool get hasContent =>
      series.isNotEmpty || number.isNotEmpty || issueDate.isNotEmpty;

  String get seriesNumber =>
      [series, number].where((part) => part.isNotEmpty).join(' ');

  String get displaySeriesNumber => formatRuPassportNumber(series, number);

  factory DriverPassport.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DriverPassport();
    return DriverPassport(
      series: jsonText(json, ['series']),
      number: jsonText(json, ['number']),
      issueDate: formatDay(json['issue_date'] ?? json['date']),
    );
  }
}

class DriverAuto {
  final String id;
  final String stateNumber;
  final String brand;
  final String model;
  final String vin;
  final String year;
  final String color;
  final String stsNumber;
  final String carCategory;
  final String bodyType;

  const DriverAuto({
    this.id = '',
    this.stateNumber = '',
    this.brand = '',
    this.model = '',
    this.vin = '',
    this.year = '',
    this.color = '',
    this.stsNumber = '',
    this.carCategory = '',
    this.bodyType = '',
  });

  bool get hasContent =>
      stateNumber.isNotEmpty ||
      brand.isNotEmpty ||
      model.isNotEmpty ||
      vin.isNotEmpty ||
      year.isNotEmpty ||
      color.isNotEmpty ||
      stsNumber.isNotEmpty ||
      carCategory.isNotEmpty ||
      bodyType.isNotEmpty;

  String get title {
    final name = [brand, model].where((part) => part.isNotEmpty).join(' ');
    return [name, stateNumber].where((part) => part.isNotEmpty).join(' · ');
  }

  factory DriverAuto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DriverAuto();
    return DriverAuto(
      id: jsonText(json, ['id']),
      stateNumber: jsonText(json, ['state_number', 'number', 'plate']),
      brand: jsonText(json, ['brand']),
      model: jsonText(json, ['model']),
      vin: jsonText(json, ['vin']),
      year: jsonText(json, ['year']),
      color: jsonText(json, ['color']),
      stsNumber: jsonText(json, ['sts_number', 'sts']),
      carCategory: jsonText(json, ['car_category', 'category']),
      bodyType: jsonText(json, ['body_type']),
    );
  }
}

class DriverProfile {
  final String id;
  final String name;
  final String phone;
  final String phoneSecondary;
  final String email;
  final String carrierName;
  final DriverLicense license;
  final DriverPassport passport;
  final DriverAuto? auto;

  const DriverProfile({
    required this.id,
    required this.name,
    this.phone = '',
    this.phoneSecondary = '',
    this.email = '',
    this.carrierName = '',
    this.license = const DriverLicense(),
    this.passport = const DriverPassport(),
    this.auto,
  });

  String get vehicle => auto?.title ?? '';

  DriverProfile orFallback(DriverProfile? other) {
    if (other == null) return this;
    String pick(String value, String fallback) =>
        value.isNotEmpty ? value : fallback;
    return DriverProfile(
      id: pick(id, other.id),
      name: pick(name, other.name),
      phone: pick(phone, other.phone),
      phoneSecondary: pick(phoneSecondary, other.phoneSecondary),
      email: pick(email, other.email),
      carrierName: pick(carrierName, other.carrierName),
      license: license.hasContent ? license : other.license,
      passport: passport.hasContent ? passport : other.passport,
      auto: (auto?.hasContent ?? false) ? auto : other.auto,
    );
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final root = unwrapJson(json);
    final source = jsonMap(root, ['driver', 'user', 'profile']) ?? root;
    final auto = jsonMap(root, ['auto']) ?? jsonMap(source, ['auto']);
    var name = jsonText(source, ['full_name', 'name', 'fio']);
    if (name.isEmpty) {
      name = [
        jsonText(source, ['last_name', 'second_name', 'surname']),
        jsonText(source, ['first_name']),
        jsonText(source, ['patronymic', 'middle_name']),
      ].where((part) => part.isNotEmpty).join(' ');
    }

    return DriverProfile(
      id: jsonText(source, ['id', 'driver_id']),
      name: name,
      phone: jsonText(source, ['phone', 'mobile_phone', 'mobile']),
      phoneSecondary: jsonText(source, [
        'phone_secondary',
        'secondary_mobile_phone',
      ]),
      email: jsonText(source, ['email']),
      carrierName: jsonText(source, [
        'company_name',
        'carrier_name',
        'company',
      ]),
      license: DriverLicense.fromJson(jsonMap(source, ['license'])),
      passport: DriverPassport.fromJson(jsonMap(source, ['passport'])),
      auto: auto == null ? null : DriverAuto.fromJson(auto),
    );
  }
}

String formatRuLicenseNumber(String raw) {
  final compact = raw.replaceAll(RegExp(r'[\s-]'), '');
  if (RegExp(r'^\d{10}$').hasMatch(compact)) {
    return '${compact.substring(0, 2)} ${compact.substring(2, 4)} ${compact.substring(4)}';
  }
  return raw.trim();
}

String formatRuPassportNumber(String series, String number) {
  final joined = '$series$number'.replaceAll(RegExp(r'[\s-]'), '');
  if (RegExp(r'^\d{10}$').hasMatch(joined)) {
    return '${joined.substring(0, 2)} ${joined.substring(2, 4)}  ${joined.substring(4)}';
  }
  return [series, number].where((part) => part.trim().isNotEmpty).join(' ');
}

String formatDay(Object? raw) {
  if (raw == null) return '';
  final value = raw.toString().trim();
  if (value.isEmpty || value == 'null') return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final dd = parsed.day.toString().padLeft(2, '0');
  final mm = parsed.month.toString().padLeft(2, '0');
  return '$dd.$mm.${parsed.year}';
}
