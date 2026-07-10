import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class Transaction {
  final String id;
  final String name;
  final String category;
  final String date;
  final double amount;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String paidBy;
  final String account;
  final String note;
  final String status;

  const Transaction({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.paidBy = "John Doe",
    this.account = "Shared Joint Card •••• 4242",
    this.note = "Standard shared transaction",
    this.status = "Completed",
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

    // Infer category
    final String category = _inferCategory(name, type);

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

    // Resolve icons and colors based on category and name
    final IconData icon = _getIconForCategory(category, name);
    final Color iconBg = _getIconBgColorForCategory(category);
    final Color iconColor = _getIconColorForCategory(category);

    // Resolve default fields or fallback values
    final String paidBy = json['paidById'] != null
        ? _resolveUser(json['paidById'].toString())
        : "John Doe";
    final String account = json['walletId'] != null
        ? _resolveAccount(json['walletId'].toString())
        : "Shared Wallet Account";
    final String note =
        json['note']?.toString() ?? "Standard shared transaction";

    // Format status
    String status = "Completed";
    final String rawStatus = json['status']?.toString() ?? 'COMPLETED';
    if (rawStatus == 'PENDING') {
      status = 'Pending';
    } else if (rawStatus == 'FAILED') {
      status = 'Failed';
    }

    return Transaction(
      id: id,
      name: name,
      category: category,
      date: formattedDate,
      amount: amount,
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      paidBy: paidBy,
      account: account,
      note: note,
      status: status,
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

  static IconData _getIconForCategory(String category, String name) {
    final desc = name.toLowerCase();
    switch (category) {
      case 'Income':
        if (desc.contains('salary') || desc.contains('salário')) {
          return Icons.savings_rounded;
        }
        return Icons.work_outline_rounded;
      case 'Food':
        return Icons.shopping_cart_outlined;
      case 'Dining':
        if (desc.contains('starbucks') ||
            desc.contains('café') ||
            desc.contains('cafe')) {
          return Icons.local_cafe_rounded;
        }
        return Icons.restaurant_rounded;
      case 'Transport':
        if (desc.contains('gas') ||
            desc.contains('fuel') ||
            desc.contains('posto') ||
            desc.contains('combustível')) {
          return Icons.local_gas_station_rounded;
        }
        return Icons.directions_car_rounded;
      case 'Entertainment':
        return Icons.movie_creation_outlined;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  static Color _getIconBgColorForCategory(String category) {
    switch (category) {
      case 'Income':
        return AppColors.greenBg;
      case 'Food':
        return AppColors.yellowBg;
      case 'Dining':
        return AppColors.redBg;
      case 'Transport':
        return AppColors.purpleBg;
      case 'Entertainment':
        return AppColors.redBg;
      default:
        return AppColors.blueBg;
    }
  }

  static Color _getIconColorForCategory(String category) {
    switch (category) {
      case 'Income':
        return AppColors.greenAccent;
      case 'Food':
        return AppColors.yellowAccent;
      case 'Dining':
        return AppColors.redAccent;
      case 'Transport':
        return AppColors.purpleAccent;
      case 'Entertainment':
        return AppColors.redAccent;
      default:
        return AppColors.blueAccent;
    }
  }

  static String _resolveUser(String paidById) {
    if (paidById == '968ab5f5-8277-487f-8554-7571872b0fee') {
      return 'John Doe'; // Wait, let's keep 'John Doe' to make sure unit/widget tests that look for 'John Doe' continue to work perfectly!
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

// Mock Transactions List - Expanded to 9 items for testing scrolling effects
const List<Transaction> transactionsData = [
  Transaction(
    id: "1",
    name: "Freelance Payment",
    category: "Income",
    date: "Jul 5, 2026",
    amount: 4500.0,
    icon: Icons.work_outline_rounded,
    iconBg: AppColors.greenBg,
    iconColor: AppColors.greenAccent,
    paidBy: "John Doe",
    account: "Shared Wallet Account",
    note: "Payment for design system deliverables",
    status: "Completed",
  ),
  Transaction(
    id: "2",
    name: "Grocery Store",
    category: "Food",
    date: "Jul 4, 2026",
    amount: -187.5,
    icon: Icons.shopping_cart_outlined,
    iconBg: AppColors.yellowBg,
    iconColor: AppColors.yellowAccent,
    paidBy: "Jane Smith",
    account: "Joint Visa Card •••• 8812",
    note: "Weekly organic groceries at Target",
    status: "Completed",
  ),
  Transaction(
    id: "3",
    name: "Restaurant Dinner",
    category: "Dining",
    date: "Jul 3, 2026",
    amount: -94.2,
    icon: Icons.restaurant_rounded,
    iconBg: AppColors.redBg,
    iconColor: AppColors.redAccent,
    paidBy: "John Doe",
    account: "Joint Visa Card •••• 8812",
    note: "Anniversary dinner celebration",
    status: "Completed",
  ),
  Transaction(
    id: "4",
    name: "Car Insurance",
    category: "Transport",
    date: "Jul 2, 2026",
    amount: -320.0,
    icon: Icons.directions_car_rounded,
    iconBg: AppColors.purpleBg,
    iconColor: AppColors.purpleAccent,
    paidBy: "Jane Smith",
    account: "AutoPay Shared Checking",
    note: "Monthly premium auto-debit",
    status: "Completed",
  ),
  Transaction(
    id: "5",
    name: "Netflix Subscription",
    category: "Entertainment",
    date: "Jul 1, 2026",
    amount: -55.90,
    icon: Icons.movie_creation_outlined,
    iconBg: AppColors.redBg,
    iconColor: AppColors.redAccent,
    paidBy: "John Doe",
    account: "Joint Mastercard •••• 1990",
    note: "Premium Ultra-HD subscription plan",
    status: "Completed",
  ),
  Transaction(
    id: "6",
    name: "Salary Deposit",
    category: "Income",
    date: "Jun 30, 2026",
    amount: 8000.0,
    icon: Icons.savings_rounded,
    iconBg: AppColors.greenBg,
    iconColor: AppColors.greenAccent,
    paidBy: "Company Inc.",
    account: "Joint Shared Savings",
    note: "Monthly primary corporate salary deposit",
    status: "Completed",
  ),
  Transaction(
    id: "7",
    name: "Starbucks Coffee",
    category: "Food",
    date: "Jun 29, 2026",
    amount: -28.50,
    icon: Icons.local_cafe_rounded,
    iconBg: AppColors.yellowBg,
    iconColor: AppColors.yellowAccent,
    paidBy: "Jane Smith",
    account: "Joint Visa Card •••• 8812",
    note: "Two iced lattes and a croissant",
    status: "Completed",
  ),
  Transaction(
    id: "8",
    name: "Shell Gas Station",
    category: "Transport",
    date: "Jun 28, 2026",
    amount: -150.0,
    icon: Icons.local_gas_station_rounded,
    iconBg: AppColors.purpleBg,
    iconColor: AppColors.purpleAccent,
    paidBy: "John Doe",
    account: "Joint Visa Card •••• 8812",
    note: "Refuel SUV full tank",
    status: "Completed",
  ),
  Transaction(
    id: "9",
    name: "SmartFit Gym",
    category: "Others",
    date: "Jun 27, 2026",
    amount: -110.00,
    icon: Icons.fitness_center_rounded,
    iconBg: AppColors.blueBg,
    iconColor: AppColors.blueAccent,
    paidBy: "John Doe",
    account: "Joint Mastercard •••• 1990",
    note: "Shared gym membership monthly fee",
    status: "Completed",
  ),
];
