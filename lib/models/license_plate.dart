class RuLicensePlate {
  final String letter;
  final String digits;
  final String series;
  final String region;
  final String raw;
  final bool parsed;

  const RuLicensePlate({
    required this.letter,
    required this.digits,
    required this.series,
    required this.region,
    required this.raw,
    required this.parsed,
  });

  String get compact => parsed ? '$letter$digits$series$region' : raw;
}

const _latinToCyr = {
  'A': 'А',
  'B': 'В',
  'C': 'С',
  'E': 'Е',
  'H': 'Н',
  'K': 'К',
  'M': 'М',
  'O': 'О',
  'P': 'Р',
  'T': 'Т',
  'X': 'Х',
  'Y': 'У',
};

final _plateRe = RegExp(
  r'^([АВЕКМНОРСТУХ])(\d{3})([АВЕКМНОРСТУХ]{2})(\d{2,3})$',
);

String normalizePlateLetters(String value) {
  final buffer = StringBuffer();
  for (final rune in value.toUpperCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_latinToCyr[char] ?? char);
  }
  return buffer.toString();
}

RuLicensePlate parseRuLicensePlate(String raw) {
  final trimmed = raw.trim();
  final compact = normalizePlateLetters(trimmed).replaceAll(RegExp(r'[\s.\-·]'), '');
  final match = _plateRe.firstMatch(compact);
  if (match == null) {
    return RuLicensePlate(
      letter: '',
      digits: '',
      series: '',
      region: '',
      raw: trimmed,
      parsed: false,
    );
  }
  return RuLicensePlate(
    letter: match.group(1)!,
    digits: match.group(2)!,
    series: match.group(3)!,
    region: match.group(4)!,
    raw: trimmed,
    parsed: true,
  );
}
