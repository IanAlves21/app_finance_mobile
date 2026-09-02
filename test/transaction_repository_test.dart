import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/services/secure_storage_manager.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';

void main() {
  group('TransactionRepository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SecureStorageManager.useMock = true;
      SecureStorageManager.mockToken = 'mock_token';
    });

    test('fetchTransactions fetches online and caches them', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/transactions');
        return http.Response(
          json.encode([
            {
              'id': 'tx-1',
              'description': 'Freelance Payment',
              'type': 'INCOME',
              'amount': '4500.0',
              'date': '2026-07-05T12:00:00.000Z',
              'category': {
                'id': 'cat-1',
                'name': 'Income',
                'type': 'INCOME',
                'icon': 'briefcase',
                'color': '#4CAF50',
              },
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repo = TransactionRepository(apiService: apiService);

      final list = await repo.fetchTransactions();

      expect(list.length, 1);
      expect(list[0].id, 'tx-1');
      expect(list[0].name, 'Freelance Payment');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cached_transactions'), isNotNull);
    });

    test('fetchTransactions falls back to cache on timeout/connection failure', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_transactions',
        json.encode([
          {
            'id': 'tx-cached',
            'description': 'Cached Lunch',
            'type': 'EXPENSE',
            'amount': '-15.0',
            'date': '2026-07-05T12:00:00.000Z',
            'category': {
              'id': 'cat-2',
              'name': 'Dining',
              'type': 'EXPENSE',
              'icon': 'restaurant',
              'color': '#ffffff',
            },
          }
        ]),
      );

      final mockClient = MockClient((request) async {
        throw const SocketException('No Internet');
      });

      final apiService = ApiService(client: mockClient);
      final repo = TransactionRepository(apiService: apiService);

      final list = await repo.fetchTransactions();

      expect(list.length, 1);
      expect(list[0].id, 'tx-cached');
      expect(list[0].name, 'Cached Lunch');
    });

    test('createTransaction sends POST online', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/transactions');
        expect(request.method, 'POST');
        return http.Response(
          json.encode({
            'id': 'tx-new',
            'description': 'Water bill',
            'type': 'EXPENSE',
            'amount': '-50.0',
            'date': '2026-07-15T12:00:00.000Z',
            'category': {
              'id': 'cat-3',
              'name': 'Utilities',
              'type': 'EXPENSE',
              'icon': 'home',
              'color': '#ff0000',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repo = TransactionRepository(apiService: apiService);

      final result = await repo.createTransaction(
        description: 'Water bill',
        amount: 50.0,
        type: 'EXPENSE',
        date: '2026-07-15T12:00:00.000Z',
      );

      expect(result.id, 'tx-new');
      expect(result.name, 'Water bill');
    });

    test('updateTransaction sends PATCH online and updates cache', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_transactions',
        json.encode([
          {
            'id': 'tx-edit',
            'description': 'Original name',
            'type': 'EXPENSE',
            'amount': '-20.0',
            'date': '2026-07-15T12:00:00.000Z',
            'category': {
              'id': 'cat-3',
              'name': 'Utilities',
              'type': 'EXPENSE',
              'icon': 'home',
              'color': '#ff0000',
            },
          }
        ]),
      );

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/transactions/tx-edit');
        expect(request.method, 'PATCH');
        return http.Response(
          json.encode({
            'id': 'tx-edit',
            'description': 'Edited name',
            'type': 'EXPENSE',
            'amount': '-25.0',
            'date': '2026-07-15T12:00:00.000Z',
            'category': {
              'id': 'cat-3',
              'name': 'Utilities',
              'type': 'EXPENSE',
              'icon': 'home',
              'color': '#ff0000',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final repo = TransactionRepository(apiService: apiService);

      final result = await repo.updateTransaction(
        id: 'tx-edit',
        description: 'Edited name',
        amount: 25.0,
        type: 'EXPENSE',
      );

      expect(result.id, 'tx-edit');
      expect(result.name, 'Edited name');

      // Verify cache has been updated
      final cachedString = prefs.getString('cached_transactions')!;
      final List<dynamic> list = json.decode(cachedString);
      expect(list[0]['description'], 'Edited name');
    });

    test('deleteTransaction sends DELETE online', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/transactions/tx-delete');
        expect(request.method, 'DELETE');
        return http.Response('{}', 200);
      });

      final apiService = ApiService(client: mockClient);
      final repo = TransactionRepository(apiService: apiService);

      await repo.deleteTransaction('tx-delete');
    });
  });
}
