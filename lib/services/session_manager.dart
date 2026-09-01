import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_manager.dart';
import '../main.dart';

class SessionManager {
  /// Centraliza o encerramento de sessão, limpando o armazenamento local
  /// e atualizando reativamente os Notifiers globais da interface.
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Limpa completamente o cache local (transações, categorias, pendências e sessão)
      await SecureStorageManager.deleteToken(); // Remove o JWT de forma segura
    } catch (e) {
      debugPrint('Erro ao encerrar sessão: $e');
    }

    // Atualiza reativamente os Notifiers da UI em um único local centralizado
    currentUserNotifier.value = null;
    isLoggedInNotifier.value = false;
  }
}
