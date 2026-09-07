import 'json_fields.dart';

class DriverLicense {
  final String number;
  final String issueDate;
  final String issuedBy;
  final String issueCity;

  const DriverLicense({
    this.number = '',
    this.issueDate = '',
    this.issuedBy = '',
    this.issueCity = '',
  });

  bool get hasContent =>
      number.isNotEmpty ||
      issueDate.isNotEmpty ||
      issuedBy.isNotEmpty ||
      issueCity.isNotEmpty;

  factory DriverLicense.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DriverLicense();
    return DriverLicense(
      number: jsonText(json, ['number']),
      issueDate: formatDay(json['issue_date'] ?? json['issued_at'] ?? json['date']),
      issuedBy: jsonText(json, ['issued_by', 'issuer']),
      issueCity: jsonText(json, ['issue_city', 'city']),
    );
  }
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
