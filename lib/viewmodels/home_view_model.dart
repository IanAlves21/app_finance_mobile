import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../services/service_locator.dart';

class HomeViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  HomeViewModel({TransactionRepository? transactionRepository})
    : _transactionRepository =
          transactionRepository ?? locator<TransactionRepository>();

  List<Transaction> _transactions = [];
  bool _isLoadingTransactions = true;
  bool _isLoadingSummary = true;
  double _balance = 0.0;
  double _income = 0.0;
  double _expenses = 0.0;

  double _prevIncome = 0.0;
  double _prevExpenses = 0.0;
  double _prevBalance = 0.0;

  // Pagination states
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadMoreLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading =>
      _isLoadingTransactions; // Backward-compatibility for list skeletons
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingSummary => _isLoadingSummary;
  double get balance => _balance;
  double get income => _income;
  double get expenses => _expenses;

  double get prevIncome => _prevIncome;
  double get prevExpenses => _prevExpenses;
  double get prevBalance => _prevBalance;

  double get incomeChangePercentage {
    if (_prevIncome == 0.0) {
      return _income == 0.0 ? 0.0 : (_income > 0 ? 100.0 : -100.0);
    }
    return ((_income - _prevIncome) / _prevIncome) * 100;
  }

  double get expensesChangePercentage {
    if (_prevExpenses == 0.0) {
      return _expenses == 0.0 ? 0.0 : (_expenses > 0 ? 100.0 : -100.0);
    }
    return ((_expenses - _prevExpenses) / _prevExpenses) * 100;
  }

  double get balanceChangePercentage {
    if (_prevBalance == 0.0) {
      return _balance == 0.0 ? 0.0 : (_balance > 0 ? 100.0 : -100.0);
    }
    return ((_balance - _prevBalance) / _prevBalance.abs()) * 100;
  }

  String get incomeComparisonText {
    final pct = incomeChangePercentage;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}%';
  }

  String get expensesComparisonText {
    final pct = expensesChangePercentage;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}%';
  }

  String get balanceComparisonText {
    final pct = balanceChangePercentage;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isLoadMoreLoading => _isLoadMoreLoading;

  Future<void> loadTransactions({
    bool isRefresh = true,
    VoidCallback? onUnauthorized,
  }) async {
    if (isRefresh) {
      _isLoadingTransactions = true;
      _isLoadingSummary = true;
      _currentPage = 1;
      _hasMore = true;
      notifyListeners();
    } else {
      _isLoadMoreLoading = true;
      notifyListeners();
    }

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final startDateStr = firstDayOfMonth.toIso8601String();
    final endDateStr = lastDayOfMonth.toIso8601String();

    // 1. Carrega as Transações concorrentemente
    final Future<void> transactionsFuture = () async {
      try {
        final fetched = await _transactionRepository.fetchTransactions(
          page: _currentPage,
          limit: 15,
          startDate: startDateStr,
          endDate: endDateStr,
        );

        if (fetched.length < 15) {
          _hasMore = false;
        }

        if (isRefresh) {
          _transactions = fetched;
        } else {
          _transactions.addAll(fetched);
        }
      } on HttpException catch (e) {
        if (e.message == 'Unauthorized') {
          if (onUnauthorized != null) {
            onUnauthorized();
          }
        }
        rethrow;
      } catch (e) {
        debugPrint('Error loading transactions in HomeViewModel: $e');
        rethrow;
      } finally {
        _isLoadingTransactions = false;
        _isLoadMoreLoading = false;
        notifyListeners();
      }
    }();

    // 2. Carrega o Resumo Mensal concorrentemente (somente no refresh inicial)
    final Future<void> summaryFuture = () async {
      if (!isRefresh) return;
      try {
        final summary = await _transactionRepository.fetchMonthlySummary(
          startDate: startDateStr,
          endDate: endDateStr,
        );

        _income = summary['income'];
        _expenses = summary['expenses'];
        _balance = summary['balance'];

        // Carrega também o resumo do mês anterior
        final prevMonthDate = DateTime(now.year, now.month - 1, 1);
        final firstDayOfPrevMonth = DateTime(
          prevMonthDate.year,
          prevMonthDate.month,
          1,
        );
        final lastDayOfPrevMonth = DateTime(
          prevMonthDate.year,
          prevMonthDate.month + 1,
          0,
          23,
          59,
          59,
        );

        final prevSummary = await _transactionRepository.fetchMonthlySummary(
          startDate: firstDayOfPrevMonth.toIso8601String(),
          endDate: lastDayOfPrevMonth.toIso8601String(),
        );

        _prevIncome = prevSummary['income'];
        _prevExpenses = prevSummary['expenses'];
        _prevBalance = prevSummary['balance'];
      } on HttpException catch (e) {
        if (e.message == 'Unauthorized') {
          if (onUnauthorized != null) {
            onUnauthorized();
          }
        }
        rethrow;
      } catch (e) {
        debugPrint('Error loading monthly summary in HomeViewModel: $e');
        rethrow;
      } finally {
        _isLoadingSummary = false;
        notifyListeners();
      }
    }();

    // Aguarda a resolução de ambas concorrentemente
    if (isRefresh) {
      await Future.wait([transactionsFuture, summaryFuture]).catchError((err) {
        debugPrint('Erro em alguma das requisições paralelas: $err');
        return [];
      });
    } else {
      await transactionsFuture.catchError((err) {
        debugPrint('Erro na paginação de transações: $err');
      });
    }
  }

  Future<void> loadNextPage({VoidCallback? onUnauthorized}) async {
    if (_isLoadMoreLoading || !_hasMore || _isLoadingTransactions) return;
    _currentPage++;
    await loadTransactions(isRefresh: false, onUnauthorized: onUnauthorized);
  }

  /// Exclui uma transação e atualiza o estado local de forma imediata
  Future<void> deleteTransaction(
    String id, {
    VoidCallback? onUnauthorized,
  }) async {
    try {
      await _transactionRepository.deleteTransaction(id);

      // Remove a transação localmente
      _transactions.removeWhere((tx) => tx.id == id);

      // Busca o resumo mensal atualizado diretamente do backend para garantir precisão
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final summary = await _transactionRepository.fetchMonthlySummary(
        startDate: firstDayOfMonth.toIso8601String(),
        endDate: lastDayOfMonth.toIso8601String(),
      );

      _income = summary['income'];
      _expenses = summary['expenses'];
      _balance = summary['balance'];

      notifyListeners();
    } on HttpException catch (e) {
      if (e.message == 'Unauthorized') {
        if (onUnauthorized != null) {
          onUnauthorized();
        }
      }
      rethrow;
    } catch (e) {
      debugPrint('Error deleting transaction in HomeViewModel: $e');
      rethrow;
    }
  }
}
