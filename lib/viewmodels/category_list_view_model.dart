import 'package:flutter/material.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../services/service_locator.dart';

class CategoryListViewModel extends ChangeNotifier {
  final CategoryRepository _categoryRepository = locator<CategoryRepository>();
  List<Category> _categories = [];
  bool _isLoading = true;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _categoryRepository.fetchCategories();
    } catch (e) {
      debugPrint('Error loading categories inside ViewModel: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Com [force] = true, exclui também as transações vinculadas à categoria
  Future<void> deleteCategory(String categoryId, {bool force = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _categoryRepository.deleteCategory(categoryId, force: force);
      // Reload automatically
      _categories = await _categoryRepository.fetchCategories();
    } catch (e) {
      debugPrint('Error deleting category inside ViewModel: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
