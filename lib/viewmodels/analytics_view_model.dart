import 'package:flutter/foundation.dart';

class AnalyticsViewModel extends ChangeNotifier {
  int _activeBarIndex = 4;
  String _activeFilter = 'Monthly';

  final List<double> _chartValues = [0.4, 0.65, 0.35, 0.8, 0.55, 0.9];
  final List<String> _chartMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  final List<double> _chartExpenses = [
    1200.0,
    2100.0,
    1050.0,
    3100.0,
    1850.0,
    3418.0,
  ];

  int get activeBarIndex => _activeBarIndex;
  String get activeFilter => _activeFilter;
  List<double> get chartValues => _chartValues;
  List<String> get chartMonths => _chartMonths;
  List<double> get chartExpenses => _chartExpenses;

  double get activeExpense => _chartExpenses[_activeBarIndex];
  String get activeMonth => _chartMonths[_activeBarIndex];

  void setActiveBarIndex(int index) {
    _activeBarIndex = index;
    notifyListeners();
  }

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }
}
