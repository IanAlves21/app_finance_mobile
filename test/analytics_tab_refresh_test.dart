import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finance_mobile/l10n/app_localizations.dart';
import 'package:app_finance_mobile/repositories/budget_repository.dart';
import 'package:app_finance_mobile/repositories/category_repository.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/services/secure_storage_manager.dart';
import 'package:app_finance_mobile/services/service_locator.dart';
import 'package:app_finance_mobile/tabs/analytics_tab.dart';
import 'package:app_finance_mobile/viewmodels/analytics_view_model.dart';

void main() {
  testWidgets('pull to refresh on Analytics reloads the analytics data', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    SecureStorageManager.useMock = true;
    SecureStorageManager.mockToken = 'mocked_jwt_token';

    int analyticsCalls = 0;
    final mockClient = MockClient((request) async {
      if (request.url.path == '/analytics/monthly-spending') {
        analyticsCalls++;
        return http.Response(
          json.encode([]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/transactions/categories' ||
          request.url.path == '/budgets') {
        return http.Response(json.encode([]), 200);
      }
      return http.Response(json.encode({}), 200);
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
    locator.registerSingleton<BudgetRepository>(
      BudgetRepository(apiService: api),
    );
    locator.registerFactory<AnalyticsViewModel>(() => AnalyticsViewModel());

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AnalyticsTab()),
      ),
    );
    await tester.pumpAndSettle();

    final int callsAfterLoad = analyticsCalls;
    expect(callsAfterLoad, greaterThan(0));
    expect(find.byType(RefreshIndicator), findsOneWidget);

    // Puxa a tela para baixo
    await tester.fling(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(analyticsCalls, greaterThan(callsAfterLoad));
  });

  Future<void> runChartScrollTest(
    WidgetTester tester, {
    required int futureMonths,
    required bool expectCurrentAsFirst,
  }) async {
    SharedPreferences.setMockInitialValues({});
    SecureStorageManager.useMock = true;
    SecureStorageManager.mockToken = 'mocked_jwt_token';

    // Celular estreito
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 6 meses passados + mês atual + meses futuros (parcelas)
    final now = DateTime.now();
    final months = List.generate(7 + futureMonths, (i) {
      final d = DateTime(now.year, now.month - 6 + i, 1);
      return {
        'year': d.year,
        'month': d.month,
        'income': 0,
        'expense': 100 + i,
        'categories': [],
        'byUser': [],
      };
    });

    final mockClient = MockClient((request) async {
      if (request.url.path == '/analytics/monthly-spending') {
        return http.Response(
          json.encode(months),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(json.encode([]), 200);
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
    locator.registerSingleton<BudgetRepository>(
      BudgetRepository(apiService: api),
    );
    locator.registerFactory<AnalyticsViewModel>(() => AnalyticsViewModel());

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AnalyticsTab()),
      ),
    );
    await tester.pumpAndSettle();

    String label(DateTime d) {
      var m = DateFormat('MMM', 'pt').format(d);
      m = m[0].toUpperCase() + m.substring(1);
      return m.endsWith('.') ? m.substring(0, m.length - 1) : m;
    }

    final chart = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    final currentLabel = find.descendant(
      of: chart,
      matching: find.text(label(DateTime(now.year, now.month, 1))),
    );
    final previousLabel = find.descendant(
      of: chart,
      matching: find.text(label(DateTime(now.year, now.month - 1, 1))),
    );

    final Rect chartRect = tester.getRect(chart);
    final Rect currentRect = tester.getRect(currentLabel);

    // Mês atual sempre totalmente visível dentro da área do gráfico
    expect(currentRect.left, greaterThanOrEqualTo(chartRect.left));
    expect(currentRect.right, lessThanOrEqualTo(chartRect.right));

    if (expectCurrentAsFirst) {
      // ...e como primeira barra: o mês anterior ficou à esquerda (acessível rolando)
      expect(currentRect.left - chartRect.left, lessThan(58));
      expect(
        tester.getRect(previousLabel).right,
        lessThanOrEqualTo(chartRect.left + 1),
      );
    }
  }

  testWidgets(
    'chart shows the current month as the first bar when there are enough future months',
    (tester) =>
        runChartScrollTest(tester, futureMonths: 6, expectCurrentAsFirst: true),
  );

  testWidgets(
    'chart keeps the current month fully visible with few future months on narrow screens',
    (tester) => runChartScrollTest(
      tester,
      futureMonths: 2,
      expectCurrentAsFirst: false,
    ),
  );
}
