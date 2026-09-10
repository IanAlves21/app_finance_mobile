import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';
import '../services/secure_storage_manager.dart';

class ChatRepository {
  final ApiService _apiService;

  ChatRepository({required this._apiService});

  /// Envia a mensagem do usuário para o assistente de IA processar
  Future<Map<String, dynamic>> sendMessage(String message) async {
    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    try {
      final response = await _apiService
          .post('/chat/message', {'message': message})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException(
          'Falha ao obter resposta da IA: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is HttpException) {
        rethrow;
      }
      throw HttpException('Erro de rede ao falar com o assistente: $e');
    }
  }
}
