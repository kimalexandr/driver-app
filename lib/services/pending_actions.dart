import 'dart:convert';

import 'secure_kv.dart';

enum PendingActionType { status, photo, location }

class PendingAction {
  final String id;
  final PendingActionType type;
  final String tripId;
  final String? status;
  final String? filePath;
  final double? lat;
  final double? lng;

  const PendingAction({
    required this.id,
    required this.type,
    required this.tripId,
    this.status,
    this.filePath,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'tripId': tripId,
        if (status != null) 'status': status,
        if (filePath != null) 'filePath': filePath,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      id: '${json['id']}',
      type: PendingActionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => PendingActionType.status,
      ),
      tripId: '${json['tripId']}',
      status: json['status']?.toString(),
      filePath: json['filePath']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}

/// Локальная очередь действий при плохой сети.
class PendingActionsQueue {
  static const _key = 'driver.pending_actions.v1';

  final SecureKv _kv;

  PendingActionsQueue({SecureKv? kv}) : _kv = kv ?? FlutterSecureKv();

  Future<List<PendingAction>> list() async {
    final raw = await _kv.read(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => PendingAction.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> enqueue(PendingAction action) async {
    final items = List<PendingAction>.from(await list());
    items.removeWhere((item) => item.id == action.id);
    items.add(action);
    await _save(items);
  }

  Future<void> remove(String id) async {
    final items = List<PendingAction>.from(await list());
    items.removeWhere((item) => item.id == id);
    await _save(items);
  }

  Future<List<PendingAction>> forTrip(String tripId) async {
    return (await list()).where((item) => item.tripId == tripId).toList();
  }

  Future<void> _save(List<PendingAction> items) async {
    if (items.isEmpty) {
      await _kv.delete(_key);
      return;
    }
    await _kv.write(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
