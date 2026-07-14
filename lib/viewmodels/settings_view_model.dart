import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('access_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
    } catch (e) {
      debugPrint('Error clearing persistent session: $e');
    }
    currentUserNotifier.value = null;
    isLoggedInNotifier.value = false;
  }
}
