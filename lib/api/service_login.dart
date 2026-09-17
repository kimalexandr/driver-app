import 'package:flutter/foundation.dart';

class ServiceLogin {
  static const code = '1111';

  static bool get enabled => kDebugMode;

  static bool matches(String value) => enabled && value == code;

  /// В debug: 1111 пускает (или подменяет на debug_code с сервера).
  /// В release служебный код отключён.
  static String resolve({required String entered, String? debugCode}) {
    if (!matches(entered)) return entered;
    if (debugCode != null && debugCode.trim().isNotEmpty) {
      return debugCode.trim();
    }
    return code;
  }
}
