String normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    digits = '7$digits';
  } else if (digits.length == 11 && digits.startsWith('8')) {
    digits = '7${digits.substring(1)}';
  }
  return digits;
}

String ruPhoneLocalDigits(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if ((digits.startsWith('7') || digits.startsWith('8')) && digits.length >= 11) {
    digits = digits.substring(1);
  }
  if (digits.length > 10) digits = digits.substring(0, 10);
  return digits;
}

String formatRuPhoneLocal(String raw) {
  final digits = ruPhoneLocalDigits(raw);
  if (digits.isEmpty) return '';
  final buffer = StringBuffer('(');
  buffer.write(digits.substring(0, digits.length.clamp(0, 3)));
  if (digits.length < 3) return buffer.toString();
  buffer.write(') ');
  if (digits.length == 3) return buffer.toString();
  buffer.write(digits.substring(3, digits.length.clamp(3, 6)));
  if (digits.length <= 6) return buffer.toString();
  buffer.write('-');
  buffer.write(digits.substring(6, digits.length.clamp(6, 8)));
  if (digits.length <= 8) return buffer.toString();
  buffer.write('-');
  buffer.write(digits.substring(8, digits.length.clamp(8, 10)));
  return buffer.toString();
}

String formatRuPhonePretty(String raw) {
  const template = '+7 (___) ___-__-__';
  final digits = ruPhoneLocalDigits(raw);
  final chars = template.split('');
  var index = 0;
  for (var i = 0; i < chars.length; i++) {
    if (chars[i] != '_' || index >= digits.length) continue;
    chars[i] = digits[index];
    index += 1;
  }
  return chars.join();
}
