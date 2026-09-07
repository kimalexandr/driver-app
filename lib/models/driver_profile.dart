class DriverProfile {
  final String id;
  final String name;
  final String phone;

  const DriverProfile({
    required this.id,
    required this.name,
    this.phone = '',
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final nested = json['driver'];
    final source = nested is Map ? Map<String, dynamic>.from(nested) : json;
    return DriverProfile(
      id: '${source['id'] ?? ''}',
      name: '${source['name'] ?? source['full_name'] ?? ''}',
      phone: '${source['phone'] ?? source['mobile_phone'] ?? ''}',
    );
  }
}
