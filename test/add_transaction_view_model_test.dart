import 'package:flutter_test/flutter_test.dart';
import 'package:app_finance_mobile/viewmodels/add_transaction_view_model.dart';
import 'package:app_finance_mobile/services/service_locator.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/repositories/category_repository.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';
import 'package:app_finance_mobile/models/category.dart';
import 'package:app_finance_mobile/models/transaction.dart';

class FakeCategoryRepository extends CategoryRepository {
  FakeCategoryRepository() : super(apiService: ApiService());

  @override
  Future<List<Category>> fetchCategories() async {
    return [
      const Category(id: 'cat-1', name: 'Food', type: 'EXPENSE'),
      const Category(id: 'cat-2', name: 'Salary', type: 'INCOME'),
    ];
  }

  @override
  Future<Category> createCategory({required String name, required String type, String? icon, String? color}) async {
    return Category(id: 'cat-new', name: name, type: type, icon: icon ?? 'category', color: color ?? '#3b82f6');
  }

  @override
  Future<Category> updateCategory({required String id, String? name, String? type, String? icon, String? color}) async {
    return Category(id: id, name: name ?? 'Default', type: type ?? 'EXPENSE', icon: icon ?? 'category', color: color ?? '#3b82f6');
  }
}

class FakeTransactionRepository extends TransactionRepository {
  bool createCalled = false;
  bool updateCalled = false;

  FakeTransactionRepository() : super(apiService: ApiService());

  @override
  Future<Transaction> createTransaction({
    required String description,
    required double amount,
    required String type,
    required String date,
    String? categoryId,
    String? paymentMethod,
    int? installments,
  }) async {
    createCalled = true;
    return Transaction(
      id: 'tx-1',
      name: description,
      category: 'Food',
      date: date,
      amount: amount,
    );
  }

  @override
  Future<Transaction> updateTransaction({
    required String id,
    required String description,
    required double amount,
    required String type,
    String? categoryId,
    String? paymentMethod,
  }) async {
    updateCalled = true;
    return Transaction(
      id: id,
      name: description,
      category: 'Food',
      date: '2026-07-05',
      amount: amount,
    );
  }
}

void main() {
  group('AddTransactionViewModel Tests', () {
    late FakeCategoryRepository categoryRepo;
    late FakeTransactionRepository transactionRepo;
    late AddTransactionViewModel viewModel;

    setUp(() async {
      categoryRepo = FakeCategoryRepository();
      transactionRepo = FakeTransactionRepository();

      await locator.reset();
      locator.registerSingleton<CategoryRepository>(categoryRepo);
      locator.registerSingleton<TransactionRepository>(transactionRepo);

      viewModel = AddTransactionViewModel();
    });

    test('loadCategories loads and sets category list', () async {
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.categories, isEmpty);

      final future = viewModel.loadCategories();
      expect(viewModel.isLoading, isTrue);

      await future;
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.categories.length, 2);
      expect(viewModel.categories[0].name, 'Food');
    });

    test('saveTransaction delegates to TransactionRepository', () async {
      await viewModel.saveTransaction(
        description: 'Dinner',
        amount: 25.0,
        type: 'EXPENSE',
        categoryId: 'cat-1',
      );

      expect(transactionRepo.createCalled, isTrue);
    });

    test('updateTransaction delegates to TransactionRepository', () async {
      await viewModel.updateTransaction(
        id: 'tx-existing',
        description: 'New Dinner',
        amount: 30.0,
        type: 'EXPENSE',
        categoryId: 'cat-1',
      );

      expect(transactionRepo.updateCalled, isTrue);
    });
  });
}
