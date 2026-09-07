import 'json_fields.dart';

class DriverProfile {
  final String id;
  final String name;
  final String phone;
  final String carrierName;
  final String vehicle;
  final String licenseNumber;
  final String licenseCategories;
  final String licenseIssuedAt;
  final String passportNumber;
  final String inn;
  final String comment;

  const DriverProfile({
    required this.id,
    required this.name,
    this.phone = '',
    this.carrierName = '',
    this.vehicle = '',
    this.licenseNumber = '',
    this.licenseCategories = '',
    this.licenseIssuedAt = '',
    this.passportNumber = '',
    this.inn = '',
    this.comment = '',
  });

  DriverProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? carrierName,
    String? vehicle,
    String? licenseNumber,
    String? licenseCategories,
    String? licenseIssuedAt,
    String? passportNumber,
    String? inn,
    String? comment,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      carrierName: carrierName ?? this.carrierName,
      vehicle: vehicle ?? this.vehicle,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseCategories: licenseCategories ?? this.licenseCategories,
      licenseIssuedAt: licenseIssuedAt ?? this.licenseIssuedAt,
      passportNumber: passportNumber ?? this.passportNumber,
      inn: inn ?? this.inn,
      comment: comment ?? this.comment,
    );
  }

  DriverProfile orFallback(DriverProfile? other) {
    if (other == null) return this;
    String pick(String value, String fallback) =>
        value.isNotEmpty ? value : fallback;
    return DriverProfile(
      id: pick(id, other.id),
      name: pick(name, other.name),
      phone: pick(phone, other.phone),
      carrierName: pick(carrierName, other.carrierName),
      vehicle: pick(vehicle, other.vehicle),
      licenseNumber: pick(licenseNumber, other.licenseNumber),
      licenseCategories: pick(licenseCategories, other.licenseCategories),
      licenseIssuedAt: pick(licenseIssuedAt, other.licenseIssuedAt),
      passportNumber: pick(passportNumber, other.passportNumber),
      inn: pick(inn, other.inn),
      comment: pick(comment, other.comment),
    );
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final root = unwrapJson(json);
    final nested = jsonMap(root, ['driver', 'user', 'profile']);
    final source = nested ?? root;
    final vehicleMap = jsonMap(source, ['vehicle', 'car', 'truck']);
    final licenseMap = jsonMap(source, ['license', 'driver_license']);
    final carrierMap = jsonMap(source, ['carrier', 'company', 'organization']);
    final vehicleText = vehicleMap == null
        ? jsonText(source, [
            'vehicle',
            'vehicle_number',
            'car_number',
            'truck_number',
          ])
        : [
            [
              jsonText(vehicleMap, ['brand', 'name']),
              jsonText(vehicleMap, ['model']),
            ].where((part) => part.isNotEmpty).join(' '),
            jsonText(vehicleMap, ['number', 'reg_number', 'plate']),
          ].where((part) => part.isNotEmpty).join(' · ');

    var name = jsonText(source, ['name', 'full_name', 'fio']);
    if (name.isEmpty) {
      name = [
        jsonText(source, ['last_name', 'surname', 'lastname']),
        jsonText(source, ['first_name', 'firstname']),
        jsonText(source, ['middle_name', 'patronymic']),
      ].where((part) => part.isNotEmpty).join(' ');
    }

    final licenseNumber = licenseMap == null
        ? [
            jsonText(source, ['license_series', 'vu_series']),
            jsonText(source, [
              'license_number',
              'driver_license',
              'license',
              'vu_number',
            ]),
          ].where((part) => part.isNotEmpty).join(' ')
        : [
            jsonText(licenseMap, ['series']),
            jsonText(licenseMap, ['number', 'series_number', 'value']),
          ].where((part) => part.isNotEmpty).join(' ');

    final passport = [
      jsonText(source, ['passport_series']),
      jsonText(source, ['passport_number', 'passport', 'passport_series_number']),
    ].where((part) => part.isNotEmpty).join(' ');

    return DriverProfile(
      id: jsonText(source, ['id', 'driver_id']),
      name: name,
      phone: jsonText(source, ['phone', 'mobile_phone', 'mobile']),
      carrierName: carrierMap == null
          ? jsonText(source, [
              'carrier_name',
              'carrier',
              'company',
              'company_name',
              'organization',
            ])
          : jsonText(carrierMap, ['name', 'title', 'full_name']),
      vehicle: vehicleText,
      licenseNumber: licenseNumber,
      licenseCategories: licenseMap == null
          ? jsonText(source, [
              'license_categories',
              'categories',
              'license_category',
            ])
          : jsonText(licenseMap, ['categories', 'category']),
      licenseIssuedAt: licenseMap == null
          ? jsonText(source, ['license_issued_at', 'license_date'])
          : jsonText(licenseMap, ['issued_at', 'date']),
      passportNumber: passport,
      inn: jsonText(source, ['inn']),
      comment: jsonText(source, ['comment', 'notes', 'note']),
    );
  }
}
