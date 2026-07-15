import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SessionManager {
  /// Centraliza o encerramento de sessão, limpando o armazenamento local
  /// e atualizando reativamente os Notifiers globais da interface.
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('access_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
    } catch (e) {
      debugPrint('Erro ao encerrar sessão: $e');
    }
    
    // Atualiza reativamente os Notifiers da UI em um único local centralizado
    currentUserNotifier.value = null;
    isLoggedInNotifier.value = false;
  }
}
