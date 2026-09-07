class OtpChallenge {
  final String requestId;
  final String phone;
  final int expiresIn;
  final int? retryAfter;

  const OtpChallenge({
    required this.requestId,
    required this.phone,
    this.expiresIn = 300,
    this.retryAfter,
  });

  factory OtpChallenge.fromJson(Map<String, dynamic> json, String phone) {
    return OtpChallenge(
      requestId: '${json['request_id']}',
      phone: phone,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 300,
      retryAfter: (json['retry_after'] as num?)?.toInt(),
    );
  }
}
