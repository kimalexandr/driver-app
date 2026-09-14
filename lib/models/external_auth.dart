class OfficialAuthLinks {
  static const gosuslugi = 'https://www.gosuslugi.ru/';
  static const goskey = 'https://www.gosuslugi.ru/goskey';

  /// Цифровой ID в мессенджере MAX (права / СТС / документы через Госуслуги).
  static const maxDigitalId = 'https://max.ru/digitalid_bot';
  static const maxDigitalIdGuide = 'https://go.max.ru/digitalId';
}

enum AuthProviderKind {
  sms,
  gosuslugi,
  goskey;

  String get id => name;

  String get title {
    switch (this) {
      case AuthProviderKind.sms:
        return 'Телефон';
      case AuthProviderKind.gosuslugi:
        return 'Госуслуги';
      case AuthProviderKind.goskey:
        return 'Госключ';
    }
  }

  static AuthProviderKind? tryParse(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'sms':
      case 'phone':
        return AuthProviderKind.sms;
      case 'gosuslugi':
      case 'esia':
        return AuthProviderKind.gosuslugi;
      case 'goskey':
      case 'gosuslugi_key':
        return AuthProviderKind.goskey;
      default:
        return null;
    }
  }
}

class ExternalAuthStart {
  final String provider;
  final String state;
  final String? authorizeUrl;
  final bool demo;
  final String? demoCode;

  const ExternalAuthStart({
    required this.provider,
    required this.state,
    this.authorizeUrl,
    this.demo = false,
    this.demoCode,
  });

  factory ExternalAuthStart.fromJson(Map<String, dynamic> json) {
    return ExternalAuthStart(
      provider: '${json['provider'] ?? ''}',
      state: '${json['state'] ?? ''}',
      authorizeUrl: json['authorize_url'] == null
          ? null
          : '${json['authorize_url']}',
      demo: json['demo'] == true,
      demoCode: json['demo_code'] == null ? null : '${json['demo_code']}',
    );
  }
}
