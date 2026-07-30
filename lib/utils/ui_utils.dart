import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UIUtils {
  static Color parseHexColor(String hexStr, {Color fallback = AppColors.primarySeed}) {
    try {
      final String cleanHex = hexStr.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  static IconData getIconData(String? iconName) {
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
}
