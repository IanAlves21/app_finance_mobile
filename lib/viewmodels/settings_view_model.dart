import 'package:flutter/material.dart';

import '../main.dart'; // import global themeNotifier & localeNotifier

class SettingsViewModel extends ChangeNotifier {
  bool _darkMode = themeNotifier.value == ThemeMode.dark;
  bool _isEnglish = localeNotifier.value.languageCode == 'en';
  bool _pushNotifications = true;
  bool _biometricAuth = false;

  bool get darkMode => _darkMode;
  bool get isEnglish => _isEnglish;
  bool get pushNotifications => _pushNotifications;
  bool get biometricAuth => _biometricAuth;

  void toggleDarkMode(bool value) {
    _darkMode = value;
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleLanguage(bool value) {
    _isEnglish = value;
    localeNotifier.value = value ? const Locale('en') : const Locale('pt');
    notifyListeners();
  }

  void togglePushNotifications(bool value) {
    _pushNotifications = value;
    notifyListeners();
  }

  void toggleBiometricAuth(bool value) {
    _biometricAuth = value;
    notifyListeners();
  }
}
