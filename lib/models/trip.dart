import 'json_fields.dart';

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

  Party orFallback(Party other) {
    return Party(
      name: name.isNotEmpty ? name : other.name,
      company: company.isNotEmpty ? company : other.company,
      phone: phone.isNotEmpty ? phone : other.phone,
      address: address.isNotEmpty ? address : other.address,
      comment: comment.isNotEmpty ? comment : other.comment,
    );
  }

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
    final nested = jsonMap(json, nestedKeys);
    final source = nested ?? json;
    final usePrefix = nested == null;
    String key(String name) => usePrefix ? '${prefix}_$name' : name;

    return Party(
      name: jsonText(source, [
        key('name'),
        key('full_name'),
        key('contact'),
        key('contact_name'),
        key('person'),
        if (!usePrefix) 'fio',
      ]),
      company: jsonText(source, [
        key('company'),
        key('organization'),
        key('legal_name'),
        key('title'),
      ]),
      phone: jsonText(source, [
        key('phone'),
        key('mobile'),
        key('mobile_phone'),
        key('contact_phone'),
      ]),
      address: jsonText(source, [
        key('address'),
        key('full_address'),
      ]),
      comment: jsonText(source, [
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
    final title = jsonText(json, [
      'name',
      'cargo',
      'product',
      'title',
      'description',
      'nomenclature',
      'number',
      'id',
    ]);
    return Shipment(
      id: jsonText(json, ['id', 'uuid']) .isNotEmpty
          ? jsonText(json, ['id', 'uuid'])
          : title,
      title: title,
      weightKg: jsonNumber(json, ['weight_kg', 'weight', 'mass', 'kg']),
      volumeM3: jsonNumber(json, ['volume_m3', 'volume', 'm3']),
      comment: jsonText(json, ['comment', 'notes', 'note']),
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
  final double? startLat;
  final double? startLng;
  final double? finishLat;
  final double? finishLng;
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
    this.startLat,
    this.startLng,
    this.finishLat,
    this.finishLng,
    this.sender = const Party(),
    this.recipient = const Party(),
    this.shipments = const [],
  });

  bool get canStart => status == 'created' || status == 'assigned';
  bool get canDeliver => status == 'in_transit';
  bool get isInTransit => status == 'in_transit';
  bool get isCompleted => status == 'delivered';

  String get destination {
    if (canStart) {
      return startAddress.isNotEmpty ? startAddress : from;
    }
    return finishAddress.isNotEmpty ? finishAddress : to;
  }

  double? get destinationLat => canStart ? startLat : finishLat;
  double? get destinationLng => canStart ? startLng : finishLng;

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
      startLat: startLat,
      startLng: startLng,
      finishLat: finishLat,
      finishLng: finishLng,
      sender: sender,
      recipient: recipient,
      shipments: shipments,
    );
  }

  Trip orFallback(Trip other) {
    String pick(String value, String fallback) =>
        value.isNotEmpty && value != 'null' ? value : fallback;
    return Trip(
      id: pick(id, other.id),
      number: pick(number, other.number),
      status: pick(status, other.status),
      statusLabel: pick(statusLabel, other.statusLabel),
      from: pick(from, other.from),
      to: pick(to, other.to),
      dateStart: pick(dateStart, other.dateStart),
      vehicle: pick(vehicle, other.vehicle),
      startAddress: pick(startAddress, other.startAddress),
      finishAddress: pick(finishAddress, other.finishAddress),
      comment: pick(comment, other.comment),
      cargo: pick(cargo, other.cargo),
      weightKg: weightKg ?? other.weightKg,
      volumeM3: volumeM3 ?? other.volumeM3,
      startLat: startLat ?? other.startLat,
      startLng: startLng ?? other.startLng,
      finishLat: finishLat ?? other.finishLat,
      finishLng: finishLng ?? other.finishLng,
      sender: sender.hasContent ? sender : other.sender.orFallback(sender),
      recipient:
          recipient.hasContent ? recipient : other.recipient.orFallback(recipient),
      shipments: shipments.isNotEmpty ? shipments : other.shipments,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    final source = unwrapJson(json);
    final trip = jsonMap(source, ['trip']) ?? source;
    final start = _routeEnd(
      trip,
      objectKeys: [
        'start_point',
        'loading',
        'loading_point',
        'origin',
        'pickup',
        'from_point',
      ],
      cityKeys: [
        'from',
        'loading_city',
        'city_from',
        'departure_city',
        'start_city',
        'from_city',
      ],
      addressKeys: [
        'start_address',
        'loading_address',
        'address_from',
        'from_address',
        'origin_address',
      ],
      pointTypes: const ['load', 'loading', 'start', 'pickup', 'from', 'origin'],
      fallbackIndex: 0,
    );
    final finish = _routeEnd(
      trip,
      objectKeys: [
        'finish_point',
        'unloading',
        'unloading_point',
        'destination',
        'delivery',
        'to_point',
      ],
      cityKeys: [
        'to',
        'unloading_city',
        'city_to',
        'arrival_city',
        'finish_city',
        'to_city',
        'destination_city',
      ],
      addressKeys: [
        'finish_address',
        'unloading_address',
        'address_to',
        'to_address',
        'destination_address',
      ],
      pointTypes: const [
        'unload',
        'unloading',
        'finish',
        'delivery',
        'to',
        'destination',
        'dropoff',
      ],
      fallbackIndex: -1,
    );
    final cargoMap = jsonMap(trip, ['cargo', 'goods', 'product']);
    final shipments = jsonMaps(trip, [
      'shipments',
      'goods',
      'cargo_items',
      'items',
      'cargos',
      'products',
      'nomenclatures',
    ]).map(Shipment.fromJson).toList();

    return Trip(
      id: jsonText(trip, ['id', 'trip_id', 'uuid']),
      number: jsonText(trip, ['number', 'id', 'trip_number']),
      status: jsonText(trip, ['status']),
      statusLabel: jsonText(trip, ['status_label']).isNotEmpty
          ? jsonText(trip, ['status_label'])
          : _labelFor(trip['status']),
      from: start.city,
      to: finish.city,
      dateStart: _formatDate(
        trip['date_start'] ??
            trip['loading_date'] ??
            trip['start_date'] ??
            trip['date'],
      ),
      vehicle: _vehicle(trip['vehicle'] ?? trip['car'] ?? trip['truck']),
      startAddress: start.address,
      finishAddress: finish.address,
      comment: jsonText(trip, [
        'comment',
        'comments',
        'note',
        'notes',
        'driver_comment',
        'description',
      ]),
      cargo: cargoMap == null
          ? jsonText(trip, [
              'cargo',
              'product',
              'goods',
              'cargo_name',
              'cargo_type',
              'nomenclature',
            ])
          : jsonText(cargoMap, ['name', 'title', 'cargo', 'product', 'type']),
      weightKg: jsonNumber(trip, [
            'weight_kg',
            'weight',
            'total_weight',
            'mass',
            'cargo_weight',
          ]) ??
          (cargoMap == null
              ? null
              : jsonNumber(cargoMap, ['weight_kg', 'weight', 'mass'])),
      volumeM3: jsonNumber(trip, [
            'volume_m3',
            'volume',
            'total_volume',
            'cargo_volume',
          ]) ??
          (cargoMap == null
              ? null
              : jsonNumber(cargoMap, ['volume_m3', 'volume'])),
      startLat: start.lat,
      startLng: start.lng,
      finishLat: finish.lat,
      finishLng: finish.lng,
      sender: Party.fromJson(
        trip,
        nestedKeys: ['sender', 'shipper', 'consignor', 'sender_info', 'client'],
        prefix: 'sender',
      ),
      recipient: Party.fromJson(
        trip,
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
      final map = Map<String, dynamic>.from(raw);
      return [
        jsonText(map, ['brand', 'name', 'title', 'model']),
        jsonText(map, ['number', 'reg_number', 'plate']),
      ].where((part) => part.isNotEmpty).join(' · ');
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
        return status == null ? '' : '$status';
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

class _RouteEnd {
  final String city;
  final String address;
  final double? lat;
  final double? lng;

  const _RouteEnd({
    this.city = '',
    this.address = '',
    this.lat,
    this.lng,
  });
}

_RouteEnd _routeEnd(
  Map<String, dynamic> json, {
  required List<String> objectKeys,
  required List<String> cityKeys,
  required List<String> addressKeys,
  required List<String> pointTypes,
  required int fallbackIndex,
}) {
  final obj = jsonMap(json, objectKeys);
  var city = obj == null
      ? jsonText(json, cityKeys)
      : jsonText(obj, ['city', 'locality', 'settlement', 'name', 'title', 'from', 'to']);
  var address = obj == null
      ? jsonText(json, addressKeys)
      : jsonText(obj, [
          'full_address',
          'address',
          'street',
          'value',
          'text',
          'formatted',
        ]);
  var lat = obj == null
      ? jsonNumber(json, [
          if (fallbackIndex == 0) ...['start_lat', 'loading_lat', 'from_lat'],
          if (fallbackIndex != 0) ...['finish_lat', 'unloading_lat', 'to_lat'],
        ])?.toDouble()
      : jsonNumber(obj, ['lat', 'latitude'])?.toDouble();
  var lng = obj == null
      ? jsonNumber(json, [
          if (fallbackIndex == 0) ...['start_lng', 'loading_lng', 'from_lng'],
          if (fallbackIndex != 0) ...['finish_lng', 'unloading_lng', 'to_lng'],
        ])?.toDouble()
      : jsonNumber(obj, ['lng', 'lon', 'longitude'])?.toDouble();

  if (city.isEmpty) city = jsonText(json, cityKeys);
  if (address.isEmpty) address = jsonText(json, addressKeys);

  final points = jsonMaps(json, [
    'points',
    'stops',
    'waypoints',
    'locations',
    'route_points',
  ]);
  Map<String, dynamic>? point;
  for (final item in points) {
    final type =
        '${item['type'] ?? item['kind'] ?? item['role'] ?? item['point_type']}'
            .toLowerCase();
    if (pointTypes.any(type.contains)) {
      point = item;
      break;
    }
  }
  if (point == null && points.isNotEmpty) {
    point = fallbackIndex < 0 ? points.last : points.first;
  }
  if (point != null) {
    if (city.isEmpty) {
      city = jsonText(point, ['city', 'locality', 'settlement', 'name', 'title']);
    }
    if (address.isEmpty) {
      address = jsonText(point, [
        'full_address',
        'address',
        'street',
        'value',
        'text',
        'formatted',
      ]);
    }
    lat ??= jsonNumber(point, ['lat', 'latitude'])?.toDouble();
    lng ??= jsonNumber(point, ['lng', 'lon', 'longitude'])?.toDouble();
  }

  return _RouteEnd(city: city, address: address, lat: lat, lng: lng);
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
