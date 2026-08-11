import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final String name;
  final String category;
  final String date;
  final double amount;
  final String paidBy;
  final String account;
  final String note;
  final String status;
  final String? categoryIcon;
  final String? categoryColor;
  final String? paymentMethod;

  const Transaction({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    this.paidBy = "John Doe",
    this.account = "Shared Joint Card •••• 4242",
    this.note = "Standard shared transaction",
    this.status = "Completed",
    this.categoryIcon,
    this.categoryColor,
    this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? '';
    final String name =
        json['description']?.toString() ?? 'Untitled Transaction';
    final String type = json['type']?.toString() ?? 'EXPENSE';

    // Parse amount
    final double rawAmount =
        double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;
    final double amount = (type == 'INCOME') ? rawAmount : -rawAmount;

    // Parse category
    final String category = json['category'] != null && json['category']['name'] != null
        ? json['category']['name'].toString()
        : _inferCategory(name, type);

    // Format date
    String formattedDate = '';
    try {
      final DateTime? parsedDate = DateTime.tryParse(
        json['date']?.toString() ?? '',
      );
      if (parsedDate != null) {
        formattedDate = DateFormat('MMM d, yyyy', 'en_US').format(parsedDate);
      } else {
        formattedDate = json['date']?.toString() ?? '';
      }
    } catch (_) {
      formattedDate = json['date']?.toString() ?? '';
    }

    // Resolve default fields or fallback values
    final String paidBy = json['paidBy'] != null && json['paidBy']['name'] != null
        ? json['paidBy']['name'].toString()
        : (json['paidById'] != null
            ? _resolveUser(json['paidById'].toString())
            : "John Doe");
            
    final String account = json['wallet'] != null && json['wallet']['name'] != null
        ? json['wallet']['name'].toString()
        : (json['walletId'] != null
            ? _resolveAccount(json['walletId'].toString())
            : "Shared Wallet Account");
            
    final String note = json['note']?.toString() ?? "";

    // Format status
    String status = "Completed";
    final String rawStatus = json['status']?.toString() ?? 'COMPLETED';
    if (rawStatus == 'PENDING') {
      status = 'Pending';
    } else if (rawStatus == 'FAILED') {
      status = 'Failed';
    }

    final String? categoryIcon = json['category'] != null ? json['category']['icon']?.toString() : null;
    final String? categoryColor = json['category'] != null ? json['category']['color']?.toString() : null;
    final String? paymentMethod = json['paymentMethod']?.toString();

    return Transaction(
      id: id,
      name: name,
      category: category,
      date: formattedDate,
      amount: amount,
      paidBy: paidBy,
      account: account,
      note: note,
      status: status,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      paymentMethod: paymentMethod,
    );
  }

  static String _inferCategory(String description, String type) {
    if (type == 'INCOME') return 'Income';
    final desc = description.toLowerCase();
    if (desc.contains('grocery') ||
        desc.contains('supermercado') ||
        desc.contains('target') ||
        desc.contains('mercado') ||
        desc.contains('food')) {
      return 'Food';
    }
    if (desc.contains('restaurant') ||
        desc.contains('dinner') ||
        desc.contains('restaurante') ||
        desc.contains('starbucks') ||
        desc.contains('café') ||
        desc.contains('cafe') ||
        desc.contains('jantar')) {
      return 'Dining';
    }
    if (desc.contains('car') ||
        desc.contains('insurance') ||
        desc.contains('gas') ||
        desc.contains('fuel') ||
        desc.contains('posto') ||
        desc.contains('combustível') ||
        desc.contains('uber') ||
        desc.contains('transport') ||
        desc.contains('carro')) {
      return 'Transport';
    }
    if (desc.contains('netflix') ||
        desc.contains('subscription') ||
        desc.contains('spotify') ||
        desc.contains('disney') ||
        desc.contains('cinema') ||
        desc.contains('filme') ||
        desc.contains('entertainment') ||
        desc.contains('lazer')) {
      return 'Entertainment';
    }
    return 'Others';
  }

  static String _resolveUser(String paidById) {
    if (paidById == '968ab5f5-8277-487f-8554-7571872b0fee') {
      return 'John Doe';
    }
    if (paidById.endsWith('fee') || paidById.contains('lucas')) {
      return 'Lucas';
    }
    return 'Mariana';
  }

  static String _resolveAccount(String walletId) {
    if (walletId == 'ac149e49-2f12-4fd3-8aeb-55fd3f3d8655') {
      return 'Shared Wallet Account';
    }
    if (walletId.hashCode % 2 == 0) {
      return 'Joint Visa Card •••• 8812';
    }
    return 'Joint Mastercard •••• 1990';
  }
}
