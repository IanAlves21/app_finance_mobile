import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finance_mobile/l10n/app_localizations.dart';
import 'package:app_finance_mobile/repositories/category_repository.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/services/secure_storage_manager.dart';
import 'package:app_finance_mobile/services/service_locator.dart';
import 'package:app_finance_mobile/viewmodels/add_transaction_view_model.dart';
import 'package:app_finance_mobile/widgets/add_transaction_bottom_sheet.dart';
import 'package:app_finance_mobile/widgets/interactive_card.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SecureStorageManager.useMock = true;
    SecureStorageManager.mockToken = 'mocked_jwt_token';

    final mockClient = MockClient((request) async {
      if (request.url.path == '/transactions/categories') {
        return http.Response(
          json.encode([
            {
              'id': 'cat-exp',
              'name': 'Mercado',
              'type': 'EXPENSE',
              'icon': 'shopping-cart',
              'color': '#F97316',
            },
          ]),
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
    locator.registerSingleton<CategoryRepository>(
      CategoryRepository(apiService: api),
    );
    locator.registerFactory<AddTransactionViewModel>(
      () => AddTransactionViewModel(),
    );
  });

  VoidCallback? saveOnTap(WidgetTester tester) => tester
      .widget<InteractiveCard>(find.byKey(const Key('save_transaction_button')))
      .onTap;

  testWidgets(
    'save button is only enabled when all fields are filled',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: AddTransactionBottomSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Category is auto-selected, but description, amount and payment are empty
      expect(saveOnTap(tester), isNull);

      await tester.enterText(find.byType(TextField).at(0), 'Feira');
      await tester.pump();
      expect(saveOnTap(tester), isNull);

      await tester.enterText(find.byType(TextField).at(1), '2500');
      await tester.pump();
      // Despesa ainda sem forma de pagamento
      expect(saveOnTap(tester), isNull);

      await tester.ensureVisible(find.text('Pix'));
      await tester.tap(find.text('Pix'));
      await tester.pump();
      expect(saveOnTap(tester), isNotNull);

      // Apagar a descrição volta a desabilitar
      await tester.enterText(find.byType(TextField).at(0), '   ');
      await tester.pump();
      expect(saveOnTap(tester), isNull);
    },
  );
}
