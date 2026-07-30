import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_finance_mobile/main.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/services/secure_storage_manager.dart';
import 'package:app_finance_mobile/services/service_locator.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';
import 'package:app_finance_mobile/repositories/category_repository.dart';
import 'package:app_finance_mobile/viewmodels/login_view_model.dart';
import 'package:app_finance_mobile/viewmodels/analytics_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() async {
    SecureStorageManager.useMock = true;
    SecureStorageManager.mockToken = 'mocked_jwt_token';

    // Reset GetIt and register default services for testing
    await locator.reset();

    final defaultMockClient = MockClient((request) async {
      if (request.url.path == '/transactions/summary') {
        return http.Response(
          json.encode({'income': 4500.0, 'expenses': 0.0, 'balance': 4500.0}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/transactions') {
        return http.Response(
          json.encode([
            {
              'id': '1',
              'description': 'Freelance Payment',
              'type': 'INCOME',
              'amount': '4500.0',
              'date': '2026-07-05T12:00:00.000Z',
              'category': {'name': 'Income'},
              'paidBy': {'name': 'John Doe'},
              'wallet': {'name': 'Shared Wallet Account'},
              'note': 'Payment for design system deliverables',
              'status': 'COMPLETED'
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final defaultApiService = ApiService(client: defaultMockClient);
    locator.registerSingleton<ApiService>(defaultApiService);
    locator.registerSingleton<TransactionRepository>(TransactionRepository(apiService: defaultApiService));
    locator.registerSingleton<CategoryRepository>(CategoryRepository(apiService: defaultApiService));

    SharedPreferences.setMockInitialValues({
      'cached_transactions': json.encode([
        {
          'id': '1',
          'description': 'Freelance Payment',
          'type': 'INCOME',
          'amount': '4500.0',
          'date': '2026-07-05T12:00:00.000Z',
          'category': {'name': 'Income'},
          'paidBy': {'name': 'John Doe'},
          'wallet': {'name': 'Shared Wallet Account'},
          'note': 'Payment for design system deliverables',
          'status': 'COMPLETED'
        }
      ]),
    });
  });
  testWidgets('App renders LoginScreen initially and performs successful login', (WidgetTester tester) async {
    // Reset login status to false initially
    isLoggedInNotifier.value = false;
    
    // Force Portuguese for deterministic assertions
    localeNotifier.value = const Locale('pt');

    final mockClient = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        // Add a realistic 800ms delay so that at 500ms the login is still loading
        await Future.delayed(const Duration(milliseconds: 800));
        return http.Response(
          json.encode({
            'access_token': 'mocked_jwt_token',
            'user': {
              'id': 'mocked_user_id',
              'name': 'Ian Gustavo',
              'email': 'ian@teste.com'
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final mockApiService = ApiService(client: mockClient);
    final mockLoginViewModel = LoginViewModel(apiService: mockApiService);

    await tester.pumpWidget(MyApp(loginViewModel: mockLoginViewModel));
    await tester.pumpAndSettle();

    // Verify LoginScreen is shown
    expect(find.text('Bem-vindos de volta'), findsOneWidget);
    expect(find.text('Sua vida financeira a dois'), findsOneWidget);
    expect(find.text('E-MAIL'), findsOneWidget);
    expect(find.text('SENHA'), findsOneWidget);

    // Enter email and password
    await tester.enterText(find.byType(TextField).at(0), 'teste@email.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha123');
    await tester.pumpAndSettle();

    // Tap on Submit Button
    final loginButtonFinder = find.text('Entrar');
    expect(loginButtonFinder, findsOneWidget);
    await tester.tap(loginButtonFinder);
    
    // Pump frames to let the animation and delay run (LoginViewModel has a 1200ms delay)
    await tester.pump(const Duration(milliseconds: 500));
    // Verify it is loading (showing CircularProgressIndicator)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump remainder of delay
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));

    // Verify it entered the Dashboard and login screen is gone
    expect(find.text('Bem-vindos de volta'), findsNothing);
    expect(find.text('SALDO TOTAL COMPARTILHADO'), findsOneWidget);
  });

  testWidgets('App dynamically switches locales and renders correct text', (WidgetTester tester) async {
    // Force login state to bypass login screen in existing test flows
    isLoggedInNotifier.value = true;
    
    // Force Portuguese initially for deterministic test assertion
    localeNotifier.value = const Locale('pt');

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that Portuguese localized text is rendered
    expect(find.text('BOM DIA'), findsOneWidget);
    expect(find.text('SALDO TOTAL COMPARTILHADO'), findsOneWidget);

    // Switch dynamically to English
    localeNotifier.value = const Locale('en');
    await tester.pumpAndSettle();

    // Verify that English localized text is now rendered
    expect(find.text('GOOD MORNING'), findsOneWidget);
    expect(find.text('SHARED TOTAL BALANCE'), findsOneWidget);
  });

  testWidgets('App opens TransactionDetailBottomSheet on transaction tap and closes it', (WidgetTester tester) async {
    // Force login state to bypass login screen in existing test flows
    isLoggedInNotifier.value = true;

    // Set locale to Portuguese
    localeNotifier.value = const Locale('pt');

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify first transaction is listed (translated under the hood to "Pagamento Freelance")
    final transactionFinder = find.text('Pagamento Freelance');
    expect(transactionFinder, findsOneWidget);

    // Ensure the transaction widget is fully visible and scrollable in screen
    await tester.ensureVisible(transactionFinder);
    await tester.pumpAndSettle();

    // Tap on the transaction to open the detail bottom sheet
    await tester.tap(transactionFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet title is visible in Portuguese
    expect(find.text('Detalhes da Transação'), findsOneWidget);

    // Verify detail row values are visible
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Payment for design system deliverables'), findsOneWidget);
    expect(find.text('Shared Wallet Account'), findsOneWidget);
    expect(find.text('Concluído'), findsOneWidget);

    // Tap the close button to close the bottom sheet
    final closeButtonFinder = find.byIcon(Icons.close_rounded);
    expect(closeButtonFinder, findsOneWidget);
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet is dismissed
    expect(find.text('Detalhes da Transação'), findsNothing);
  });

  testWidgets('App opens TransactionDetailBottomSheet and deletes a transaction', (WidgetTester tester) async {
    // Force login state to bypass login screen in existing test flows
    isLoggedInNotifier.value = true;

    // Set locale to Portuguese
    localeNotifier.value = const Locale('pt');

    // Custom mock client that handles both GET and DELETE
    bool deleteCalled = false;
    final customMockClient = MockClient((request) async {
      if (request.url.path == '/transactions/summary') {
        return http.Response(
          json.encode({'income': 4500.0, 'expenses': 0.0, 'balance': 4500.0}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/transactions/1' && request.method == 'DELETE') {
        deleteCalled = true;
        return http.Response('', 200);
      }
      if (request.url.path == '/transactions') {
        return http.Response(
          json.encode([
            {
              'id': '1',
              'description': 'Freelance Payment',
              'type': 'INCOME',
              'amount': '4500.0',
              'date': '2026-07-05T12:00:00.000Z',
              'category': {'name': 'Income'},
              'paidBy': {'name': 'John Doe'},
              'wallet': {'name': 'Shared Wallet Account'},
              'note': 'Payment for design system deliverables',
              'status': 'COMPLETED'
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final customApiService = ApiService(client: customMockClient);
    await locator.reset();
    locator.registerSingleton<ApiService>(customApiService);
    locator.registerSingleton<TransactionRepository>(TransactionRepository(apiService: customApiService));
    locator.registerSingleton<CategoryRepository>(CategoryRepository(apiService: customApiService));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify transaction is listed (translated under the hood to "Pagamento Freelance")
    final transactionFinder = find.text('Pagamento Freelance');
    expect(transactionFinder, findsOneWidget);

    // Ensure the transaction widget is fully visible and scrollable in screen
    await tester.ensureVisible(transactionFinder);
    await tester.pumpAndSettle();

    // Tap on the transaction to open the detail bottom sheet
    await tester.tap(transactionFinder);
    await tester.pumpAndSettle();

    // Verify "Excluir Transação" button is visible
    final deleteButtonFinder = find.text('Excluir Transação');
    expect(deleteButtonFinder, findsOneWidget);

    // Ensure the delete button is visible (since the bottom sheet may be scrollable)
    await tester.ensureVisible(deleteButtonFinder);
    await tester.pumpAndSettle();

    // Tap the delete button
    await tester.tap(deleteButtonFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog is shown
    expect(find.text('Deseja realmente excluir esta transação? Esta ação não pode ser desfeita.'), findsOneWidget);

    // Tap "Excluir" on the dialog
    final confirmBtnFinder = find.text('Excluir').last;
    await tester.tap(confirmBtnFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet and dialog are closed, and delete was called on API
    expect(deleteCalled, isTrue);
    expect(find.text('Detalhes da Transação'), findsNothing);

    // Verify transaction is removed from list
    expect(find.text('Pagamento Freelance'), findsNothing);
  });

  testWidgets('App handles transaction deletion failure gracefully', (WidgetTester tester) async {
    // Force login state to bypass login screen in existing test flows
    isLoggedInNotifier.value = true;

    // Set locale to Portuguese
    localeNotifier.value = const Locale('pt');

    // Custom mock client that returns 500 Internal Server Error on DELETE
    final customMockClient = MockClient((request) async {
      if (request.url.path == '/transactions/summary') {
        return http.Response(
          json.encode({'income': 4500.0, 'expenses': 0.0, 'balance': 4500.0}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/transactions/1' && request.method == 'DELETE') {
        return http.Response('Internal Server Error', 500);
      }
      if (request.url.path == '/transactions') {
        return http.Response(
          json.encode([
            {
              'id': '1',
              'description': 'Freelance Payment',
              'type': 'INCOME',
              'amount': '4500.0',
              'date': '2026-07-05T12:00:00.000Z',
              'category': {'name': 'Income'},
              'paidBy': {'name': 'John Doe'},
              'wallet': {'name': 'Shared Wallet Account'},
              'note': 'Payment for design system deliverables',
              'status': 'COMPLETED'
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final customApiService = ApiService(client: customMockClient);
    await locator.reset();
    locator.registerSingleton<ApiService>(customApiService);
    locator.registerSingleton<TransactionRepository>(TransactionRepository(apiService: customApiService));
    locator.registerSingleton<CategoryRepository>(CategoryRepository(apiService: customApiService));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify transaction is listed
    final transactionFinder = find.text('Pagamento Freelance');
    expect(transactionFinder, findsOneWidget);

    // Ensure the transaction widget is fully visible and scrollable in screen
    await tester.ensureVisible(transactionFinder);
    await tester.pumpAndSettle();

    // Tap on the transaction to open the detail bottom sheet
    await tester.tap(transactionFinder);
    await tester.pumpAndSettle();

    // Scroll the delete button into view
    final deleteButtonFinder = find.text('Excluir Transação');
    await tester.ensureVisible(deleteButtonFinder);
    await tester.pumpAndSettle();

    // Tap the delete button
    await tester.tap(deleteButtonFinder);
    await tester.pumpAndSettle();

    // Tap "Excluir" on the dialog to confirm
    final confirmBtnFinder = find.text('Excluir').last;
    await tester.tap(confirmBtnFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet is dismissed
    expect(find.text('Detalhes da Transação'), findsNothing);

    // Verify transaction remains in the list (since deletion failed)
    expect(find.text('Pagamento Freelance'), findsOneWidget);
  });

  test('AnalyticsViewModel loads data, scales chart values, and localizes months correctly', () async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/transactions/monthly-spending')) {
        return http.Response(
          json.encode([
            { 'year': 2026, 'month': 1, 'income': 1000.0, 'expense': 500.0 },
            { 'year': 2026, 'month': 2, 'income': 2000.0, 'expense': 1000.0 }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final apiService = ApiService(client: mockClient);
    final transactionRepository = TransactionRepository(apiService: apiService);
    await locator.reset();
    locator.registerSingleton<ApiService>(apiService);
    locator.registerSingleton<TransactionRepository>(transactionRepository);

    final viewModel = AnalyticsViewModel();
    final future = viewModel.loadMonthlySpending(locale: 'en');
    expect(viewModel.isLoading, isTrue);

    await future;
    
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.chartExpenses.length, 6);
    expect(viewModel.chartExpenses.sublist(4), [500.0, 1000.0]);
    expect(viewModel.chartMonths.length, 6);
    expect(viewModel.chartMonths.sublist(4), ['Jan', 'Feb']);
    expect(viewModel.chartValues.length, 6);
    expect(viewModel.chartValues.sublist(4), [0.5, 1.0]);
    expect(viewModel.activeBarIndex, 5);
    expect(viewModel.activeExpense, 1000.0);
    expect(viewModel.activeMonth, 'Feb');
    expect(viewModel.activeComparison['text'], '+100,0%');
    expect(viewModel.activeComparison['isIncrease'], isTrue);

    // Verify activeStartDate and activeEndDate for MONTHLY
    expect(viewModel.activeStartDate, DateTime(2026, 2, 1));
    expect(viewModel.activeEndDate, DateTime(2026, 3, 1).subtract(const Duration(seconds: 1)));

    // Test Portuguese localization
    await viewModel.loadMonthlySpending(locale: 'pt');
    expect(viewModel.chartMonths.sublist(4), ['Jan', 'Fev']);
  });

  test('AnalyticsViewModel activeStartDate and activeEndDate work for Weekly and Yearly timeframes', () async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/transactions/monthly-spending')) {
        if (request.url.query.contains('timeframe=YEARLY')) {
          return http.Response(
            json.encode([
              { 'year': 2025, 'income': 10000.0, 'expense': 5000.0 },
              { 'year': 2026, 'income': 12000.0, 'expense': 6000.0 }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.query.contains('timeframe=WEEKLY')) {
          return http.Response(
            json.encode([
              { 'year': 2026, 'month': 7, 'day': 20, 'income': 500.0, 'expense': 300.0 },
              { 'year': 2026, 'month': 7, 'day': 27, 'income': 600.0, 'expense': 400.0 }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      }
      return http.Response('Not Found', 404);
    });

    final apiService = ApiService(client: mockClient);
    final transactionRepository = TransactionRepository(apiService: apiService);
    await locator.reset();
    locator.registerSingleton<ApiService>(apiService);
    locator.registerSingleton<TransactionRepository>(transactionRepository);

    final viewModel = AnalyticsViewModel();

    // Test YEARLY
    viewModel.setActiveFilter('Yearly');
    await viewModel.loadMonthlySpending(locale: 'en');
    expect(viewModel.activeStartDate, DateTime(2026, 1, 1));
    expect(viewModel.activeEndDate, DateTime(2026, 12, 31, 23, 59, 59));

    // Test WEEKLY
    viewModel.setActiveFilter('Weekly');
    await viewModel.loadMonthlySpending(locale: 'en');
    expect(viewModel.activeStartDate, DateTime(2026, 7, 27));
    expect(viewModel.activeEndDate, DateTime(2026, 7, 27).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)));
  });
}
