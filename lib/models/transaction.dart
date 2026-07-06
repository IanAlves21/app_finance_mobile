import 'package:flutter/material.dart';

class Transaction {
  final int id;
  final String name;
  final String category;
  final String date;
  final double amount;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const Transaction({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

// Mock Transactions List - Expanded to 9 items for testing scrolling effects
const List<Transaction> transactionsData = [
  Transaction(
    id: 1,
    name: "Freelance Payment",
    category: "Income",
    date: "Jul 5, 2026",
    amount: 4500.0,
    icon: Icons.work_outline_rounded,
    iconBg: Color(0xFFDCFCE7),
    iconColor: Color(0xFF16A34A),
  ),
  Transaction(
    id: 2,
    name: "Grocery Store",
    category: "Food",
    date: "Jul 4, 2026",
    amount: -187.5,
    icon: Icons.shopping_cart_outlined,
    iconBg: Color(0xFFFEF3C7),
    iconColor: Color(0xFFD97706),
  ),
  Transaction(
    id: 3,
    name: "Restaurant Dinner",
    category: "Dining",
    date: "Jul 3, 2026",
    amount: -94.2,
    icon: Icons.restaurant_rounded,
    iconBg: Color(0xFFFEE2E2),
    iconColor: Color(0xFFDC2626),
  ),
  Transaction(
    id: 4,
    name: "Car Insurance",
    category: "Transport",
    date: "Jul 2, 2026",
    amount: -320.0,
    icon: Icons.directions_car_rounded,
    iconBg: Color(0xFFEDE9FE),
    iconColor: Color(0xFF7C3AED),
  ),
  Transaction(
    id: 5,
    name: "Netflix Subscription",
    category: "Entertainment",
    date: "Jul 1, 2026",
    amount: -55.90,
    icon: Icons.movie_creation_outlined,
    iconBg: Color(0xFFFEE2E2),
    iconColor: Color(0xFFDC2626),
  ),
  Transaction(
    id: 6,
    name: "Salary Deposit",
    category: "Income",
    date: "Jun 30, 2026",
    amount: 8000.0,
    icon: Icons.savings_rounded,
    iconBg: Color(0xFFDCFCE7),
    iconColor: Color(0xFF16A34A),
  ),
  Transaction(
    id: 7,
    name: "Starbucks Coffee",
    category: "Food",
    date: "Jun 29, 2026",
    amount: -28.50,
    icon: Icons.local_cafe_rounded,
    iconBg: Color(0xFFFEF3C7),
    iconColor: Color(0xFFD97706),
  ),
  Transaction(
    id: 8,
    name: "Shell Gas Station",
    category: "Transport",
    date: "Jun 28, 2026",
    amount: -150.0,
    icon: Icons.local_gas_station_rounded,
    iconBg: Color(0xFFEDE9FE),
    iconColor: Color(0xFF7C3AED),
  ),
  Transaction(
    id: 9,
    name: "SmartFit Gym",
    category: "Others",
    date: "Jun 27, 2026",
    amount: -110.00,
    icon: Icons.fitness_center_rounded,
    iconBg: Color(0xFFE0F2FE),
    iconColor: Color(0xFF0284C7),
  ),
];
