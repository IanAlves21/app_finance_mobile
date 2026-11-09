import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/services/secure_storage_manager.dart';
import 'package:app_finance_mobile/repositories/category_repository.dart';

void main() {
  group('CategoryRepository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SecureStorageManager.useMock = true;
      SecureStorageManager.mockToken = 'mock_token';
    });

    test('fetchCategories fetches online and caches them', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/transactions/categories');
        return http.Response(
          json.encode([
            {
              'id': 'cat-1',
              'name': 'Food',
              'type': 'EXPENSE',
              'icon': 'shopping-cart',
              'color': '#ff0000',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repo = CategoryRepository(apiService: apiService);

      final categories = await repo.fetchCategories();

      expect(categories.length, 1);
      expect(categories[0].id, 'cat-1');
      expect(categories[0].name, 'Food');

      // Verify it was cached in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cached_categories'), isNotNull);
    });

    test('fetchCategories falls back to cache on timeout/connection failure', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_categories',
        json.encode([
          {
            'id': 'cat-cached',
            'name': 'Cached Food',
            'type': 'EXPENSE',
            'icon': 'shopping-cart',
            'color': '#ff0000',
          }
        ]),
      );

      final mockClient = MockClient((request) async {
        throw const SocketException('Connection failed');
      });

      final apiService = ApiService(client: mockClient);
      final repo = CategoryRepository(apiService: apiService);

      final categories = await repo.fetchCategories();

      expect(categories.length, 1);
      expect(categories[0].id, 'cat-cached');
      expect(categories[0].name, 'Cached Food');
    });

    test('createCategory sends POST and updates cache', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/transactions/categories');
        expect(request.method, 'POST');
        return http.Response(
          json.encode({
            'id': 'cat-new',
            'name': 'Gym',
            'type': 'EXPENSE',
            'icon': 'fitness',
            'color': '#ffffff',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repo = CategoryRepository(apiService: apiService);

      final newCat = await repo.createCategory(
        name: 'Gym',
        type: 'EXPENSE',
        icon: 'fitness',
        color: '#ffffff',
      );

      expect(newCat.id, 'cat-new');
      expect(newCat.name, 'Gym');
    });

    test('deleteCategory throws CategoryHasTransactionsException on 409', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/transactions/categories/cat-1');
        expect(request.url.queryParameters.containsKey('force'), isFalse);
        return http.Response(
          json.encode({
            'statusCode': 409,
            'code': 'CATEGORY_HAS_TRANSACTIONS',
            'transactionCount': 3,
            'message': 'Categoria possui transações',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = CategoryRepository(apiService: ApiService(client: mockClient));

      await expectLater(
        repo.deleteCategory('cat-1'),
        throwsA(
          isA<CategoryHasTransactionsException>()
              .having((e) => e.transactionCount, 'transactionCount', 3),
        ),
      );
    });

    test('deleteCategory with force sends force=true and clears cached transactions', () async {
      SharedPreferences.setMockInitialValues({
        'cached_categories': json.encode([
          {'id': 'cat-1', 'name': 'Food', 'type': 'EXPENSE'},
          {'id': 'cat-2', 'name': 'Gym', 'type': 'EXPENSE'},
        ]),
        'cached_transactions': json.encode([
          {'id': 'tx-1', 'categoryId': 'cat-1'},
          {'id': 'tx-2', 'category': {'id': 'cat-1'}},
          {'id': 'tx-3', 'categoryId': 'cat-2'},
        ]),
      });

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/transactions/categories/cat-1');
        expect(request.url.queryParameters['force'], 'true');
        return http.Response(json.encode({'id': 'cat-1'}), 200);
      });

      final repo = CategoryRepository(apiService: ApiService(client: mockClient));
      await repo.deleteCategory('cat-1', force: true);

      final prefs = await SharedPreferences.getInstance();
      final cats = json.decode(prefs.getString('cached_categories')!) as List;
      final txs = json.decode(prefs.getString('cached_transactions')!) as List;
      expect(cats.map((c) => c['id']), ['cat-2']);
      expect(txs.map((t) => t['id']), ['tx-3']);
    });
  });
}
