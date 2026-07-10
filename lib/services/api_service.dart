import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/transaction.dart';

class ApiService {
  static String get baseUrl {
    // If running on Android emulator, localhost is 10.0.2.2.
    // In other platforms (iOS simulator, Web, Desktop), it's localhost.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<List<Transaction>> fetchTransactions() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/transactions'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw HttpException(
          'Failed to load transactions: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('ApiService error, falling back to mock data: $e');
      // Graceful fallback to mock data!
      return transactionsData;
    }
  }
}
