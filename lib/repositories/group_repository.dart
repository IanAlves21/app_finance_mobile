import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/secure_storage_manager.dart';

class GroupRepository {
  final ApiService _apiService;

  GroupRepository({required ApiService apiService}) : _apiService = apiService;

  /// Busca informações sobre o grupo familiar atual e seus membros
  Future<Map<String, dynamic>> fetchGroupInfo() async {
    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    try {
      final response = await _apiService
          .get('/groups/info')
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException('Falha ao buscar informações do grupo: ${response.statusCode}');
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de conexão ao buscar grupo: $e');
    }
  }

  /// Gera um convite (código/token) para o grupo familiar atual
  Future<Map<String, dynamic>> createInvite() async {
    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    try {
      final response = await _apiService
          .post('/groups/invite', {})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException('Falha ao gerar convite: ${response.statusCode}');
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de conexão ao gerar convite: $e');
    }
  }

  /// Busca os detalhes de um convite a partir de seu código curto
  Future<Map<String, dynamic>> fetchInviteDetails(String code) async {
    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    try {
      final response = await _apiService
          .get('/groups/invite/$code')
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException('Falha ao buscar detalhes do convite: ${response.statusCode}');
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de conexão ao buscar convite: $e');
    }
  }

  /// Aceita o convite e integra o grupo correspondente
  Future<Map<String, dynamic>> acceptInvite(String code) async {
    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    try {
      final response = await _apiService
          .post('/groups/invite/$code/accept', {})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException('Falha ao aceitar convite: ${response.statusCode}');
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de conexão ao aceitar convite: $e');
    }
  }

  /// Sai do grupo familiar atual e volta para um grupo individual
  Future<Map<String, dynamic>> leaveGroup() async {
    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    try {
      final response = await _apiService
          .post('/groups/leave', {})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        try {
          final body = json.decode(response.body);
          final String message = body['message'] ?? 'Falha ao sair do grupo';
          throw HttpException(message);
        } catch (_) {
          throw HttpException('Falha ao sair do grupo: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Erro de conexão ao sair do grupo: $e');
    }
  }
}
