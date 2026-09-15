class NotificationPrefs {
  final bool enabled;
  final bool newTrips;
  final bool statusChanges;
  final bool dispatcher;
  final bool deadlines;

  const NotificationPrefs({
    this.enabled = true,
    this.newTrips = true,
    this.statusChanges = true,
    this.dispatcher = true,
    this.deadlines = true,
  });

  static const defaults = NotificationPrefs();

  NotificationPrefs copyWith({
    bool? enabled,
    bool? newTrips,
    bool? statusChanges,
    bool? dispatcher,
    bool? deadlines,
  }) {
    return NotificationPrefs(
      enabled: enabled ?? this.enabled,
      newTrips: newTrips ?? this.newTrips,
      statusChanges: statusChanges ?? this.statusChanges,
      dispatcher: dispatcher ?? this.dispatcher,
      deadlines: deadlines ?? this.deadlines,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'new_trips': newTrips,
        'status_changes': statusChanges,
        'dispatcher': dispatcher,
        'deadlines': deadlines,
      };

  factory NotificationPrefs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    bool flag(String key, {bool fallback = true}) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == '1' || normalized == 'true') return true;
        if (normalized == '0' || normalized == 'false') return false;
      }
      return fallback;
    }

    return NotificationPrefs(
      enabled: flag('enabled'),
      newTrips: flag('new_trips'),
      statusChanges: flag('status_changes'),
      dispatcher: flag('dispatcher'),
      deadlines: flag('deadlines'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationPrefs &&
        other.enabled == enabled &&
        other.newTrips == newTrips &&
        other.statusChanges == statusChanges &&
        other.dispatcher == dispatcher &&
        other.deadlines == deadlines;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        newTrips,
        statusChanges,
        dispatcher,
        deadlines,
      );
}
