import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../api/driver_api.dart';
import '../api/token_store.dart';
import '../models/auth_session.dart';
import '../models/driver_profile.dart';

class AuthController extends ChangeNotifier {
  final DriverApi api;
  final TokenStore tokenStore;

  AuthController({
    required this.api,
    required this.tokenStore,
  });

  DriverProfile? driver;
  bool ready = false;

  bool get isLoggedIn => driver != null;

  Future<void> restore() async {
    final token = await tokenStore.accessToken;
    if (token != null && token.isNotEmpty) {
      try {
        driver = await api.me();
      } on ApiException catch (error) {
        if (error.isUnauthorized) {
          driver = null;
        } else {
          driver = const DriverProfile(id: '', name: '');
        }
      } catch (_) {
        driver = const DriverProfile(id: '', name: '');
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> applySession(AuthSession session) async {
    await tokenStore.saveAccessToken(session.accessToken);
    driver = session.driver;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    driver = await api.me();
    notifyListeners();
  }

  Future<void> logout() async {
    await tokenStore.clear();
    driver = null;
    notifyListeners();
  }

  Future<void> onUnauthorized() async {
    await tokenStore.clear();
    driver = null;
    notifyListeners();
  }
}
