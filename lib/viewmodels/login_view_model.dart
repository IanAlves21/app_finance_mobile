import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/secure_storage_manager.dart';

class LoginViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final GoogleSignIn _googleSignIn;

  LoginViewModel({ApiService? apiService, GoogleSignIn? googleSignIn})
    : _apiService = apiService ?? ApiService(),
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

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
      final Map<String, dynamic> userJson =
          data['user'] as Map<String, dynamic>;
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

  Future<void> submitGoogleLogin({
    required VoidCallback onSuccess,
    required ValueChanged<String> onError,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = _googleSignIn;

      // Inicializa o seletor (necessário no google_sign_in v7+)
      try {
        await googleSignIn.initialize(
          serverClientId: ApiService.googleServerClientId.isNotEmpty
              ? ApiService.googleServerClientId
              : null,
        );
      } catch (_) {}

      // Sempre desloga para garantir que o seletor de contas do Google apareça
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      // Abre o seletor de contas do Google usando o authenticate() nativo
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        // Usuário cancelou o login manualmente
        _loading = false;
        notifyListeners();
        return;
      }

      // No google_sign_in v7+, acessar a autenticação é um método síncrono (sem await)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Não foi possível obter o ID Token do Google');
      }

      // Envia o idToken oficial para validação no backend
      final data = await _apiService.loginGoogle(idToken);

      final String accessToken = data['access_token'] as String;
      final Map<String, dynamic> userJson =
          data['user'] as Map<String, dynamic>;
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
