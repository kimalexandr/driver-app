String _text(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is Map) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

num? _number(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
      if (parsed != null) return parsed;
    }
  }
  return null;
}

Map<String, dynamic>? _map(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return null;
}

class Party {
  final String name;
  final String company;
  final String phone;
  final String address;
  final String comment;

  const Party({
    this.name = '',
    this.company = '',
    this.phone = '',
    this.address = '',
    this.comment = '',
  });

  bool get hasContent =>
      name.isNotEmpty ||
      company.isNotEmpty ||
      phone.isNotEmpty ||
      address.isNotEmpty ||
      comment.isNotEmpty;

  factory Party.fromJson(
    Map<String, dynamic> json, {
    required List<String> nestedKeys,
    required String prefix,
  }) {
    for (final key in nestedKeys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return Party(name: value.trim());
      }
    }
    final nested = _map(json, nestedKeys);
    final source = nested ?? json;
    final usePrefix = nested == null;
    String key(String name) => usePrefix ? '${prefix}_$name' : name;

    return Party(
      name: _text(source, [
        key('name'),
        key('full_name'),
        key('contact'),
        key('contact_name'),
        key('person'),
        if (!usePrefix) 'fio',
      ]),
      company: _text(source, [
        key('company'),
        key('organization'),
        key('legal_name'),
        key('title'),
      ]),
      phone: _text(source, [
        key('phone'),
        key('mobile'),
        key('mobile_phone'),
        key('contact_phone'),
      ]),
      address: _text(source, [
        key('address'),
      ]),
      comment: _text(source, [
        key('comment'),
        key('notes'),
        key('note'),
      ]),
    );
  }
}

class Shipment {
  final String id;
  final String title;
  final num? weightKg;
  final num? volumeM3;
  final String comment;

  const Shipment({
    required this.id,
    required this.title,
    this.weightKg,
    this.volumeM3,
    this.comment = '',
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    final title = json['name'] ??
        json['cargo'] ??
        json['product'] ??
        json['title'] ??
        json['description'] ??
        json['number'] ??
        json['id'] ??
        '';
    return Shipment(
      id: '${json['id'] ?? title}',
      title: '$title',
      weightKg: _number(json, ['weight_kg', 'weight', 'mass', 'kg']),
      volumeM3: _number(json, ['volume_m3', 'volume', 'm3']),
      comment: _text(json, ['comment', 'notes', 'note']),
    );
  }
}

class Trip {
  final String id;
  final String number;
  final String status;
  final String statusLabel;
  final String from;
  final String to;
  final String dateStart;
  final String vehicle;
  final String startAddress;
  final String finishAddress;
  final String comment;
  final String cargo;
  final num? weightKg;
  final num? volumeM3;
  final Party sender;
  final Party recipient;
  final List<Shipment> shipments;

  const Trip({
    required this.id,
    required this.number,
    required this.status,
    required this.statusLabel,
    required this.from,
    required this.to,
    required this.dateStart,
    this.vehicle = '',
    this.startAddress = '',
    this.finishAddress = '',
    this.comment = '',
    this.cargo = '',
    this.weightKg,
    this.volumeM3,
    this.sender = const Party(),
    this.recipient = const Party(),
    this.shipments = const [],
  });

  bool get canStart => status == 'created' || status == 'assigned';
  bool get canDeliver => status == 'in_transit';
  bool get isInTransit => status == 'in_transit';

  num? get totalWeightKg {
    if (weightKg != null) return weightKg;
    final sum = shipments.fold<num>(0, (acc, item) => acc + (item.weightKg ?? 0));
    return sum == 0 ? null : sum;
  }

  num? get totalVolumeM3 {
    if (volumeM3 != null) return volumeM3;
    final sum = shipments.fold<num>(0, (acc, item) => acc + (item.volumeM3 ?? 0));
    return sum == 0 ? null : sum;
  }

  String get cargoLabel {
    if (cargo.isNotEmpty) return cargo;
    final names = shipments.map((item) => item.title).where((item) => item.isNotEmpty);
    return names.join(', ');
  }

  Trip copyWith({String? status, String? statusLabel}) {
    return Trip(
      id: id,
      number: number,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      from: from,
      to: to,
      dateStart: dateStart,
      vehicle: vehicle,
      startAddress: startAddress,
      finishAddress: finishAddress,
      comment: comment,
      cargo: cargo,
      weightKg: weightKg,
      volumeM3: volumeM3,
      sender: sender,
      recipient: recipient,
      shipments: shipments,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    final shipmentsRaw = json['shipments'] ?? json['goods'] ?? json['cargo_items'];
    final shipments = shipmentsRaw is List
        ? shipmentsRaw
            .whereType<Map>()
            .map((item) => Shipment.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <Shipment>[];

    return Trip(
      id: '${json['id']}',
      number: '${json['number'] ?? json['id']}',
      status: '${json['status'] ?? ''}',
      statusLabel: '${json['status_label'] ?? _labelFor(json['status'])}',
      from: '${json['from'] ?? ''}',
      to: '${json['to'] ?? ''}',
      dateStart: _formatDate(json['date_start']),
      vehicle: _vehicle(json['vehicle']),
      startAddress: _text(json, ['start_address', 'loading_address']),
      finishAddress: _text(json, ['finish_address', 'unloading_address']),
      comment: _text(json, [
        'comment',
        'comments',
        'note',
        'notes',
        'driver_comment',
        'description',
      ]),
      cargo: _text(json, ['cargo', 'product', 'goods', 'cargo_name']),
      weightKg: _number(json, ['weight_kg', 'weight', 'total_weight', 'mass']),
      volumeM3: _number(json, ['volume_m3', 'volume', 'total_volume']),
      sender: Party.fromJson(
        json,
        nestedKeys: ['sender', 'shipper', 'consignor', 'sender_info'],
        prefix: 'sender',
      ),
      recipient: Party.fromJson(
        json,
        nestedKeys: ['recipient', 'receiver', 'consignee', 'recipient_info'],
        prefix: 'recipient',
      ),
      shipments: shipments,
    );
  }

  static String _vehicle(Object? raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      return '${raw['number'] ?? raw['name'] ?? raw['title'] ?? ''}';
    }
    return '$raw';
  }

  static String _labelFor(Object? status) {
    switch ('$status') {
      case 'created':
        return 'Создан';
      case 'assigned':
        return 'Назначен';
      case 'in_transit':
        return 'В пути';
      case 'delivered':
        return 'Доставлено';
      default:
        return '$status';
    }
  }

  static String _formatDate(Object? raw) {
    if (raw == null) return '';
    final value = raw.toString();
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final dd = parsed.day.toString().padLeft(2, '0');
    final mm = parsed.month.toString().padLeft(2, '0');
    final hh = parsed.hour.toString().padLeft(2, '0');
    final min = parsed.minute.toString().padLeft(2, '0');
    if (hh == '00' && min == '00' && !value.contains('T') && !value.contains(' ')) {
      return '$dd.$mm.${parsed.year}';
    }
    return '$dd.$mm.${parsed.year} $hh:$min';
  }
}

String formatKg(num? value) {
  if (value == null) return '';
  return '${_trimNum(value)} кг';
}

String formatM3(num? value) {
  if (value == null) return '';
  return '${_trimNum(value)} м³';
}

String _trimNum(num value) {
  if (value == value.roundToDouble()) return '${value.round()}';
  return value.toString();
}
