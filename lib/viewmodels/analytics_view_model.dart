import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../repositories/transaction_repository.dart';
import '../services/service_locator.dart';

class AnalyticsViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository = locator<TransactionRepository>();

  int _activeBarIndex = 0;
  String _activeFilter = 'Monthly';
  bool _isLoading = false;
  bool _isGeneratingPdf = false;

  final List<double> _chartValues = [];
  final List<String> _chartMonths = [];
  final List<double> _chartExpenses = [];
  List<Map<String, dynamic>> _rawSpendingData = [];

  int get activeBarIndex => _activeBarIndex;
  String get activeFilter => _activeFilter;
  bool get isLoading => _isLoading;
  bool get isGeneratingPdf => _isGeneratingPdf;
  List<double> get chartValues => _chartValues;
  List<String> get chartMonths => _chartMonths;
  List<double> get chartExpenses => _chartExpenses;

  double get activeExpense => _chartExpenses.isNotEmpty && _activeBarIndex < _chartExpenses.length
      ? _chartExpenses[_activeBarIndex]
      : 0.0;

  double get activeIncome {
    if (_rawSpendingData.isEmpty || _activeBarIndex < 0) {
      return 0.0;
    }
    final int rawIndex = _activeBarIndex + 1;
    if (rawIndex >= _rawSpendingData.length) {
      return 0.0;
    }
    final interval = _rawSpendingData[rawIndex];
    return (interval['income'] as num?)?.toDouble() ?? 0.0;
  }

  double get activeSavings => activeIncome - activeExpense;

  double get savingsRate {
    final income = activeIncome;
    if (income <= 0.0) {
      return 0.0;
    }
    return (activeSavings / income) * 100.0;
  }

  String get activeMonth => _chartMonths.isNotEmpty && _activeBarIndex < _chartMonths.length
      ? _chartMonths[_activeBarIndex]
      : '';

  DateTime get activeStartDate {
    if (_rawSpendingData.isEmpty || _activeBarIndex < 0 || _activeBarIndex >= _rawSpendingData.length) {
      return DateTime.now();
    }
    final int rawIndex = _activeBarIndex + 1;
    if (rawIndex >= _rawSpendingData.length) {
      return DateTime.now();
    }
    final interval = _rawSpendingData[rawIndex];
    final String timeframe = _activeFilter.toUpperCase();

    if (timeframe == 'YEARLY') {
      final int year = (interval['year'] as num).toInt();
      return DateTime(year, 1, 1);
    } else if (timeframe == 'WEEKLY') {
      final int year = (interval['year'] as num).toInt();
      final int month = (interval['month'] as num).toInt();
      final int day = (interval['day'] as num).toInt();
      return DateTime(year, month, day);
    } else {
      // MONTHLY
      final int year = (interval['year'] as num).toInt();
      final int month = (interval['month'] as num).toInt();
      return DateTime(year, month, 1);
    }
  }

  DateTime get activeEndDate {
    if (_rawSpendingData.isEmpty || _activeBarIndex < 0 || _activeBarIndex >= _rawSpendingData.length) {
      return DateTime.now();
    }
    final int rawIndex = _activeBarIndex + 1;
    if (rawIndex >= _rawSpendingData.length) {
      return DateTime.now();
    }
    final interval = _rawSpendingData[rawIndex];
    final String timeframe = _activeFilter.toUpperCase();

    if (timeframe == 'YEARLY') {
      final int year = (interval['year'] as num).toInt();
      return DateTime(year, 12, 31, 23, 59, 59);
    } else if (timeframe == 'WEEKLY') {
      final int year = (interval['year'] as num).toInt();
      final int month = (interval['month'] as num).toInt();
      final int day = (interval['day'] as num).toInt();
      final start = DateTime(year, month, day);
      return start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    } else {
      // MONTHLY
      final int year = (interval['year'] as num).toInt();
      final int month = (interval['month'] as num).toInt();
      // Last day of that month
      final nextMonth = DateTime(year, month + 1, 1);
      return nextMonth.subtract(const Duration(seconds: 1));
    }
  }

  /// Retorna a lista de categorias agregadas para o intervalo atualmente selecionado.
  List<Map<String, dynamic>> get activeCategories {
    if (_rawSpendingData.isEmpty || _activeBarIndex < 0 || _activeBarIndex >= _rawSpendingData.length) {
      return [];
    }

    // O gráfico de 6 elementos representa os índices 1 a 6 de _rawSpendingData (que tem 7 elementos)
    final int rawIndex = _activeBarIndex + 1;
    if (rawIndex >= _rawSpendingData.length) {
      return [];
    }

    final interval = _rawSpendingData[rawIndex];
    if (interval['categories'] == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
      (interval['categories'] as List).map((item) => Map<String, dynamic>.from(item))
    );
  }

  /// Retorna o breakdown de gastos por usuário (parceiro) para o intervalo selecionado.
  List<Map<String, dynamic>> get activeUserBreakdown {
    if (_rawSpendingData.isEmpty || _activeBarIndex < 0 || _activeBarIndex >= _rawSpendingData.length) {
      return [];
    }

    final int rawIndex = _activeBarIndex + 1;
    if (rawIndex >= _rawSpendingData.length) {
      return [];
    }

    final interval = _rawSpendingData[rawIndex];
    if (interval['byUser'] == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
      (interval['byUser'] as List).map((item) => Map<String, dynamic>.from(item))
    );
  }

  /// Retorna a porcentagem de variação de gastos do mês ativo comparado ao mês imediatamente anterior.
  Map<String, dynamic> get activeComparison {
    if (_chartExpenses.isEmpty || _activeBarIndex < 0 || _activeBarIndex >= _chartExpenses.length) {
      return {
        'text': '0,0%',
        'isIncrease': false,
        'icon': Icons.remove_rounded,
        'isNeutral': true,
      };
    }

    if (_rawSpendingData.length < 2) {
      return {
        'text': '0,0%',
        'isIncrease': false,
        'icon': Icons.remove_rounded,
        'isNeutral': true,
      };
    }

    // Como buscamos 7 intervalos (ex: 7 meses ou 7 semanas), o gráfico representa os índices 1 a 6 de _rawSpendingData.
    // O item na posição i do gráfico corresponde ao item i + 1 de _rawSpendingData.
    final int rawIndex = _activeBarIndex + 1;
    if (rawIndex >= _rawSpendingData.length) {
      return {
        'text': '0,0%',
        'isIncrease': false,
        'icon': Icons.remove_rounded,
        'isNeutral': true,
      };
    }

    final double currentExpense = (_rawSpendingData[rawIndex]['expense'] as num).toDouble();
    final double prevExpense = (_rawSpendingData[rawIndex - 1]['expense'] as num).toDouble();

    if (prevExpense == 0.0) {
      if (currentExpense == 0.0) {
        return {
          'text': '0,0%',
          'isIncrease': false,
          'icon': Icons.remove_rounded,
          'isNeutral': true,
        };
      } else {
        return {
          'text': '+100,0%',
          'isIncrease': true,
          'icon': Icons.trending_up_rounded,
          'isNeutral': false,
        };
      }
    }

    final double percentage = ((currentExpense - prevExpense) / prevExpense) * 100;
    final String sign = percentage > 0 ? '+' : '';
    final String formattedText = '$sign${percentage.toStringAsFixed(1).replaceAll('.', ',')}%';

    return {
      'text': formattedText,
      'isIncrease': percentage > 0,
      'icon': percentage > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      'isNeutral': percentage == 0.0,
    };
  }

  Future<void> loadMonthlySpending({String locale = 'en'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String timeframe = _activeFilter.toUpperCase(); // 'WEEKLY' | 'MONTHLY' | 'YEARLY'

      // Buscamos 7 intervalos para poder calcular a comparação do primeiro visível (que são 6 colunas)
      final data = await _transactionRepository.fetchMonthlySpending(limit: 7, timeframe: timeframe);
      
      // Se temos menos de 7 intervalos de retorno, completamos o array para 7 elementos
      while (data.length < 7) {
        final DateTime now = DateTime.now();
        final int intervalsAgo = 7 - data.length;
        if (timeframe == 'YEARLY') {
          data.insert(0, {
            'year': now.year - intervalsAgo,
            'income': 0.0,
            'expense': 0.0,
            'categories': [],
            'byUser': [],
          });
        } else if (timeframe == 'WEEKLY') {
          final currentWeekStart = DateTime(now.year, now.month, now.day - now.weekday);
          final d = currentWeekStart.subtract(Duration(days: intervalsAgo * 7));
          data.insert(0, {
            'year': d.year,
            'month': d.month,
            'day': d.day,
            'income': 0.0,
            'expense': 0.0,
            'categories': [],
            'byUser': [],
          });
        } else {
          final d = DateTime(now.year, now.month - intervalsAgo, 1);
          data.insert(0, {
            'year': d.year,
            'month': d.month,
            'income': 0.0,
            'expense': 0.0,
            'categories': [],
            'byUser': [],
          });
        }
      }

      _rawSpendingData = data;
      _chartMonths.clear();
      _chartExpenses.clear();
      _chartValues.clear();

      // O gráfico de 6 colunas vai usar os últimos 6 intervalos da lista de 7 (índices 1 a 6)
      final displayData = data.sublist(1);

      double maxExpense = 0.0;
      for (final item in displayData) {
        final double expense = (item['expense'] as num).toDouble();
        if (expense > maxExpense) {
          maxExpense = expense;
        }
        _chartExpenses.add(expense);

        String formattedMonth = '';
        if (timeframe == 'YEARLY') {
          formattedMonth = item['year'].toString();
        } else if (timeframe == 'WEEKLY') {
          final int year = item['year'] as int;
          final int month = item['month'] as int;
          final int day = item['day'] as int;
          final date = DateTime(year, month, day);
          
          final weekLabel = DateFormat('d/MMM', locale).format(date);
          formattedMonth = weekLabel;
          if (formattedMonth.isNotEmpty) {
            formattedMonth = formattedMonth[0].toUpperCase() + formattedMonth.substring(1);
            if (formattedMonth.endsWith('.')) {
              formattedMonth = formattedMonth.substring(0, formattedMonth.length - 1);
            }
          }
        } else {
          // MONTHLY
          final int month = item['month'] as int;
          final int year = item['year'] as int;
          final date = DateTime(year, month, 1);
          final monthName = DateFormat('MMM', locale).format(date);
          
          formattedMonth = monthName;
          if (formattedMonth.isNotEmpty) {
            formattedMonth = formattedMonth[0].toUpperCase() + formattedMonth.substring(1);
            if (formattedMonth.endsWith('.')) {
              formattedMonth = formattedMonth.substring(0, formattedMonth.length - 1);
            }
          }
        }
        _chartMonths.add(formattedMonth);
      }

      // Calcula os valores proporcionais para o gráfico (altura entre 0.0 e 1.0)
      for (final expense in _chartExpenses) {
        final val = maxExpense > 0 ? (expense / maxExpense) : 0.0;
        _chartValues.add(expense > 0 ? (val < 0.1 ? 0.1 : val) : 0.0);
      }

      // Define como ativo o intervalo atual (mês, semana ou ano atual) de forma inteligente
      if (_chartExpenses.isNotEmpty) {
        _activeBarIndex = _chartExpenses.length - 1; // default fallback (mais recente)
        final DateTime now = DateTime.now();

        for (int i = 0; i < displayData.length; i++) {
          if (timeframe == 'YEARLY') {
            if (displayData[i]['year'] == now.year) {
              _activeBarIndex = i;
              break;
            }
          } else if (timeframe == 'WEEKLY') {
            final currentWeekStart = DateTime(now.year, now.month, now.day - now.weekday);
            final int year = displayData[i]['year'] as int;
            final int month = displayData[i]['month'] as int;
            final int day = displayData[i]['day'] as int;
            final date = DateTime(year, month, day);
            if (date.year == currentWeekStart.year &&
                date.month == currentWeekStart.month &&
                date.day == currentWeekStart.day) {
              _activeBarIndex = i;
              break;
            }
          } else {
            // MONTHLY
            if (displayData[i]['year'] == now.year && displayData[i]['month'] == now.month) {
              _activeBarIndex = i;
              break;
            }
          }
        }
      } else {
        _activeBarIndex = 0;
      }
    } catch (e) {
      debugPrint('Erro ao atualizar ViewModel com gastos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setActiveBarIndex(int index) {
    if (index >= 0 && index < _chartExpenses.length) {
      _activeBarIndex = index;
      notifyListeners();
    }
  }

  void setActiveFilter(String filter, {String locale = 'en'}) {
    _activeFilter = filter;
    loadMonthlySpending(locale: locale);
  }

  Future<void> generatePdfReport({
    required DateTime startDate,
    required DateTime endDate,
    required VoidCallback onUnauthorized,
  }) async {
    _isGeneratingPdf = true;
    notifyListeners();

    try {
      final String startDateStr = startDate.toIso8601String().substring(0, 10);
      final String endDateStr = endDate.toIso8601String().substring(0, 10);

      final Uint8List pdfBytes = await _transactionRepository.fetchReportPdf(
        startDate: startDateStr,
        endDate: endDateStr,
      );

      // Salva o PDF localmente na pasta temporária do dispositivo
      final tempDir = await getTemporaryDirectory();
      final String fileName = 'Relatorio_Financeiro_${startDateStr}_$endDateStr.pdf';
      final File file = File('${tempDir.path}/$fileName');
      
      await file.writeAsBytes(pdfBytes, flush: true);

      // Abre o PDF nativamente
      await OpenFilex.open(file.path);
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        onUnauthorized();
        return;
      }
      debugPrint('Erro ao gerar relatório em PDF no ViewModel: $e');
      rethrow;
    } finally {
      _isGeneratingPdf = false;
      notifyListeners();
    }
  }
}
