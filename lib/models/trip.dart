class Shipment {
  final String id;
  final String title;

  const Shipment({
    required this.id,
    required this.title,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    final title = json['number'] ??
        json['name'] ??
        json['title'] ??
        json['cargo'] ??
        json['description'] ??
        json['id'] ??
        '';
    return Shipment(
      id: '${json['id'] ?? title}',
      title: '$title',
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
    this.shipments = const [],
  });

  bool get canStart => status == 'created' || status == 'assigned';
  bool get canDeliver => status == 'in_transit';
  bool get isInTransit => status == 'in_transit';

  factory Trip.fromJson(Map<String, dynamic> json) {
    final shipmentsRaw = json['shipments'];
    return Trip(
      id: '${json['id']}',
      number: '${json['number'] ?? json['id']}',
      status: '${json['status'] ?? ''}',
      statusLabel: '${json['status_label'] ?? _labelFor(json['status'])}',
      from: '${json['from'] ?? ''}',
      to: '${json['to'] ?? ''}',
      dateStart: _formatDate(json['date_start']),
      vehicle: _vehicle(json['vehicle']),
      startAddress: '${json['start_address'] ?? ''}',
      finishAddress: '${json['finish_address'] ?? ''}',
      shipments: shipmentsRaw is List
          ? shipmentsRaw
              .whereType<Map>()
              .map((item) => Shipment.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
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
