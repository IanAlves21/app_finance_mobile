import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'access_token';

  static String? mockToken;
  static bool useMock = false;

  /// Escreve de forma criptografada o JWT token no armazenamento seguro
  static Future<void> writeToken(String token) async {
    if (useMock) {
      mockToken = token;
      return;
    }
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('Erro ao escrever token seguro: $e');
    }
  }

  /// Lê de forma segura o JWT token
  static Future<String?> readToken() async {
    if (useMock) {
      return mockToken;
    }
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Erro ao ler token seguro: $e');
      return null;
    }
  }

  /// Remove de forma segura o JWT token do chaveiro de criptografia
  static Future<void> deleteToken() async {
    if (useMock) {
      mockToken = null;
      return;
    }
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('Erro ao remover token seguro: $e');
    }
  }
}
