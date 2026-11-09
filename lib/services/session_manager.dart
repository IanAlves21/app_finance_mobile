import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_manager.dart';
import '../main.dart';

class SessionManager {
  /// Centraliza o encerramento de sessão, limpando os dados de usuário e cache,
  /// mas preservando as preferências de configuração (biometria, tema, idioma)
  /// e atualizando reativamente os Notifiers globais da interface.
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Salva as configurações de preferência do usuário que devem persistir
      final bool? biometricAuth = prefs.getBool('biometric_auth');
      final String? themeMode = prefs.getString('theme_mode');
      final bool? pushNotifications = prefs.getBool('push_notifications');
      final String? languageCode = prefs.getString('language_code');

      await prefs.clear(); // Limpa dados da sessão, cache de transações e pendências

      // Restaura as configurações
      if (biometricAuth != null) {
        await prefs.setBool('biometric_auth', biometricAuth);
      }
      if (themeMode != null) {
        await prefs.setString('theme_mode', themeMode);
      }
      if (pushNotifications != null) {
        await prefs.setBool('push_notifications', pushNotifications);
      }
      if (languageCode != null) {
        await prefs.setString('language_code', languageCode);
      }

      await SecureStorageManager.deleteToken(); // Remove o JWT de forma segura
    } catch (e) {
      debugPrint('Erro ao encerrar sessão: $e');
    }

    // Atualiza reativamente os Notifiers da UI em um único local centralizado
    currentUserNotifier.value = null;
    isLoggedInNotifier.value = false;
  }
}
