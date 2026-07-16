import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/service_locator.dart';

class AddTransactionViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;

  AddTransactionViewModel({
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  })  : _transactionRepository = transactionRepository ?? locator<TransactionRepository>(),
        _categoryRepository = categoryRepository ?? locator<CategoryRepository>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _categoryRepository.fetchCategories();
    } catch (e) {
      debugPrint('Erro ao carregar categorias no ViewModel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveTransaction({
    required String description,
    required double amount,
    required String type, // 'INCOME' ou 'EXPENSE'
    String? categoryId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _transactionRepository.createTransaction(
        description: description,
        amount: amount,
        type: type,
        date: DateTime.now().toIso8601String(),
        categoryId: categoryId,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
