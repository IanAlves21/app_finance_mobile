import 'package:flutter/foundation.dart';

class LoginViewModel extends ChangeNotifier {
  String _email = '';
  String _password = '';
  bool _showPassword = false;
  bool _loading = false;
  String? _focusedField;

  String get email => _email;
  String get password => _password;
  bool get showPassword => _showPassword;
  bool get loading => _loading;
  String? get focusedField => _focusedField;

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void toggleShowPassword() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  void setFocusedField(String? value) {
    _focusedField = value;
    notifyListeners();
  }

  Future<void> submitLogin(VoidCallback onSuccess) async {
    _loading = true;
    notifyListeners();

    // 1200ms simulated network timeout delay
    await Future.delayed(const Duration(milliseconds: 1200));

    _loading = false;
    notifyListeners();
    onSuccess();
  }
}
