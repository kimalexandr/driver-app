String _text(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null || value is Map) continue;
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

Map<String, dynamic>? _map(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return null;
}

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

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final nested = json['driver'];
    final source = nested is Map ? Map<String, dynamic>.from(nested) : json;
    final vehicleMap = _map(source, ['vehicle', 'car', 'truck']);
    final licenseMap = _map(source, ['license', 'driver_license']);
    final carrierMap = _map(source, ['carrier', 'company', 'organization']);
    final vehicleText = vehicleMap == null
        ? _text(source, ['vehicle', 'vehicle_number', 'car_number', 'truck_number'])
        : [
            [
              _text(vehicleMap, ['brand', 'name']),
              _text(vehicleMap, ['model']),
            ].where((part) => part.isNotEmpty).join(' '),
            _text(vehicleMap, ['number', 'reg_number', 'plate']),
          ].where((part) => part.isNotEmpty).join(' · ');

    return DriverProfile(
      id: _text(source, ['id', 'driver_id']),
      name: _text(source, ['name', 'full_name', 'fio']),
      phone: _text(source, ['phone', 'mobile_phone', 'mobile']),
      carrierName: carrierMap == null
          ? _text(source, [
              'carrier_name',
              'carrier',
              'company',
              'company_name',
              'organization',
            ])
          : _text(carrierMap, ['name', 'title', 'full_name']),
      vehicle: vehicleText,
      licenseNumber: licenseMap == null
          ? _text(source, [
              'license_number',
              'driver_license',
              'license',
              'vu_number',
            ])
          : _text(licenseMap, ['number', 'series_number', 'value']),
      licenseCategories: licenseMap == null
          ? _text(source, ['license_categories', 'categories', 'license_category'])
          : _text(licenseMap, ['categories', 'category']),
      licenseIssuedAt: licenseMap == null
          ? _text(source, ['license_issued_at', 'license_date'])
          : _text(licenseMap, ['issued_at', 'date']),
      passportNumber: _text(source, ['passport_number', 'passport', 'passport_series_number']),
      inn: _text(source, ['inn']),
      comment: _text(source, ['comment', 'notes', 'note']),
    );
  }
}
