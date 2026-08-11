import 'dart:convert';
import 'dart:io';
import '../models/budget.dart';
import '../services/api_service.dart';
import '../services/secure_storage_manager.dart';

class BudgetRepository {
  final ApiService _apiService;

  BudgetRepository({required this._apiService});

  /// Busca os limites de orçamento do servidor para um determinado mês e ano
  Future<List<Budget>> fetchBudgets(int month, int year) async {
    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    final response = await _apiService
        .get('/budgets?month=$month&year=$year')
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Budget.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    } else {
      throw HttpException('Failed to load budgets: ${response.statusCode}');
    }
  }

  /// Cria ou atualiza (upsert) um limite de orçamento no servidor
  Future<Budget> upsertBudget({
    required double amount,
    required int month,
    required int year,
    required String categoryId,
  }) async {
    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    final response = await _apiService.post(
      '/budgets',
      {
        'amount': amount,
        'month': month,
        'year': year,
        'categoryId': categoryId,
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Budget.fromJson(data);
    } else if (response.statusCode == 401) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    } else {
      throw HttpException('Failed to upsert budget: ${response.statusCode}');
    }
  }

  /// Remove um limite de orçamento do servidor
  Future<void> deleteBudget(String id) async {
    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    final response = await _apiService
        .delete('/budgets/$id')
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else if (response.statusCode == 401) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    } else {
      throw HttpException('Failed to delete budget: ${response.statusCode}');
    }
  }
}
