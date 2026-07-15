import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';

extension TransactionUI on Transaction {
  IconData get icon {
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
