import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/secure_storage_manager.dart';

class TransactionRepository {
  final ApiService _apiService;

  TransactionRepository({required this._apiService});

  /// Busca as transações do servidor com paginação e suporte a cache local
  Future<List<Transaction>> fetchTransactions({
    int page = 1,
    int limit = 15,
    String? startDate,
    String? endDate,
    String? categoryId,
  }) async {
    try {
      final String? token = await SecureStorageManager.readToken();

      // Proteção prévia: se houver token, mas ele estiver expirado, desloga antes de fazer a requisição
      if (token != null && ApiService.isTokenExpired(token)) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      }

      if (page == 1) {
        // Tenta sincronizar transações offline pendentes antes de carregar
        await syncPendingTransactions();
      }

      String queryPath = '/transactions?page=$page&limit=$limit';
      if (startDate != null) {
        queryPath += '&startDate=$startDate';
      }
      if (endDate != null) {
        queryPath += '&endDate=$endDate';
      }
      if (categoryId != null) {
        queryPath += '&categoryId=$categoryId';
      }

      final response = await _apiService
          .get(queryPath)
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
        await _apiService.logout();
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
      debugPrint(
        'TransactionRepository error, carregando transações do cache local: $e',
      );

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

      return [];
    }
  }

  /// Cria uma transação (online ou enfileira offline se estiver sem rede)
  Future<Transaction> createTransaction({
    required String description,
    required double amount,
    required String type, // 'INCOME' ou 'EXPENSE'
    required String date, // ISO string
    String? categoryId,
    String? paymentMethod,
    int? installments,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _apiService
          .post('/transactions', {
            'description': description,
            'amount': amount,
            'type': type,
            'date': date,
            if (categoryId != null) 'categoryId': categoryId,
            if (paymentMethod != null) 'paymentMethod': paymentMethod,
            if (installments != null) 'installments': installments,
          })
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Transaction newTx = Transaction.fromJson(data);

        // 1. Atualiza imediatamente o cache de transações locais para exibição instantânea
        if (newTx.status == 'Completed' || newTx.status == 'Pending') {
          try {
            final String? cachedData = prefs.getString('cached_transactions');
            final List<dynamic> cacheList = cachedData != null
                ? json.decode(cachedData)
                : [];

            // Adiciona no topo da lista (transação mais recente primeiro)
            cacheList.insert(0, data);
            await prefs.setString(
              'cached_transactions',
              json.encode(cacheList),
            );
          } catch (cacheError) {
            debugPrint('Erro ao atualizar cache de transações: $cacheError');
          }
        }

        return newTx;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
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
        'TransactionRepository error durante criação, enfileirando offline: $e',
      );

      // Salva a transação pendente na lista local para sincronização futura
      final pendingTx = {
        'description': description,
        'amount': amount,
        'type': type,
        'date': date,
        if (categoryId != null) 'categoryId': categoryId,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (installments != null) 'installments': installments,
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
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          'paidBy': {'name': prefs.getString('user_name') ?? 'Me'},
          'wallet': {'name': 'Shared Wallet Account'},
          'note': 'Sincronização pendente',
          'status': 'PENDING',
        };
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

  /// Atualiza uma transação existente online
  Future<Transaction> updateTransaction({
    required String id,
    required String description,
    required double amount,
    required String type, // 'INCOME' ou 'EXPENSE'
    String? categoryId,
    String? paymentMethod,
  }) async {
    try {
      final response = await _apiService
          .patch('/transactions/$id', {
            'description': description,
            'amount': amount,
            'type': type,
            'categoryId': categoryId,
            'paymentMethod': paymentMethod,
          })
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Transaction updatedTx = Transaction.fromJson(data);

        // Atualiza o cache local
        try {
          final prefs = await SharedPreferences.getInstance();
          final String? cachedData = prefs.getString('cached_transactions');
          if (cachedData != null && cachedData.isNotEmpty) {
            final List<dynamic> cacheList = json.decode(cachedData);
            final int index = cacheList.indexWhere((tx) => tx['id']?.toString() == id);
            if (index != -1) {
              cacheList[index] = data;
              await prefs.setString(
                'cached_transactions',
                json.encode(cacheList),
              );
            }
          }
        } catch (cacheError) {
          debugPrint('Erro ao atualizar cache de transações no update: $cacheError');
        }

        return updatedTx;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        String errorMessage = 'Falha ao atualizar transação';
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
      if (e is HttpException) {
        rethrow;
      }
      throw HttpException('Erro de conexão ao atualizar transação: $e');
    }
  }

  /// Sincroniza todas as transações criadas offline que estão pendentes
  Future<void> syncPendingTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pendingData = prefs.getString('pending_transactions');
      if (pendingData == null || pendingData.isEmpty) return;

      final List<dynamic> pendingList = json.decode(pendingData);
      if (pendingList.isEmpty) return;

      final String? token = await SecureStorageManager.readToken();
      if (token != null && ApiService.isTokenExpired(token)) {
        return; // Não sincroniza se o token estiver expirado/inválido
      }

      final List<dynamic> remainingPending = [];

      debugPrint(
        'TransactionRepository: Iniciando sincronização de ${pendingList.length} transações offline...',
      );

      for (final txMap in pendingList) {
        try {
          final response = await _apiService
              .post('/transactions', {
                'description': txMap['description'],
                'amount': txMap['amount'],
                'type': txMap['type'],
                'date': txMap['date'],
                if (txMap.containsKey('categoryId'))
                  'categoryId': txMap['categoryId'],
                if (txMap.containsKey('paymentMethod'))
                  'paymentMethod': txMap['paymentMethod'],
                if (txMap.containsKey('installments'))
                  'installments': txMap['installments'],
              })
              .timeout(const Duration(seconds: 5));

          if (response.statusCode != 200 && response.statusCode != 201) {
            if (response.statusCode == 401) {
              await _apiService.logout();
              throw const HttpException('Unauthorized');
            }
            remainingPending.add(txMap);
          }
        } catch (e) {
          remainingPending.addAll(
            pendingList.sublist(pendingList.indexOf(txMap)),
          );
          debugPrint(
            'TransactionRepository: Pausando sincronização de transações devido a erro de rede: $e',
          );
          break;
        }
      }

      if (remainingPending.isEmpty) {
        await prefs.remove('pending_transactions');
        debugPrint(
          'TransactionRepository: Sincronização offline de transações concluída!',
        );
      } else {
        await prefs.setString(
          'pending_transactions',
          json.encode(remainingPending),
        );
        debugPrint(
          'TransactionRepository: Sincronização de transações incompleta. ${remainingPending.length} restantes na fila.',
        );
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar transações offline: $e');
    }
  }

  /// Exclui uma transação online e atualiza o cache local
  Future<void> deleteTransaction(String id) async {
    try {
      final String? token = await SecureStorageManager.readToken();

      if (token != null && ApiService.isTokenExpired(token)) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      }

      final response = await _apiService
          .delete('/transactions/$id')
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Atualiza o cache local removendo a transação excluída
        try {
          final prefs = await SharedPreferences.getInstance();
          final String? cachedData = prefs.getString('cached_transactions');
          if (cachedData != null) {
            final List<dynamic> cacheList = json.decode(cachedData);
            cacheList.removeWhere((tx) => tx['id'] == id);
            await prefs.setString(
              'cached_transactions',
              json.encode(cacheList),
            );
          }
        } catch (cacheError) {
          debugPrint('Erro ao atualizar cache após exclusão: $cacheError');
        }
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException(
          'Failed to delete transaction: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint('Erro ao excluir transação: $e');
      rethrow;
    }
  }

  /// Busca o resumo mensal precalculado no servidor
  Future<Map<String, dynamic>> fetchMonthlySummary({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final String? token = await SecureStorageManager.readToken();

      if (token != null && ApiService.isTokenExpired(token)) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      }

      final response = await _apiService
          .get('/transactions/summary?startDate=$startDate&endDate=$endDate')
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'income': (data['income'] as num).toDouble(),
          'expenses': (data['expenses'] as num).toDouble(),
          'balance': (data['balance'] as num).toDouble(),
        };
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException('Failed to load summary: ${response.statusCode}');
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint('Erro ao carregar resumo mensal: $e');
      return {'income': 0.0, 'expenses': 0.0, 'balance': 0.0};
    }
  }

  /// Busca os dados de gastos mensais históricos
  /// Busca os dados de gastos históricos (semanal, mensal ou anual)
  Future<List<Map<String, dynamic>>> fetchMonthlySpending({
    int limit = 6,
    String timeframe = 'MONTHLY',
  }) async {
    try {
      final String? token = await SecureStorageManager.readToken();

      if (token != null && ApiService.isTokenExpired(token)) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      }

      final response = await _apiService
          .get('/analytics/monthly-spending?limit=$limit&timeframe=$timeframe')
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException(
          'Failed to load monthly spending: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint(
        'Erro ao carregar gastos históricos do servidor ($timeframe): $e',
      );

      // Fallback local para estabilidade offline
      final DateTime now = DateTime.now();
      final List<Map<String, dynamic>> fallbackData = [];
      for (int i = limit - 1; i >= 0; i--) {
        if (timeframe == 'YEARLY') {
          fallbackData.add({
            'year': now.year - i,
            'income': 0.0,
            'expense': 0.0,
          });
        } else if (timeframe == 'WEEKLY') {
          final currentWeekStart = DateTime(
            now.year,
            now.month,
            now.day - now.weekday,
          );
          final d = currentWeekStart.subtract(Duration(days: i * 7));
          fallbackData.add({
            'year': d.year,
            'month': d.month,
            'day': d.day,
            'income': 0.0,
            'expense': 0.0,
          });
        } else {
          final d = DateTime(now.year, now.month - i, 1);
          fallbackData.add({
            'year': d.year,
            'month': d.month,
            'income': 0.0,
            'expense': 0.0,
          });
        }
      }
      return fallbackData;
    }
  }

  /// Realiza o download do relatório em PDF para o período selecionado
  Future<Uint8List> fetchReportPdf({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final String? token = await SecureStorageManager.readToken();

      if (token != null && ApiService.isTokenExpired(token)) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      }

      final response = await _apiService
          .get('/analytics/report/pdf?startDate=$startDate&endDate=$endDate')
          .timeout(
            const Duration(seconds: 10),
          ); // 10 seconds timeout for report compilation

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException(
          'Failed to generate report: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint('Erro ao obter relatório PDF do servidor: $e');
      rethrow;
    }
  }
}
