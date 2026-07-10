import 'package:flutter/foundation.dart';

import '../theme/app_colors.dart';

class WalletsViewModel extends ChangeNotifier {
  int _activeCardIndex = 0;

  final List<Map<String, dynamic>> _cards = [
    {
      'holder': 'Lucas Shared',
      'number': '•••• •••• •••• 4820',
      'balance': 'R\$ 18.231,50',
      'expiry': '12/31',
      'colors': [AppColors.slate800, AppColors.slate900],
      'brand': 'VISA',
    },
    {
      'holder': 'Mariana Shared',
      'number': '•••• •••• •••• 9210',
      'balance': 'R\$ 6.150,00',
      'expiry': '08/30',
      'colors': [AppColors.indigoAccent, AppColors.indigoBg],
      'brand': 'Mastercard',
    },
  ];

  int get activeCardIndex => _activeCardIndex;
  List<Map<String, dynamic>> get cards => _cards;

  void setActiveCardIndex(int index) {
    _activeCardIndex = index;
    notifyListeners();
  }
}
