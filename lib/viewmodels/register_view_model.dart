import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class RegisterViewModel extends ChangeNotifier {
  final ApiService _apiService;

  RegisterViewModel({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _loading = false;
  String? _focusedField;
  String? _errorMessage;

  String get name => _name;
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  bool get showPassword => _showPassword;
  bool get showConfirmPassword => _showConfirmPassword;
  bool get loading => _loading;
  String? get focusedField => _focusedField;
  String? get errorMessage => _errorMessage;

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }

  void toggleShowPassword() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  void toggleShowConfirmPassword() {
    _showConfirmPassword = !_showConfirmPassword;
    notifyListeners();
  }

  void setFocusedField(String? value) {
    _focusedField = value;
    notifyListeners();
  }

  Future<void> submitRegister({
    required VoidCallback onSuccess,
    required ValueChanged<String> onError,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.register(_name, _email, _password);
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
