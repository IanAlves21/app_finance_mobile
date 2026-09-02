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
  });
}
