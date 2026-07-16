import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/secure_storage_manager.dart';

class LoginViewModel extends ChangeNotifier {
  final ApiService _apiService;

  LoginViewModel({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  String _email = '';
  String _password = '';
  bool _showPassword = false;
  bool _loading = false;
  String? _focusedField;
  String? _errorMessage;

  String get email => _email;
  String get password => _password;
  bool get showPassword => _showPassword;
  bool get loading => _loading;
  String? get focusedField => _focusedField;
  String? get errorMessage => _errorMessage;

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

  Future<void> submitLogin({
    required VoidCallback onSuccess,
    required ValueChanged<String> onError,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.login(_email, _password);

      final String accessToken = data['access_token'] as String;
      final Map<String, dynamic> userJson = data['user'] as Map<String, dynamic>;
      final userObj = User.fromJson(userJson);

      final prefs = await SharedPreferences.getInstance();
      await SecureStorageManager.writeToken(accessToken);
      await prefs.setString('user_id', userObj.id);
      await prefs.setString('user_name', userObj.name);
      await prefs.setString('user_email', userObj.email);
      await prefs.setBool('is_logged_in', true);

      currentUserNotifier.value = userObj;

      _loading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _loading = false;
      _errorMessage = e.toString().replaceAll('HttpException: ', '');
      notifyListeners();
      onError(_errorMessage!);
    }
  }
}
