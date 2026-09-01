import 'package:flutter_test/flutter_test.dart';
import 'package:app_finance_mobile/viewmodels/home_view_model.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/models/transaction.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockTransactionRepository extends TransactionRepository {
  MockTransactionRepository()
    : super(
        apiService: ApiService(
          client: MockClient((_) async => http.Response('', 200)),
        ),
      );

  Map<String, dynamic>? Function(String startDate, String endDate)?
  onFetchMonthlySummary;
  Future<List<Transaction>> Function()? onFetchTransactions;

  @override
  Future<Map<String, dynamic>> fetchMonthlySummary({
    required String startDate,
    required String endDate,
  }) async {
    if (onFetchMonthlySummary != null) {
      return onFetchMonthlySummary!(startDate, endDate) ??
          {'income': 0.0, 'expenses': 0.0, 'balance': 0.0};
    }
    return {'income': 0.0, 'expenses': 0.0, 'balance': 0.0};
  }

  @override
  Future<List<Transaction>> fetchTransactions({
    int page = 1,
    int limit = 15,
    String? startDate,
    String? endDate,
    String? categoryId,
  }) async {
    if (onFetchTransactions != null) {
      return onFetchTransactions!();
    }
    return [];
  }
}

void main() {
  late MockTransactionRepository mockRepository;
  late HomeViewModel viewModel;

  setUp(() async {
    mockRepository = MockTransactionRepository();
    viewModel = HomeViewModel(transactionRepository: mockRepository);
  });

  group('HomeViewModel - Previous Month Comparison calculations', () {
    test('Calculates positive changes correctly', () async {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

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

      mockRepository.onFetchMonthlySummary = (startDate, endDate) {
        if (startDate == firstDayOfMonth.toIso8601String() &&
            endDate == lastDayOfMonth.toIso8601String()) {
          return {'income': 5000.0, 'expenses': 2500.0, 'balance': 2500.0};
        } else if (startDate == firstDayOfPrevMonth.toIso8601String() &&
            endDate == lastDayOfPrevMonth.toIso8601String()) {
          return {'income': 4000.0, 'expenses': 2000.0, 'balance': 2000.0};
        }
        return null;
      };

      mockRepository.onFetchTransactions = () async => [];

      await viewModel.loadTransactions();

      expect(viewModel.income, 5000.0);
      expect(viewModel.expenses, 2500.0);
      expect(viewModel.balance, 2500.0);

      expect(viewModel.prevIncome, 4000.0);
      expect(viewModel.prevExpenses, 2000.0);
      expect(viewModel.prevBalance, 2000.0);

      // Percentage Change validations
      // ((5000 - 4000) / 4000) * 100 = 25%
      expect(viewModel.incomeChangePercentage, 25.0);
      expect(viewModel.incomeComparisonText, '+25%');

      // ((2500 - 2000) / 2000) * 100 = 25%
      expect(viewModel.expensesChangePercentage, 25.0);
      expect(viewModel.expensesComparisonText, '+25%');

      // ((2500 - 2000) / 2000) * 100 = 25%
      expect(viewModel.balanceChangePercentage, 25.0);
      expect(viewModel.balanceComparisonText, '+25.0%');
    });

    test('Calculates negative/savings changes correctly', () async {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

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

      mockRepository.onFetchMonthlySummary = (startDate, endDate) {
        if (startDate == firstDayOfMonth.toIso8601String() &&
            endDate == lastDayOfMonth.toIso8601String()) {
          return {'income': 3000.0, 'expenses': 1500.0, 'balance': 1500.0};
        } else if (startDate == firstDayOfPrevMonth.toIso8601String() &&
            endDate == lastDayOfPrevMonth.toIso8601String()) {
          return {'income': 4000.0, 'expenses': 2000.0, 'balance': 2000.0};
        }
        return null;
      };

      mockRepository.onFetchTransactions = () async => [];

      await viewModel.loadTransactions();

      // ((3000 - 4000) / 4000) * 100 = -25%
      expect(viewModel.incomeChangePercentage, -25.0);
      expect(viewModel.incomeComparisonText, '-25%');

      // ((1500 - 2000) / 2000) * 100 = -25%
      expect(viewModel.expensesChangePercentage, -25.0);
      expect(viewModel.expensesComparisonText, '-25%');

      // ((1500 - 2000) / 2000) * 100 = -25%
      expect(viewModel.balanceChangePercentage, -25.0);
      expect(viewModel.balanceComparisonText, '-25.0%');
    });

    test('Handles zero in previous values gracefully', () async {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

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

      mockRepository.onFetchMonthlySummary = (startDate, endDate) {
        if (startDate == firstDayOfMonth.toIso8601String() &&
            endDate == lastDayOfMonth.toIso8601String()) {
          return {'income': 2000.0, 'expenses': 1000.0, 'balance': 1000.0};
        } else if (startDate == firstDayOfPrevMonth.toIso8601String() &&
            endDate == lastDayOfPrevMonth.toIso8601String()) {
          return {'income': 0.0, 'expenses': 0.0, 'balance': 0.0};
        }
        return null;
      };

      mockRepository.onFetchTransactions = () async => [];

      await viewModel.loadTransactions();

      expect(viewModel.incomeChangePercentage, 100.0);
      expect(viewModel.incomeComparisonText, '+100%');

      expect(viewModel.expensesChangePercentage, 100.0);
      expect(viewModel.expensesComparisonText, '+100%');

      expect(viewModel.balanceChangePercentage, 100.0);
      expect(viewModel.balanceComparisonText, '+100.0%');
    });
  });
}
