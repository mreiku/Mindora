import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';

import '../backend/auth_service.dart';

final appThemeStateNotifier = ChangeNotifierProvider(
  (ref) => appThemeState()
);

class appThemeState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  var isDarkModeEnabled = false;

  Future<void> setLightTheme() async {
    isDarkModeEnabled = false;
    await _authService.updateDarkModePreference(false);
    notifyListeners();
  }

  Future<void> setDarkTheme() async {
    isDarkModeEnabled = true;
    await _authService.updateDarkModePreference(true);
    notifyListeners();
  }

  Future<void> loadThemeForCurrentUser() async {
    isDarkModeEnabled = await _authService.getCurrentUserDarkModePreference();
    notifyListeners();
  }

  void resetToLightTheme() {
    isDarkModeEnabled = false;
    notifyListeners();
  }
}

