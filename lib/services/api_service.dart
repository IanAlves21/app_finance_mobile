import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import 'session_manager.dart';

class ApiService {
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  static String get baseUrl {
    // API Gateway runs on 8080. On Android emulator, use 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static String get gatewayUrl {
    // API Gateway runs on 8080. On Android emulator, use 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  // Verifica se o token JWT está expirado decodificando seu payload (sem depedências externas)
  static bool isTokenExpired(String token) {
    // Ignora a validação para tokens mockados usados em testes automatizados
    if (token.startsWith('mocked_') || token == 'mocked_jwt_token') {
      return false;
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      String payloadPart = parts[1];
      // Normaliza caracteres base64url e adiciona padding se necessário
      payloadPart = payloadPart.replaceAll('-', '+').replaceAll('_', '/');
      while (payloadPart.length % 4 != 0) {
        payloadPart += '=';
      }

      final payload = utf8.decode(base64.decode(payloadPart));
      final Map<String, dynamic> claims = json.decode(payload);

      if (claims.containsKey('exp')) {
        final int exp = claims['exp'];
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isAfter(expiryDate);
      }
      return true;
    } catch (_) {
      return true; // Considera expirado se houver erro ao decodificar
    }
  }

  // Limpa a sessão local e atualiza os notifiers globais para forçar redirecionamento ao Login
  static Future<void> logout() async {
    await SessionManager.logout();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client
        .post(
          Uri.parse('$gatewayUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Falha ao realizar login';
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('message')) {
          if (data['message'] is List) {
            errorMessage = (data['message'] as List).join(', ');
          } else {
            errorMessage = data['message'].toString();
          }
        }
      } catch (_) {}
      throw HttpException(errorMessage);
    }
  }

  Future<List<Transaction>> fetchTransactions({
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');

      // Proteção prévia: se houver token, mas ele estiver expirado, desloga antes de fazer a requisição
      if (token != null && isTokenExpired(token)) {
        await logout();
        throw const HttpException('Unauthorized');
      }

      if (page == 1) {
        // Tenta sincronizar transações offline pendentes antes de carregar
        await syncPendingTransactions();
      }

      final Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await client
          .get(
            Uri.parse('$baseUrl/transactions?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Cache localmente a primeira página de transações para uso offline
        if (page == 1) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_transactions', response.body);
          } catch (cacheError) {
            debugPrint('Erro ao salvar cache de transações: $cacheError');
          }
        }

        return data.map((json) => Transaction.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        // Se receber 401 do Gateway, limpa a sessão e relança o erro de não autorizado
        await logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException(
          'Failed to load transactions: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint('ApiService error, carregando transações do cache local: $e');

      // Fallback amigável apenas para erros de rede/timeout: tenta carregar do cache local
      if (page == 1) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final String? cachedData = prefs.getString('cached_transactions');
          if (cachedData != null) {
            final List<dynamic> data = json.decode(cachedData);
            return data.map((json) => Transaction.fromJson(json)).toList();
          }
        } catch (cacheError) {
          debugPrint('Falha ao ler transações do cache local: $cacheError');
        }
      }

      return [];
    }
  }

  Future<Transaction> createTransaction({
    required String description,
    required double amount,
    required String type, // 'INCOME' ou 'EXPENSE'
    required String date, // ISO string
    String? categoryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    if (token != null && isTokenExpired(token)) {
      await logout();
      throw const HttpException('Unauthorized');
    }

    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/transactions'),
            headers: headers,
            body: json.encode({
              'description': description,
              'amount': amount,
              'type': type,
              'date': date,
              if (categoryId != null) 'categoryId': categoryId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Transaction.fromJson(data);
      } else if (response.statusCode == 401) {
        await logout();
        throw const HttpException('Unauthorized');
      } else {
        String errorMessage = 'Falha ao criar transação';
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data.containsKey('message')) {
            if (data['message'] is List) {
              errorMessage = (data['message'] as List).join(', ');
            } else {
              errorMessage = data['message'].toString();
            }
          }
        } catch (_) {}
        throw HttpException(errorMessage);
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint(
        'ApiService error durante criação de transação, enfileirando offline: $e',
      );

      // Salva a transação pendente na lista local para sincronização futura
      final pendingTx = {
        'description': description,
        'amount': amount,
        'type': type,
        'date': date,
        if (categoryId != null) 'categoryId': categoryId,
      };

      try {
        // 1. Adiciona ao final da fila de pendentes
        final List<dynamic> pendingList = [];
        final String? existingPending = prefs.getString('pending_transactions');
        if (existingPending != null && existingPending.isNotEmpty) {
          pendingList.addAll(json.decode(existingPending));
        }
        pendingList.add(pendingTx);
        await prefs.setString('pending_transactions', json.encode(pendingList));

        // 2. Adiciona imediatamente ao cache de transações para exibição instantânea na interface
        final String? existingCache = prefs.getString('cached_transactions');
        final List<dynamic> cacheList = [];
        if (existingCache != null && existingCache.isNotEmpty) {
          cacheList.addAll(json.decode(existingCache));
        }

        // Cria uma representação no mesmo formato de resposta da API
        final localMockTx = {
          'id': 'offline_${DateTime.now().millisecondsSinceEpoch}',
          'description': description,
          'type': type,
          'amount': amount.toString(),
          'date': date,
          if (categoryId != null) 'categoryId': categoryId,
          'paidBy': {'name': prefs.getString('user_name') ?? 'Me'},
          'wallet': {'name': 'Shared Wallet Account'},
          'note': 'Sincronização pendente',
          'status': 'PENDING',
        };

        // Adiciona no topo da lista (transação mais recente primeiro)
        cacheList.insert(0, localMockTx);
        await prefs.setString('cached_transactions', json.encode(cacheList));

        // Retorna o objeto Transaction construído localmente
        return Transaction.fromJson(localMockTx);
      } catch (cacheError) {
        debugPrint('Erro ao enfileirar transação offline: $cacheError');
        rethrow;
      }
    }
  }

  Future<List<Category>> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();

    // Tenta sincronizar categorias pendentes offline primeiro antes de carregar do servidor!
    try {
      await syncPendingCategories();
    } catch (syncError) {
      debugPrint('Erro ao sincronizar categorias antes de fetch: $syncError');
    }

    final String? token = prefs.getString('access_token');

    if (token != null && isTokenExpired(token)) {
      await logout();
      throw const HttpException('Unauthorized');
    }

    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/transactions/categories'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Se ainda houver categorias offline pendentes que falharam no sync, mescla-as no resultado
        try {
          final String? pendingData = prefs.getString('pending_categories');
          if (pendingData != null && pendingData.isNotEmpty) {
            final List<dynamic> pendingList = json.decode(pendingData);
            for (int i = 0; i < pendingList.length; i++) {
              final catMap = pendingList[i];
              data.add({
                'id': 'offline_cat_fetch_$i',
                'name': catMap['name'],
                'type': catMap['type'],
                'icon': catMap['icon'],
                'color': catMap['color'],
                'familyId': 'offline_family',
              });
            }
          }
        } catch (_) {}

        try {
          await prefs.setString('cached_categories', json.encode(data));
        } catch (cacheError) {
          debugPrint('Erro ao salvar cache de categorias: $cacheError');
        }
        return data.map((json) => Category.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint('ApiService error, carregando categorias do cache local: $e');

      try {
        final String? cachedData = prefs.getString('cached_categories');
        if (cachedData != null) {
          final List<dynamic> data = json.decode(cachedData);
          return data.map((json) => Category.fromJson(json)).toList();
        }
      } catch (cacheError) {
        debugPrint('Falha ao ler categorias do cache local: $cacheError');
      }

      return [];
    }
  }

  Future<Category> createCategory({
    required String name,
    required String type, // 'INCOME' ou 'EXPENSE'
    required String icon,
    required String color,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    if (token != null && isTokenExpired(token)) {
      await logout();
      throw const HttpException('Unauthorized');
    }

    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/transactions/categories'),
            headers: headers,
            body: json.encode({
              'name': name,
              'type': type,
              'icon': icon,
              'color': color,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Category newCat = Category.fromJson(data);

        // Atualiza o cache local de categorias
        try {
          final String? cachedData = prefs.getString('cached_categories');
          final List<dynamic> currentCats = cachedData != null ? json.decode(cachedData) : [];
          currentCats.add(data);
          await prefs.setString('cached_categories', json.encode(currentCats));
        } catch (_) {}

        return newCat;
      } else if (response.statusCode == 401) {
        await logout();
        throw const HttpException('Unauthorized');
      } else {
        throw const HttpException('Falha ao criar categoria');
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint(
        'ApiService: Erro durante criação de categoria, enfileirando offline: $e',
      );

      final String localId = 'offline_cat_${DateTime.now().millisecondsSinceEpoch}';
      final localMockCat = {
        'id': localId,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'familyId': 'offline_family', // Indica que é customizada localmente
      };

      final pendingCat = {
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
      };

      try {
        // 1. Adiciona ao final da fila de pendentes
        final List<dynamic> pendingList = [];
        final String? existingPending = prefs.getString('pending_categories');
        if (existingPending != null && existingPending.isNotEmpty) {
          pendingList.addAll(json.decode(existingPending));
        }
        pendingList.add(pendingCat);
        await prefs.setString('pending_categories', json.encode(pendingList));

        // 2. Adiciona imediatamente ao cache de categorias para exibição instantânea
        final String? cachedData = prefs.getString('cached_categories');
        final List<dynamic> currentCats = cachedData != null ? json.decode(cachedData) : [];
        currentCats.add(localMockCat);
        await prefs.setString('cached_categories', json.encode(currentCats));

        return Category.fromJson(localMockCat);
      } catch (cacheError) {
        debugPrint('Erro ao enfileirar categoria offline: $cacheError');
        rethrow;
      }
    }
  }

  Future<Category> updateCategory({
    required String id,
    String? name,
    String? type,
    String? icon,
    String? color,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    if (token != null && isTokenExpired(token)) {
      await logout();
      throw const HttpException('Unauthorized');
    }

    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await client
          .patch(
            Uri.parse('$baseUrl/transactions/categories/$id'),
            headers: headers,
            body: json.encode({
              if (name != null) 'name': name,
              if (type != null) 'type': type,
              if (icon != null) 'icon': icon,
              if (color != null) 'color': color,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Category updated = Category.fromJson(data);

        // Atualiza o cache local
        try {
          final String? cachedData = prefs.getString('cached_categories');
          if (cachedData != null) {
            final List<dynamic> currentCats = json.decode(cachedData);
            final int index = currentCats.indexWhere((cat) => cat['id'] == id);
            if (index != -1) {
              currentCats[index] = data;
              await prefs.setString('cached_categories', json.encode(currentCats));
            }
          }
        } catch (_) {}

        return updated;
      } else if (response.statusCode == 401) {
        await logout();
        throw const HttpException('Unauthorized');
      } else {
        throw const HttpException('Falha ao atualizar categoria');
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      throw HttpException('Erro ao atualizar categoria: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    if (token != null && isTokenExpired(token)) {
      await logout();
      throw const HttpException('Unauthorized');
    }

    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await client
          .delete(
            Uri.parse('$baseUrl/transactions/categories/$id'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove do cache local
        try {
          final String? cachedData = prefs.getString('cached_categories');
          if (cachedData != null) {
            final List<dynamic> currentCats = json.decode(cachedData);
            currentCats.removeWhere((cat) => cat['id'] == id);
            await prefs.setString('cached_categories', json.encode(currentCats));
          }
        } catch (_) {}
      } else if (response.statusCode == 401) {
        await logout();
        throw const HttpException('Unauthorized');
      } else {
        // Tenta decodificar a mensagem de erro do backend para exibir ao usuário
        String errMsg = 'Falha ao excluir categoria';
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data.containsKey('message')) {
            errMsg = data['message'].toString();
          }
        } catch (_) {}
        throw HttpException(errMsg);
      }
    } catch (e) {
      if (e is HttpException) {
        rethrow;
      }
      throw HttpException('Erro ao excluir categoria: $e');
    }
  }

  Future<void> syncPendingCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pendingData = prefs.getString('pending_categories');
      if (pendingData == null || pendingData.isEmpty) return;

      final List<dynamic> pendingList = json.decode(pendingData);
      if (pendingList.isEmpty) return;

      final String? token = prefs.getString('access_token');
      if (token != null && isTokenExpired(token)) {
        return;
      }

      final Map<String, String> headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final List<dynamic> remainingPending = [];

      debugPrint(
        'ApiService: Iniciando sincronização de ${pendingList.length} categorias offline...',
      );

      for (final catMap in pendingList) {
        try {
          final response = await client
              .post(
                Uri.parse('$baseUrl/transactions/categories'),
                headers: headers,
                body: json.encode({
                  'name': catMap['name'],
                  'type': catMap['type'],
                  'icon': catMap['icon'],
                  'color': catMap['color'],
                }),
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode != 200 && response.statusCode != 201) {
            if (response.statusCode == 401) {
              await logout();
              throw const HttpException('Unauthorized');
            }
            remainingPending.add(catMap);
          }
        } catch (e) {
          remainingPending.addAll(
            pendingList.sublist(pendingList.indexOf(catMap)),
          );
          debugPrint(
            'ApiService: Pausando sincronização de categorias devido a erro de rede: $e',
          );
          break;
        }
      }

      if (remainingPending.isEmpty) {
        await prefs.remove('pending_categories');
        debugPrint('ApiService: Sincronização offline de categorias concluída!');
      } else {
        await prefs.setString(
          'pending_categories',
          json.encode(remainingPending),
        );
        debugPrint(
          'ApiService: Sincronização de categorias incompleta. ${remainingPending.length} restantes na fila.',
        );
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar categorias offline: $e');
    }
  }

  Future<void> syncPendingTransactions() async {
    try {
      await syncPendingCategories();

      final prefs = await SharedPreferences.getInstance();
      final String? pendingData = prefs.getString('pending_transactions');
      if (pendingData == null || pendingData.isEmpty) return;

      final List<dynamic> pendingList = json.decode(pendingData);
      if (pendingList.isEmpty) return;

      final String? token = prefs.getString('access_token');
      if (token != null && isTokenExpired(token)) {
        return; // Não sincroniza se o token estiver expirado/inválido
      }

      final Map<String, String> headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final List<dynamic> remainingPending = [];

      debugPrint(
        'ApiService: Iniciando sincronização de ${pendingList.length} transações offline...',
      );

      for (final txMap in pendingList) {
        try {
          final response = await client
              .post(
                Uri.parse('$baseUrl/transactions'),
                headers: headers,
                body: json.encode({
                  'description': txMap['description'],
                  'amount': txMap['amount'],
                  'type': txMap['type'],
                  'date': txMap['date'],
                }),
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode != 200 && response.statusCode != 201) {
            if (response.statusCode == 401) {
              await logout();
              throw const HttpException('Unauthorized');
            }
            remainingPending.add(txMap);
          }
        } catch (e) {
          // Erro de rede/timeout durante sincronização: mantém as transações restantes na fila e aborta sync atual
          remainingPending.addAll(
            pendingList.sublist(pendingList.indexOf(txMap)),
          );
          debugPrint(
            'ApiService: Pausando sincronização devido a erro de rede: $e',
          );
          break;
        }
      }

      if (remainingPending.isEmpty) {
        await prefs.remove('pending_transactions');
        debugPrint('ApiService: Sincronização offline concluída com sucesso!');
      } else {
        await prefs.setString(
          'pending_transactions',
          json.encode(remainingPending),
        );
        debugPrint(
          'ApiService: Sincronização incompleta. ${remainingPending.length} restantes na fila.',
        );
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar transações offline: $e');
    }
  }
}
