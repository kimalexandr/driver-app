import 'dart:math' as math;

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
  final String plannedAt;

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
    this.plannedAt = '',
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
      plannedAt: formatTripDate(json['planned_at'] ?? json['date'] ?? json['datetime']),
    );
  }
}

class StatusEvent {
  final String status;
  final String label;
  final String at;

  const StatusEvent({
    this.status = '',
    this.label = '',
    this.at = '',
  });

  bool matches(String key) {
    final haystack = '${status.toLowerCase()} ${label.toLowerCase()}';
    return haystack.contains(key.toLowerCase());
  }

  factory StatusEvent.fromJson(Map<String, dynamic> json) {
    final status = jsonText(json, ['status', 'code', 'kind', 'type']);
    final label = jsonText(json, ['status_label', 'label', 'title', 'name']);
    return StatusEvent(
      status: status,
      label: label,
      at: formatTripDate(
        json['at'] ??
            json['changed_at'] ??
            json['created_at'] ??
            json['datetime'] ??
            json['date'],
      ),
    );
  }
}

class EtrnTitle {
  final String code;
  final String name;
  final bool signed;
  final String signedAt;
  final String signedBy;

  const EtrnTitle({
    required this.code,
    this.name = '',
    this.signed = false,
    this.signedAt = '',
    this.signedBy = '',
  });

  String get title => name.isNotEmpty ? name : etrnTitleName(code);

  String get statusLine {
    if (!signed) return 'не подписан';
    return [
      'подписан',
      if (signedAt.isNotEmpty) signedAt,
      if (signedBy.isNotEmpty) signedBy,
    ].join(' · ');
  }

  factory EtrnTitle.fromJson(Map<String, dynamic> json) {
    final code = normalizeEtrnCode(
      jsonText(json, ['code', 'title_code', 'kind', 'type', 'title']),
    );
    final signedAt = formatTripDate(
      json['signed_at'] ?? json['signedAt'] ?? json['date'],
    );
    final signedFlag = json['signed'];
    return EtrnTitle(
      code: code,
      name: jsonText(json, ['name', 'label', 'title_name']),
      signed: signedFlag == true || signedFlag == 1 || signedAt.isNotEmpty,
      signedAt: signedAt,
      signedBy: jsonText(json, ['signed_by', 'signer', 'company']),
    );
  }
}

String etrnTitleName(String code) {
  switch (code.toUpperCase()) {
    case 'T1':
      return 'Грузоотправитель';
    case 'T2':
      return 'Перевозчик, приём';
    case 'T3':
      return 'Грузополучатель';
    case 'T4':
      return 'Перевозчик, сдача';
    default:
      return code;
  }
}

String normalizeEtrnCode(String raw) {
  final value = raw.trim().toUpperCase();
  final match = RegExp(r'T\s*([1-4])').firstMatch(value);
  if (match != null) return 'T${match.group(1)}';
  final digit = RegExp(r'^[1-4]$').firstMatch(value);
  if (digit != null) return 'T${digit.group(0)}';
  return value;
}

List<EtrnTitle> parseEtrnTitles(Map<String, dynamic> json) {
  final nested = jsonMap(json, ['etrn', 'documents']);
  final maps = [
    ...jsonMaps(json, ['titles', 'etrn_titles', 'etrn']),
    if (nested != null) ...jsonMaps(nested, ['titles', 'items']),
  ];
  return maps
      .map(EtrnTitle.fromJson)
      .where((item) => item.code.isNotEmpty)
      .toList();
}

List<StatusEvent> parseStatusHistory(Map<String, dynamic> json) {
  final items = jsonMaps(json, ['status_history', 'history', 'events', 'timeline']);
  if (items.isNotEmpty) {
    return items
        .map(StatusEvent.fromJson)
        .where((item) => item.at.isNotEmpty || item.status.isNotEmpty)
        .toList();
  }
  final inferred = <StatusEvent>[];
  void add(String status, List<String> keys) {
    for (final key in keys) {
      final at = formatTripDate(json[key]);
      if (at.isEmpty) continue;
      inferred.add(StatusEvent(status: status, at: at));
      return;
    }
  }

  add('assigned', ['assigned_at', 'created_at']);
  add('loaded', ['loaded_at', 'loading_at']);
  add('in_transit', ['in_transit_at', 'started_at']);
  add('unloaded', ['unloaded_at']);
  add('delivered', ['delivered_at', 'completed_at']);
  return inferred;
}

String tripStatusChangedAt(Trip trip, String stepId) {
  String pick(List<String> keys) {
    for (final key in keys) {
      for (final event in trip.statusHistory) {
        if (event.at.isNotEmpty && event.matches(key)) return event.at;
      }
    }
    return '';
  }

  switch (stepId) {
    case 'assigned':
      return pick(['assigned', 'created', 'назнач']);
    case 'load':
      final loaded = pick(['loaded', 'loading', 'погруз']);
      if (loaded.isNotEmpty) return loaded;
      // Выезд с погрузки = переход «в пути»
      if (trip.isInTransit || trip.isCompleted) {
        return pick(['in_transit', 'started', 'пути', 'выехал']);
      }
      return '';
    case 'transit':
      return pick(['in_transit', 'started', 'пути', 'выехал']);
    case 'unload':
      final unloaded = pick(['unloaded', 'unloading', 'выгруз']);
      if (unloaded.isNotEmpty) return unloaded;
      if (trip.isCompleted) {
        return pick(['delivered', 'completed', 'достав']);
      }
      return '';
    case 'delivered':
      return pick(['delivered', 'completed', 'достав']);
    default:
      if (stepId.startsWith('stop_')) {
        final index = int.tryParse(stepId.substring(5));
        if (index != null && index >= 0 && index < trip.stops.length) {
          final stop = trip.stops[index];
          if (stop.isLoad) return tripStatusChangedAt(trip, 'load');
          if (stop.isUnload) return tripStatusChangedAt(trip, 'unload');
        }
      }
      return '';
  }
}

bool tripMatchesQuery(Trip trip, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  final haystack = [
    trip.number,
    '№${trip.number}',
    trip.from,
    trip.to,
    trip.startAddress,
    trip.finishAddress,
    trip.startCompany,
    trip.finishCompany,
    trip.dateStart,
    trip.dateEnd,
    trip.dateRange,
    trip.cargoLabel,
    for (final event in trip.statusHistory) event.at,
    for (final stop in trip.stops) ...[stop.title, stop.address],
    for (final item in trip.shipments) ...[
      item.title,
      item.from,
      item.to,
      item.fromAddress,
      item.toAddress,
    ],
  ].join(' · ').toLowerCase();
  return haystack.contains(needle);
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
  final List<EtrnTitle> titles;
  final String attorneyNumber;
  final String attorneyDate;
  final String attorneyUrl;

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
    this.titles = const [],
    this.attorneyNumber = '',
    this.attorneyDate = '',
    this.attorneyUrl = '',
  });

  bool get hasAttorney =>
      attorneyNumber.isNotEmpty || attorneyDate.isNotEmpty || attorneyUrl.isNotEmpty;

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
    final attorney = jsonMap(json, ['attorney', 'power_of_attorney']);
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
      titles: parseEtrnTitles(json),
      attorneyNumber: attorney == null
          ? jsonText(json, ['attorney_number'])
          : jsonText(attorney, ['number']),
      attorneyDate: attorney == null
          ? formatTripDate(json['attorney_date'])
          : formatTripDate(attorney['date'] ?? attorney['issued_at']),
      attorneyUrl: attorney == null
          ? jsonText(json, ['attorney_url'])
          : jsonText(attorney, ['url', 'file_url', 'download_url']),
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
  final String loadWindowFrom;
  final String loadWindowTo;
  final String unloadWindowFrom;
  final String unloadWindowTo;
  final num? distanceKm;
  final String dispatcherName;
  final String dispatcherPhone;
  final String attorneyNumber;
  final String attorneyDate;
  final String attorneyUrl;
  final List<StatusEvent> statusHistory;
  final List<EtrnTitle> etrnTitles;

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
    this.loadWindowFrom = '',
    this.loadWindowTo = '',
    this.unloadWindowFrom = '',
    this.unloadWindowTo = '',
    this.distanceKm,
    this.dispatcherName = '',
    this.dispatcherPhone = '',
    this.attorneyNumber = '',
    this.attorneyDate = '',
    this.attorneyUrl = '',
    this.statusHistory = const [],
    this.etrnTitles = const [],
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

  /// Куда вести навигацию с учётом статуса рейса.
  String get navigationLabel {
    if (canStart) return 'К погрузке';
    if (canDeliver) return 'К выгрузке';
    return 'Маршрут';
  }

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

  bool get hasAttorney =>
      attorneyNumber.isNotEmpty || attorneyDate.isNotEmpty || attorneyUrl.isNotEmpty;

  /// Доверенность с рейса или с первой поставки, где она есть.
  bool get hasAnyAttorney =>
      hasAttorney || shipments.any((item) => item.hasAttorney);

  String get resolvedAttorneyNumber {
    if (attorneyNumber.isNotEmpty) return attorneyNumber;
    for (final item in shipments) {
      if (item.attorneyNumber.isNotEmpty) return item.attorneyNumber;
    }
    return '';
  }

  String get resolvedAttorneyDate {
    if (attorneyDate.isNotEmpty) return attorneyDate;
    for (final item in shipments) {
      if (item.attorneyDate.isNotEmpty) return item.attorneyDate;
    }
    return '';
  }

  String get resolvedAttorneyUrl {
    if (attorneyUrl.isNotEmpty) return attorneyUrl;
    for (final item in shipments) {
      if (item.attorneyUrl.isNotEmpty) return item.attorneyUrl;
    }
    return '';
  }

  List<EtrnTitle> get allEtrnTitles {
    final byCode = <String, EtrnTitle>{};
    for (final title in etrnTitles) {
      if (title.code.isNotEmpty) byCode[title.code] = title;
    }
    for (final shipment in shipments) {
      for (final title in shipment.titles) {
        if (title.code.isEmpty) continue;
        final current = byCode[title.code];
        if (current == null || (!current.signed && title.signed)) {
          byCode[title.code] = title;
        }
      }
    }
    final order = ['T1', 'T2', 'T3', 'T4'];
    final sorted = byCode.values.toList()
      ..sort((a, b) {
        final ai = order.indexOf(a.code);
        final bi = order.indexOf(b.code);
        return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
      });
    return sorted;
  }

  String get loadWindowLabel => formatTimeWindow(loadWindowFrom, loadWindowTo);
  String get unloadWindowLabel => formatTimeWindow(unloadWindowFrom, unloadWindowTo);

  Trip copyWith({
    String? status,
    String? statusLabel,
    List<StatusEvent>? statusHistory,
  }) {
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
      loadWindowFrom: loadWindowFrom,
      loadWindowTo: loadWindowTo,
      unloadWindowFrom: unloadWindowFrom,
      unloadWindowTo: unloadWindowTo,
      distanceKm: distanceKm,
      dispatcherName: dispatcherName,
      dispatcherPhone: dispatcherPhone,
      attorneyNumber: attorneyNumber,
      attorneyDate: attorneyDate,
      attorneyUrl: attorneyUrl,
      statusHistory: statusHistory ?? this.statusHistory,
      etrnTitles: etrnTitles,
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
      loadWindowFrom: pick(loadWindowFrom, other.loadWindowFrom),
      loadWindowTo: pick(loadWindowTo, other.loadWindowTo),
      unloadWindowFrom: pick(unloadWindowFrom, other.unloadWindowFrom),
      unloadWindowTo: pick(unloadWindowTo, other.unloadWindowTo),
      distanceKm: distanceKm ?? other.distanceKm,
      dispatcherName: pick(dispatcherName, other.dispatcherName),
      dispatcherPhone: pick(dispatcherPhone, other.dispatcherPhone),
      attorneyNumber: pick(attorneyNumber, other.attorneyNumber),
      attorneyDate: pick(attorneyDate, other.attorneyDate),
      attorneyUrl: pick(attorneyUrl, other.attorneyUrl),
      statusHistory:
          statusHistory.isNotEmpty ? statusHistory : other.statusHistory,
      etrnTitles: etrnTitles.isNotEmpty ? etrnTitles : other.etrnTitles,
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
    final dispatcher = jsonMap(trip, ['dispatcher']);
    final attorney = jsonMap(trip, ['attorney', 'power_of_attorney']);

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
      loadWindowFrom: jsonText(trip, ['time_load_from', 'load_window_from']),
      loadWindowTo: jsonText(trip, ['time_load_to', 'load_window_to']),
      unloadWindowFrom: jsonText(trip, ['time_unload_from', 'unload_window_from']),
      unloadWindowTo: jsonText(trip, ['time_unload_to', 'unload_window_to']),
      distanceKm: jsonNumber(trip, ['distance_km', 'distance']),
      dispatcherName: dispatcher == null
          ? jsonText(trip, ['dispatcher_name'])
          : jsonText(dispatcher, ['name', 'full_name']),
      dispatcherPhone: dispatcher == null
          ? jsonText(trip, ['dispatcher_phone'])
          : jsonText(dispatcher, ['phone', 'mobile']),
      attorneyNumber: attorney == null
          ? jsonText(trip, ['attorney_number'])
          : jsonText(attorney, ['number']),
      attorneyDate: attorney == null
          ? formatTripDate(trip['attorney_date'])
          : formatTripDate(attorney['date'] ?? attorney['issued_at']),
      attorneyUrl: attorney == null
          ? jsonText(trip, ['attorney_url'])
          : jsonText(attorney, ['url', 'file_url', 'download_url']),
      statusHistory: parseStatusHistory(trip),
      etrnTitles: parseEtrnTitles(trip),
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

String formatTimeWindow(String from, String to) {
  if (from.isEmpty && to.isEmpty) return '';
  if (from.isNotEmpty && to.isNotEmpty) return '$from–$to';
  return from.isNotEmpty ? from : to;
}

DateTime? parseTripDateTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final iso = DateTime.tryParse(value);
  if (iso != null) return iso;
  final match = RegExp(
    r'^(\d{2})\.(\d{2})\.(\d{4})(?:\s+(\d{2}):(\d{2}))?',
  ).firstMatch(value);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
    int.parse(match.group(4) ?? '0'),
    int.parse(match.group(5) ?? '0'),
  );
}

double? haversineKm(double? lat1, double? lng1, double? lat2, double? lng2) {
  if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return null;
  const earth = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final sinLat = math.sin(dLat / 2);
  final sinLng = math.sin(dLng / 2);
  final h = sinLat * sinLat +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          sinLng *
          sinLng;
  return earth * 2 * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
}

num? tripDistanceKm(Trip trip) {
  if (trip.distanceKm != null) return trip.distanceKm;
  return haversineKm(trip.startLat, trip.startLng, trip.finishLat, trip.finishLng);
}

String formatDistanceKm(num? km) {
  if (km == null) return '';
  if (km >= 100) return '${km.round()} км';
  return '${_trimNum(num.parse(km.toStringAsFixed(1)))} км';
}

class TripDeadline {
  final String kind;
  final DateTime at;
  final bool late;
  final Duration delta;

  const TripDeadline({
    required this.kind,
    required this.at,
    required this.late,
    required this.delta,
  });

  String get headline {
    final label = kind == 'unload' ? 'выгрузки' : 'погрузки';
    if (late) return 'Опаздываете к $label на ${_formatDuration(delta)}';
    return 'До $label ${_formatDuration(delta)}';
  }
}

TripDeadline? tripDeadline(Trip trip, [DateTime? now]) {
  if (trip.isCompleted) return null;
  final clock = now ?? DateTime.now();
  final kind = trip.canStart ? 'load' : 'unload';
  final raw = trip.canStart ? trip.dateStart : trip.dateEnd;
  var at = parseTripDateTime(raw);
  if (at == null && trip.canStart && trip.loadWindowFrom.isNotEmpty) {
    at = _combineDateAndTime(trip.dateStart, trip.loadWindowFrom);
  }
  if (at == null && !trip.canStart && trip.unloadWindowFrom.isNotEmpty) {
    at = _combineDateAndTime(trip.dateEnd.isNotEmpty ? trip.dateEnd : trip.dateStart, trip.unloadWindowFrom);
  }
  if (at == null) return null;
  final late = clock.isAfter(at);
  return TripDeadline(
    kind: kind,
    at: at,
    late: late,
    delta: late ? clock.difference(at) : at.difference(clock),
  );
}

DateTime? _combineDateAndTime(String date, String time) {
  final parsed = parseTripDateTime(date);
  final parts = time.split(':');
  if (parts.length < 2) return parsed;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return parsed;
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day, hour, minute);
}

String _formatDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  if (hours > 48) {
    final days = (hours / 24).floor();
    return '$days д ${_formatHours(hours.remainder(24))}';
  }
  if (hours > 0) return '$hours ч $minutes мин';
  if (minutes > 0) return '$minutes мин';
  return 'меньше минуты';
}

String _formatHours(int hours) => hours > 0 ? '$hours ч' : '';
