import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finance_mobile/l10n/app_localizations.dart';
import 'package:app_finance_mobile/main.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/services/secure_storage_manager.dart';
import 'package:app_finance_mobile/services/service_locator.dart';
import 'package:app_finance_mobile/widgets/category_transactions_bottom_sheet.dart';

void main() {
  testWidgets(
    'deleting from category breakdown calls the API and removes all installments',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      SecureStorageManager.useMock = true;
      SecureStorageManager.mockToken = 'mocked_jwt_token';

      final List<String> deleteCalls = [];
      Map<String, dynamic> tx(String id, String description) => {
        'id': id,
        'description': description,
        'type': 'EXPENSE',
        'amount': '100.0',
        'date': '2026-12-09T12:00:00.000Z',
        'categoryId': 'cat-1',
        'category': {'id': 'cat-1', 'name': 'Mercado'},
        'paidBy': {'name': 'Ian'},
        'paymentMethod': 'CREDIT',
        'status': 'COMPLETED',
      };

      final mockClient = MockClient((request) async {
        if (request.method == 'DELETE') {
          deleteCalls.add(request.url.path);
          return http.Response(
            json.encode({
              'id': 'tx-2',
              'deletedIds': ['tx-2', 'tx-3'],
            }),
            200,
          );
        }
        if (request.url.path == '/transactions') {
          return http.Response(
            json.encode([tx('tx-2', 'Compra (2/3)'), tx('tx-3', 'Compra (3/3)')]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiService(client: mockClient);
      await locator.reset();
      locator.registerSingleton<ApiService>(api);
      locator.registerSingleton<TransactionRepository>(
        TransactionRepository(apiService: api),
      );

      final int refreshBefore = transactionRefreshNotifier.value;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CategoryTransactionsBottomSheet(
              categoryId: 'cat-1',
              categoryName: 'Mercado',
              startDate: DateTime(2026, 12, 1),
              endDate: DateTime(2026, 12, 31),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Compra'), findsNWidgets(2));

      // Abre o detalhe da parcela 2/3 e exclui
      await tester.tap(find.textContaining('Compra').first);
      await tester.pumpAndSettle();
      final deleteButton = find.widgetWithText(ElevatedButton, 'Excluir Transação');
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Diálogo avisa que todas as parcelas serão excluídas
      expect(find.textContaining('Todas as 3 parcelas'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(deleteCalls, ['/transactions/tx-2']);
      expect(find.textContaining('Compra'), findsNothing);
      expect(transactionRefreshNotifier.value, greaterThan(refreshBefore));
    },
  );
}
