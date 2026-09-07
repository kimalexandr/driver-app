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
}

class GateInfo {
  final String number;
  final String comment;

  const GateInfo({this.number = '', this.comment = ''});

  bool get hasContent => number.isNotEmpty || comment.isNotEmpty;

  factory GateInfo.fromJson(Object? raw) {
    if (raw is Map) {
      final json = Map<String, dynamic>.from(raw);
      return GateInfo(
        number: jsonText(json, ['number', 'name', 'title']),
        comment: jsonText(json, ['comment', 'note']),
      );
    }
    if (raw == null) return const GateInfo();
    final text = raw.toString().trim();
    if (text.isEmpty || text == 'null') return const GateInfo();
    return GateInfo(number: text);
  }
}

class TripStop {
  final String type;
  final String title;
  final String address;
  final double? lat;
  final double? lng;
  final String queue;
  final GateInfo gate;
  final String comment;
  final String cargoName;
  final num? weightKg;

  const TripStop({
    this.type = '',
    this.title = '',
    this.address = '',
    this.lat,
    this.lng,
    this.queue = '',
    this.gate = const GateInfo(),
    this.comment = '',
    this.cargoName = '',
    this.weightKg,
  });

  bool get isLoad => type == 'load' || type == 'loading';
  bool get isUnload => type == 'unload' || type == 'unloading';

  factory TripStop.fromJson(Map<String, dynamic> json) {
    return TripStop(
      type: jsonText(json, ['type', 'kind', 'role']).toLowerCase(),
      title: jsonText(json, ['title', 'name', 'city']),
      address: jsonText(json, ['address', 'full_address']),
      lat: jsonNumber(json, ['lat', 'latitude'])?.toDouble(),
      lng: jsonNumber(json, ['lng', 'lon', 'longitude'])?.toDouble(),
      queue: jsonText(json, ['queue', 'load_queue', 'unload_queue']),
      gate: GateInfo.fromJson(json['gate']),
      comment: jsonText(json, ['comment']),
      cargoName: jsonText(json, ['cargo_name', 'cargo']),
      weightKg: jsonNumber(json, ['weight_kg', 'weight']),
    );
  }
}

class Shipment {
  final String id;
  final String title;
  final String status;
  final String from;
  final String to;
  final String fromAddress;
  final String toAddress;
  final String dateStart;
  final String dateEnd;
  final num? weightKg;
  final num? volumeM3;
  final num? units;
  final String measureUnit;
  final num? widthM;
  final num? depthM;
  final num? heightM;
  final String consignee;
  final String comment;
  final String loadComment;
  final String unloadComment;
  final String loadQueue;
  final String unloadQueue;
  final GateInfo loadGate;
  final GateInfo unloadGate;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;

  const Shipment({
    required this.id,
    required this.title,
    this.status = '',
    this.from = '',
    this.to = '',
    this.fromAddress = '',
    this.toAddress = '',
    this.dateStart = '',
    this.dateEnd = '',
    this.weightKg,
    this.volumeM3,
    this.units,
    this.measureUnit = '',
    this.widthM,
    this.depthM,
    this.heightM,
    this.consignee = '',
    this.comment = '',
    this.loadComment = '',
    this.unloadComment = '',
    this.loadQueue = '',
    this.unloadQueue = '',
    this.loadGate = const GateInfo(),
    this.unloadGate = const GateInfo(),
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
  });

  bool get hasRoute =>
      from.isNotEmpty ||
      to.isNotEmpty ||
      fromAddress.isNotEmpty ||
      toAddress.isNotEmpty;

  String get sizeLabel {
    if (widthM == null && depthM == null && heightM == null) return '';
    return '${[
      widthM,
      depthM,
      heightM,
    ].map((value) => value == null ? '—' : _trimNum(value)).join(' × ')} м';
  }

  factory Shipment.fromJson(Map<String, dynamic> json) {
    final cargo = jsonMap(json, ['cargo']);
    final title = cargo == null
        ? jsonText(json, ['cargo_name', 'name', 'title', 'shipping_condition'])
        : jsonText(cargo, ['name', 'title', 'cargo_name']);
    final comment = jsonText(json, ['comment']);
    return Shipment(
      id: jsonText(json, ['id', 'uuid']).isNotEmpty
          ? jsonText(json, ['id', 'uuid'])
          : title,
      title: title,
      status: jsonText(json, ['status', 'status_label']),
      from: jsonText(json, ['from']),
      to: jsonText(json, ['to']),
      fromAddress: jsonText(json, ['from_address']),
      toAddress: jsonText(json, ['to_address']),
      dateStart: formatTripDate(json['date_start']),
      dateEnd: formatTripDate(json['date_end']),
      weightKg: (cargo == null ? null : jsonNumber(cargo, ['weight_kg', 'weight'])) ??
          jsonNumber(json, ['weight_kg', 'weight']),
      volumeM3: jsonNumber(json, ['volume_m3', 'volume']),
      units: (cargo == null ? null : jsonNumber(cargo, ['units'])) ??
          jsonNumber(json, ['units']),
      measureUnit: cargo == null
          ? jsonText(json, ['measure_unit'])
          : jsonText(cargo, ['measure_unit']),
      widthM: cargo == null
          ? jsonNumber(json, ['width_m', 'width'])
          : jsonNumber(cargo, ['width_m', 'width']),
      depthM: cargo == null
          ? jsonNumber(json, ['depth_m', 'depth'])
          : jsonNumber(cargo, ['depth_m', 'depth']),
      heightM: cargo == null
          ? jsonNumber(json, ['height_m', 'height'])
          : jsonNumber(cargo, ['height_m', 'height']),
      consignee: jsonText(json, ['consignee']),
      comment: comment == title ? '' : comment,
      loadComment: jsonText(json, ['load_comment']),
      unloadComment: jsonText(json, ['unload_comment']),
      loadQueue: jsonText(json, ['load_queue']),
      unloadQueue: jsonText(json, ['unload_queue']),
      loadGate: GateInfo.fromJson(json['load_gate']),
      unloadGate: GateInfo.fromJson(json['unload_gate']),
      fromLat: jsonNumber(json, ['from_lat'])?.toDouble(),
      fromLng: jsonNumber(json, ['from_lng'])?.toDouble(),
      toLat: jsonNumber(json, ['to_lat'])?.toDouble(),
      toLng: jsonNumber(json, ['to_lng'])?.toDouble(),
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
  final String dateEnd;
  final String vehicle;
  final String startAddress;
  final String finishAddress;
  final String startCompany;
  final String finishCompany;
  final String startComment;
  final String finishComment;
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
  final List<TripStop> stops;

  const Trip({
    required this.id,
    required this.number,
    required this.status,
    required this.statusLabel,
    required this.from,
    required this.to,
    required this.dateStart,
    this.dateEnd = '',
    this.vehicle = '',
    this.startAddress = '',
    this.finishAddress = '',
    this.startCompany = '',
    this.finishCompany = '',
    this.startComment = '',
    this.finishComment = '',
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
    this.stops = const [],
  });

  bool get canStart => status == 'created' || status == 'assigned';
  bool get canDeliver => status == 'in_transit';
  bool get isInTransit => status == 'in_transit';
  bool get isCompleted => status == 'delivered';
  bool get needsLocation => status == 'assigned' || status == 'in_transit';

  String get destination {
    if (canStart) {
      return startAddress.isNotEmpty ? startAddress : from;
    }
    return finishAddress.isNotEmpty ? finishAddress : to;
  }

  double? get destinationLat => canStart ? startLat : finishLat;
  double? get destinationLng => canStart ? startLng : finishLng;

  String get dateRange {
    if (dateStart.isEmpty) return dateEnd;
    if (dateEnd.isEmpty || dateEnd == dateStart) return dateStart;
    return '$dateStart — $dateEnd';
  }

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
      dateEnd: dateEnd,
      vehicle: vehicle,
      startAddress: startAddress,
      finishAddress: finishAddress,
      startCompany: startCompany,
      finishCompany: finishCompany,
      startComment: startComment,
      finishComment: finishComment,
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
      stops: stops,
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
      dateEnd: pick(dateEnd, other.dateEnd),
      vehicle: pick(vehicle, other.vehicle),
      startAddress: pick(startAddress, other.startAddress),
      finishAddress: pick(finishAddress, other.finishAddress),
      startCompany: pick(startCompany, other.startCompany),
      finishCompany: pick(finishCompany, other.finishCompany),
      startComment: pick(startComment, other.startComment),
      finishComment: pick(finishComment, other.finishComment),
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
      stops: stops.isNotEmpty ? stops : other.stops,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    final source = unwrapJson(json);
    final trip = jsonMap(source, ['trip']) ?? source;
    final shipments =
        jsonMaps(trip, ['shipments']).map(Shipment.fromJson).toList();
    final stops = jsonMaps(trip, ['stops']).map(TripStop.fromJson).toList();
    final start = _routeEnd(
      trip,
      shipments: shipments,
      objectKeys: const ['start_point', 'loading', 'loading_point'],
      cityKeys: const ['from', 'start_city', 'loading_city'],
      addressKeys: const ['start_address', 'loading_address', 'from_address'],
      companyKeys: const ['start_company', 'start_company_name'],
      commentKeys: const ['start_comment'],
      pointTypes: const ['load', 'loading', 'start', 'pickup'],
      fallbackIndex: 0,
    );
    final finish = _routeEnd(
      trip,
      shipments: shipments,
      objectKeys: const ['finish_point', 'unloading', 'unloading_point'],
      cityKeys: const ['to', 'finish_city', 'unloading_city'],
      addressKeys: const ['finish_address', 'unloading_address', 'to_address'],
      companyKeys: const ['finish_company', 'finish_company_name'],
      commentKeys: const ['finish_comment'],
      pointTypes: const ['unload', 'unloading', 'finish', 'delivery', 'dropoff'],
      fallbackIndex: -1,
    );
    final rawStatus = jsonText(trip, ['status']);
    final statusLabel = jsonText(trip, ['status_label']).isNotEmpty
        ? jsonText(trip, ['status_label'])
        : _labelFor(rawStatus);
    final status = _normalizeStatus(rawStatus, statusLabel);
    final consignee = shipments
        .map((item) => item.consignee)
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');

    return Trip(
      id: jsonText(trip, ['id', 'trip_id', 'uuid']),
      number: jsonText(trip, ['number', 'sap_id', 'id']),
      status: status,
      statusLabel: statusLabel,
      from: start.city,
      to: finish.city,
      dateStart: formatTripDate(
        trip['date_start'] ?? trip['start_date'] ?? trip['loading_date'],
      ),
      dateEnd: formatTripDate(
        trip['date_end'] ?? trip['finish_date'] ?? trip['unloading_date'],
      ),
      vehicle: jsonText(trip, ['vehicle']),
      startAddress: start.address,
      finishAddress: finish.address,
      startCompany: start.company,
      finishCompany: finish.company,
      startComment: start.comment,
      finishComment: finish.comment,
      comment: jsonText(trip, ['comment', 'driver_comment', 'notes']),
      cargo: jsonText(trip, ['cargo', 'cargo_name', 'goods']),
      weightKg: jsonNumber(trip, ['weight_kg', 'total_weight', 'weight', 'cargo']),
      volumeM3: jsonNumber(trip, ['volume_m3', 'volume']),
      startLat: start.lat,
      startLng: start.lng,
      finishLat: finish.lat,
      finishLng: finish.lng,
      sender: Party(company: start.company, address: start.address),
      recipient: Party(
        company: finish.company,
        name: consignee,
        address: finish.address,
      ),
      shipments: shipments,
      stops: stops,
    );
  }

  static String _normalizeStatus(String raw, String label) {
    final haystack = '${raw.toLowerCase()} ${label.toLowerCase()}';
    if (haystack.contains('deliver') ||
        haystack.contains('complete') ||
        haystack.contains('достав')) {
      return 'delivered';
    }
    if (haystack.contains('transit') ||
        haystack.contains('in_way') ||
        haystack.contains('пути')) {
      return 'in_transit';
    }
    if (haystack.contains('assign') ||
        haystack.contains('creat') ||
        haystack.contains('назнач')) {
      return 'assigned';
    }
    return raw;
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
}

class _RouteEnd {
  final String city;
  final String address;
  final String company;
  final String comment;
  final double? lat;
  final double? lng;

  const _RouteEnd({
    this.city = '',
    this.address = '',
    this.company = '',
    this.comment = '',
    this.lat,
    this.lng,
  });
}

_RouteEnd _routeEnd(
  Map<String, dynamic> json, {
  required List<Shipment> shipments,
  required List<String> objectKeys,
  required List<String> cityKeys,
  required List<String> addressKeys,
  required List<String> companyKeys,
  required List<String> commentKeys,
  required List<String> pointTypes,
  required int fallbackIndex,
}) {
  final obj = jsonMap(json, objectKeys);
  var city = obj == null
      ? jsonText(json, cityKeys)
      : jsonText(obj, ['city', 'name', 'title', 'from', 'to']);
  var address = obj == null
      ? jsonText(json, addressKeys)
      : jsonText(obj, ['full_address', 'address', 'formatted']);
  var company = jsonText(json, companyKeys);
  var comment = jsonText(json, commentKeys);
  var lat = jsonNumber(json, [
    if (fallbackIndex == 0) ...['start_lat', 'from_lat'],
    if (fallbackIndex != 0) ...['finish_lat', 'to_lat'],
  ])?.toDouble();
  var lng = jsonNumber(json, [
    if (fallbackIndex == 0) ...['start_lng', 'from_lng'],
    if (fallbackIndex != 0) ...['finish_lng', 'to_lng'],
  ])?.toDouble();

  final points = jsonMaps(json, ['stops', 'points']);
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
    if (city.isEmpty) city = jsonText(point, ['city', 'name', 'title', 'from', 'to']);
    if (address.isEmpty) {
      address = jsonText(point, ['address', 'full_address', 'formatted']);
    }
    lat ??= jsonNumber(point, ['lat', 'latitude'])?.toDouble();
    lng ??= jsonNumber(point, ['lng', 'lon', 'longitude'])?.toDouble();
  }

  if (shipments.isNotEmpty) {
    final shipment = fallbackIndex < 0 ? shipments.last : shipments.first;
    if (fallbackIndex == 0) {
      if (city.isEmpty) city = shipment.from;
      if (address.isEmpty) address = shipment.fromAddress;
      lat ??= shipment.fromLat;
      lng ??= shipment.fromLng;
    } else {
      if (city.isEmpty) city = shipment.to;
      if (address.isEmpty) address = shipment.toAddress;
      lat ??= shipment.toLat;
      lng ??= shipment.toLng;
    }
  }

  return _RouteEnd(
    city: city,
    address: address,
    company: company,
    comment: comment,
    lat: lat,
    lng: lng,
  );
}

String formatTripDate(Object? raw) {
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

String formatKg(num? value) {
  if (value == null) return '';
  return '${_trimNum(value)} кг';
}

String formatM3(num? value) {
  if (value == null) return '';
  return '${_trimNum(value)} м³';
}

String formatUnits(num? units, String measureUnit) {
  if (units == null) return '';
  if (measureUnit.isEmpty) return '${_trimNum(units)} шт';
  return '${_trimNum(units)} $measureUnit';
}

String _trimNum(num value) {
  if (value == value.roundToDouble()) return '${value.round()}';
  return value.toString();
}
