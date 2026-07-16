import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';

extension TransactionUI on Transaction {
  Color _parseHexColor(String hexStr) {
    try {
      final String cleanHex = hexStr.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return AppColors.primarySeed;
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'briefcase':
      case 'savings':
        return Icons.savings_rounded;
      case 'shopping-cart':
      case 'food':
        return Icons.shopping_cart_outlined;
      case 'restaurant':
      case 'dining':
        return Icons.restaurant_rounded;
      case 'directions-car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'money':
      case 'monetization-on':
        return Icons.monetization_on_outlined;
      case 'subscriptions':
      case 'streaming':
        return Icons.subscriptions_rounded;
      case 'home':
      case 'rent':
        return Icons.home_outlined;
      case 'medical':
      case 'health':
        return Icons.medical_services_outlined;
      case 'school':
      case 'education':
        return Icons.school_outlined;
      case 'pets':
      case 'pet':
        return Icons.pets_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  IconData get icon {
    if (categoryIcon != null) {
      return _getIconData(categoryIcon);
    }
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

  Color get iconBg {
    if (categoryColor != null) {
      return _parseHexColor(categoryColor!).withOpacity(0.15);
    }
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

  Color get iconColor {
    if (categoryColor != null) {
      return _parseHexColor(categoryColor!);
    }
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
}
