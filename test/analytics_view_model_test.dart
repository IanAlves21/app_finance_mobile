import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_finance_mobile/viewmodels/analytics_view_model.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/services/service_locator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockTransactionRepository extends TransactionRepository {
  MockTransactionRepository() : super(apiService: ApiService(client: MockClient((_) async => http.Response('', 200))));
  
  List<Map<String, dynamic>>? mockSpendingResponse;

  @override
  Future<List<Map<String, dynamic>>> fetchMonthlySpending({
    int limit = 6,
    String timeframe = 'MONTHLY',
  }) async {
    return mockSpendingResponse ?? [];
  }

  @override
  Future<Uint8List> fetchReportPdf({
    required String startDate,
    required String endDate,
  }) async {
    return Uint8List.fromList([1, 2, 3, 4]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTransactionRepository mockRepository;
  late AnalyticsViewModel viewModel;

  setUpAll(() {
    // Mock the PathProvider and OpenFilex platform channels to avoid native channel exceptions
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return '.';
    });

    const MethodChannel('open_filex')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return {'type': 0, 'message': 'done'};
    });
  });

  setUp(() async {
    await initializeDateFormatting('en');
    await locator.reset();
    mockRepository = MockTransactionRepository();
    locator.registerSingleton<TransactionRepository>(mockRepository);
    viewModel = AnalyticsViewModel();
  });

  group('AnalyticsViewModel - Savings Rate calculations', () {
    test('Calculates positive savings rate correctly', () async {
      mockRepository.mockSpendingResponse = [
        {
          'year': 2026,
          'month': 1,
          'income': 5000.0,
          'expense': 3000.0,
          'categories': [],
          'byUser': [],
        },
        {
          'year': 2026,
          'month': 2,
          'income': 10000.0,
          'expense': 6500.0,
          'categories': [],
          'byUser': [],
        }
      ];

      await viewModel.loadMonthlySpending();
      viewModel.setActiveBarIndex(5);

      expect(viewModel.activeIncome, 10000.0);
      expect(viewModel.activeExpense, 6500.0);
      expect(viewModel.activeSavings, 3500.0);
      expect(viewModel.savingsRate, 35.0);
    });

    test('Calculates negative savings rate (deficit) correctly', () async {
      mockRepository.mockSpendingResponse = [
        {
          'year': 2026,
          'month': 1,
          'income': 5000.0,
          'expense': 3000.0,
          'categories': [],
          'byUser': [],
        },
        {
          'year': 2026,
          'month': 2,
          'income': 4000.0,
          'expense': 5000.0,
          'categories': [],
          'byUser': [],
        }
      ];

      await viewModel.loadMonthlySpending();
      viewModel.setActiveBarIndex(5);

      expect(viewModel.activeIncome, 4000.0);
      expect(viewModel.activeExpense, 5000.0);
      expect(viewModel.activeSavings, -1000.0);
      expect(viewModel.savingsRate, -25.0);
    });

    test('Handles zero income gracefully', () async {
      mockRepository.mockSpendingResponse = [
        {
          'year': 2026,
          'month': 1,
          'income': 5000.0,
          'expense': 3000.0,
          'categories': [],
          'byUser': [],
        },
        {
          'year': 2026,
          'month': 2,
          'income': 0.0,
          'expense': 1200.0,
          'categories': [],
          'byUser': [],
        }
      ];

      await viewModel.loadMonthlySpending();
      viewModel.setActiveBarIndex(5);

      expect(viewModel.activeIncome, 0.0);
      expect(viewModel.activeExpense, 1200.0);
      expect(viewModel.activeSavings, -1200.0);
      expect(viewModel.savingsRate, 0.0);
    });

    test('generatePdfReport completes successfully and sets isGeneratingPdf', () async {
      expect(viewModel.isGeneratingPdf, isFalse);

      final future = viewModel.generatePdfReport(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        onUnauthorized: () {},
      );

      expect(viewModel.isGeneratingPdf, isTrue);

      await future;

      expect(viewModel.isGeneratingPdf, isFalse);
    });
  });
}
