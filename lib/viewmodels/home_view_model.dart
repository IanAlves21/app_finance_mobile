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

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get balance => _balance;
  double get income => _income;
  double get expenses => _expenses;

  Future<void> loadTransactions({VoidCallback? onUnauthorized}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await _apiService.fetchTransactions();

      // Calculate aggregates
      double calculatedIncome = 0.0;
      double calculatedExpenses = 0.0;
      for (final tx in fetched) {
        if (tx.amount > 0) {
          calculatedIncome += tx.amount;
        } else {
          calculatedExpenses += tx.amount.abs();
        }
      }

      _transactions = fetched;
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
      notifyListeners();
    }
  }
}
