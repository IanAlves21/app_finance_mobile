import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AddTransactionViewModel extends ChangeNotifier {
  final ApiService _apiService;

  AddTransactionViewModel({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> saveTransaction({
    required String description,
    required double amount,
    required String type, // 'INCOME' ou 'EXPENSE'
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.createTransaction(
        description: description,
        amount: amount,
        type: type,
        date: DateTime.now().toIso8601String(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
