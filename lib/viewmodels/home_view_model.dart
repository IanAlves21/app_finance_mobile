import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../services/api_service.dart';

class HomeViewModel extends ChangeNotifier {
  final ApiService _apiService;

  HomeViewModel({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  List<Transaction> _transactions = [];
  bool _isLoading = true;
  double _balance = 0.0;
  double _income = 0.0;
  double _expenses = 0.0;

  // Pagination states
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadMoreLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get balance => _balance;
  double get income => _income;
  double get expenses => _expenses;
  
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isLoadMoreLoading => _isLoadMoreLoading;

  Future<void> loadTransactions({bool isRefresh = true, VoidCallback? onUnauthorized}) async {
    if (isRefresh) {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      notifyListeners();
    } else {
      _isLoadMoreLoading = true;
      notifyListeners();
    }

    try {
      final fetched = await _apiService.fetchTransactions(page: _currentPage, limit: 15);

      if (fetched.length < 15) {
        _hasMore = false;
      }

      if (isRefresh) {
        _transactions = fetched;
      } else {
        _transactions.addAll(fetched);
      }

      // Calculate aggregates
      double calculatedIncome = 0.0;
      double calculatedExpenses = 0.0;
      for (final tx in _transactions) {
        if (tx.amount > 0) {
          calculatedIncome += tx.amount;
        } else {
          calculatedExpenses += tx.amount.abs();
        }
      }

      _income = calculatedIncome;
      _expenses = calculatedExpenses;
      _balance = calculatedIncome - calculatedExpenses;
    } on HttpException catch (e) {
      if (e.message == 'Unauthorized') {
        if (onUnauthorized != null) {
          onUnauthorized();
        }
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      _isLoadMoreLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage({VoidCallback? onUnauthorized}) async {
    if (_isLoadMoreLoading || !_hasMore || _isLoading) return;
    _currentPage++;
    await loadTransactions(isRefresh: false, onUnauthorized: onUnauthorized);
  }
}
