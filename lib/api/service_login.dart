class ServiceLogin {
  static const code = '1111';

  static bool matches(String value) => value == code;

  /// Пока SMS может не приходить: 1111 пускает любого водителя,
  /// которому уже выписали код. Если сервер отдал debug_code — уходит он.
  static String resolve({required String entered, String? debugCode}) {
    if (!matches(entered)) return entered;
    if (debugCode != null && debugCode.trim().isNotEmpty) {
      return debugCode.trim();
    }
    return code;
  }
}
