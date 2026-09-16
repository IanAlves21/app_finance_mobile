import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UIUtils {
  static String sanitizeErrorMessage(dynamic error, {String? defaultMessage}) {
    if (error == null) return defaultMessage ?? 'Ocorreu um erro inesperado';
    
    final String errStr = error.toString();
    
    // Tenta decodificar se a mensagem for ou contiver JSON bruto
    if (errStr.contains('{') && errStr.contains('}')) {
      try {
        final startIndex = errStr.indexOf('{');
        final endIndex = errStr.lastIndexOf('}');
        final jsonPart = errStr.substring(startIndex, endIndex + 1);
        final decoded = json.decode(jsonPart);
        if (decoded is Map) {
          if (decoded.containsKey('message')) {
            final msg = decoded['message'];
            if (msg is List) {
              return msg.join(', ');
            }
            final String msgStr = msg.toString();
            // Suporta JSONs aninhados de forma recursiva
            if (msgStr.contains('{') && msgStr.contains('}')) {
              return sanitizeErrorMessage(msgStr, defaultMessage: defaultMessage);
            }
            return msgStr;
          } else if (decoded.containsKey('error')) {
            final err = decoded['error'];
            if (err is Map && err.containsKey('message')) {
              return err['message'].toString();
            }
            if (err is String) {
              return err;
            }
          } else if (decoded.containsKey('reply')) {
            return decoded['reply'].toString();
          }
        }
      } catch (_) {}
    }
    
    // Filtros de erros comuns de conexão
    if (errStr.contains('SocketException') || 
        errStr.contains('Connection failed') || 
        errStr.contains('Network') || 
        errStr.contains('Connection refused') ||
        errStr.contains('Failed host lookup')) {
      return 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.';
    }
    
    if (errStr.contains('TimeoutException') || errStr.contains('timeout')) {
      return 'A conexão com o servidor expirou. Por favor, tente novamente.';
    }
    
    // Remove prefixos indesejados de exceção do Flutter/Dart
    String cleanMsg = errStr
        .replaceAll('HttpException:', '')
        .replaceAll('HttpException: ', '')
        .replaceAll('Exception:', '')
        .replaceAll('Exception: ', '')
        .trim();
        
    // Caso a mensagem seja muito técnica ou vazia, substitui por um texto amigável
    final lower = cleanMsg.toLowerCase();
    if (cleanMsg.isEmpty || 
        cleanMsg.length > 150 || 
        lower.contains('internal server error') || 
        lower.contains('prisma') || 
        lower.contains('database') || 
        lower.contains('sql') || 
        lower.contains('typeerror') || 
        lower.contains('failed to parse')) {
      return defaultMessage ?? 'Não foi possível processar sua solicitação no momento. Por favor, tente novamente mais tarde.';
    }
    
    return cleanMsg;
  }

  static Color parseHexColor(
    String hexStr, {
    Color fallback = AppColors.primarySeed,
  }) {
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
