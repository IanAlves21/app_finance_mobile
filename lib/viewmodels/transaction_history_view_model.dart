import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../services/service_locator.dart';

class TransactionHistoryViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository = locator<TransactionRepository>();
  final List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadMoreLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  DateTimeRange? _selectedDateRange;

  TransactionHistoryViewModel() {
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isLoadMoreLoading => _isLoadMoreLoading;
  bool get hasMore => _hasMore;
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  void setDateRange(DateTimeRange range) {
    _selectedDateRange = range;
    loadTransactions(isRefresh: true);
  }

  Future<void> loadTransactions({bool isRefresh = true}) async {
    if (isRefresh) {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _transactions.clear();
      notifyListeners();
    } else {
      if (_isLoadMoreLoading || !_hasMore) return;
      _isLoadMoreLoading = true;
      notifyListeners();
    }

    try {
      final startIso = _selectedDateRange?.start.toIso8601String();
      final endIso = _selectedDateRange?.end.toIso8601String();

      final fetched = await _transactionRepository.fetchTransactions(
        page: _currentPage,
        limit: 15,
        startDate: startIso,
        endDate: endIso,
      );

      if (fetched.length < 15) {
        _hasMore = false;
      }

      _transactions.addAll(fetched);
    } catch (e) {
      debugPrint('Error loading transactions inside ViewModel: $e');
      rethrow;
    } finally {
      _isLoading = false;
      _isLoadMoreLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (_isLoadMoreLoading || !_hasMore || _isLoading) return;
    _currentPage++;
    await loadTransactions(isRefresh: false);
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _transactionRepository.deleteTransaction(id);
      _transactions.removeWhere((tx) => tx.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting transaction inside ViewModel: $e');
      rethrow;
    }
  }
}
