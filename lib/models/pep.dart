import 'external_auth.dart';

class PepRecord {
  final String kid;
  final String driverId;
  final String thumbprint;
  final DateTime issuedAt;
  final AuthProviderKind issuedVia;
  final String algorithm;

  const PepRecord({
    required this.kid,
    required this.driverId,
    required this.thumbprint,
    required this.issuedAt,
    required this.issuedVia,
    this.algorithm = 'HMAC-SHA256',
  });

  String get issuedLabel {
    final dd = issuedAt.day.toString().padLeft(2, '0');
    final mm = issuedAt.month.toString().padLeft(2, '0');
    return '$dd.$mm.${issuedAt.year}';
  }

  Map<String, dynamic> toJson() => {
        'kid': kid,
        'driver_id': driverId,
        'thumbprint': thumbprint,
        'issued_at': issuedAt.toIso8601String(),
        'issued_via': issuedVia.id,
        'algorithm': algorithm,
      };

  factory PepRecord.fromJson(Map<String, dynamic> json) {
    return PepRecord(
      kid: '${json['kid'] ?? ''}',
      driverId: '${json['driver_id'] ?? ''}',
      thumbprint: '${json['thumbprint'] ?? ''}',
      issuedAt: DateTime.tryParse('${json['issued_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      issuedVia:
          AuthProviderKind.tryParse('${json['issued_via']}') ?? AuthProviderKind.sms,
      algorithm: '${json['algorithm'] ?? 'HMAC-SHA256'}',
    );
  }
}

class PepSignature {
  final String kid;
  final String payload;
  final String signature;
  final DateTime signedAt;
  final String algorithm;

  const PepSignature({
    required this.kid,
    required this.payload,
    required this.signature,
    required this.signedAt,
    this.algorithm = 'HMAC-SHA256',
  });

  Map<String, dynamic> toJson() => {
        'kid': kid,
        'payload': payload,
        'signature': signature,
        'signed_at': signedAt.toIso8601String(),
        'algorithm': algorithm,
        'method': 'pep',
      };
}
