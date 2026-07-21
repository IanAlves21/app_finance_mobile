import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../services/service_locator.dart';
import '../theme/app_colors.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_skeleton.dart';
import '../widgets/custom_toast.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TransactionRepository _transactionRepository = locator<TransactionRepository>();
  final List<Transaction> _transactions = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;

  // Pagination states
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadMoreLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Default to the current month's boundaries
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
    _scrollController.addListener(_onScroll);
    _loadTransactions(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadTransactions({bool isRefresh = true}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _transactions.clear();
      });
    } else {
      setState(() {
        _isLoadMoreLoading = true;
      });
    }

    try {
      final startIso = _selectedDateRange?.start.toIso8601String();
      final endIso = _selectedDateRange?.end.toIso8601String();

      final fetched = await _transactionRepository.fetchTransactions(
        page: _currentPage,
        limit: 15, // Dynamic small paging
        startDate: startIso,
        endDate: endIso,
      );

      if (fetched.length < 15) {
        _hasMore = false;
      }

      setState(() {
        _transactions.addAll(fetched);
        _isLoading = false;
        _isLoadMoreLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadMoreLoading = false;
      });
      if (mounted) {
        CustomToast.showError(
          context,
          Localizations.localeOf(context).languageCode == 'pt'
              ? 'Erro ao carregar transações.'
              : 'Error loading transactions.',
        );
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadMoreLoading || !_hasMore || _isLoading) return;
    setState(() {
      _currentPage++;
    });
    await _loadTransactions(isRefresh: false);
  }

  Future<void> _selectCustomRange() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showGeneralDialog<DateTimeRange>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.center,
          child: CustomDateRangePicker(
            minimumDate: DateTime(2020),
            maximumDate: DateTime(2030),
            initialStartDate: _selectedDateRange?.start,
            initialEndDate: _selectedDateRange?.end,
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            primaryColor: AppColors.accentOrange,
            onApplyClick: (start, end) {
              setState(() {
                _selectedDateRange = DateTimeRange(
                  start: start,
                  end: DateTime(end.year, end.month, end.day, 23, 59, 59),
                );
              });
              Navigator.pop(context); // Close dialog
              _loadTransactions(isRefresh: true);
            },
            onCancelClick: () {
              Navigator.pop(context); // Close dialog on cancel
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  String _formatDateRange() {
    if (_selectedDateRange == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    final DateFormat formatter = DateFormat('dd/MM/yyyy', locale);
    return '${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}';
  }

  Future<void> _deleteTransaction(String id) async {
    try {
      await _transactionRepository.deleteTransaction(id);
      setState(() {
        _transactions.removeWhere((tx) => tx.id == id);
      });
    } catch (e) {
      debugPrint('Error deleting transaction in history: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark ? AppColors.slate400 : AppColors.slate600;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          Localizations.localeOf(context).languageCode == 'pt'
              ? 'Histórico de Transações'
              : 'Transaction History',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
          // Filter Pill Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: InkWell(
              onTap: _selectCustomRange,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkSlate.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.accentOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Localizations.localeOf(context).languageCode == 'pt'
                                ? 'PERÍODO SELECIONADO'
                                : 'SELECTED PERIOD',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateRange(),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: subTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Transactions List Area
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: TransactionSkeleton(itemCount: 5),
                  )
                : _transactions.isEmpty
                    ? Center(
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'pt'
                              ? 'Nenhuma transação neste período'
                              : 'No transactions found in this period',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _transactions.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == _transactions.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                                  ),
                                ),
                              ),
                            );
                          }
                          final tx = _transactions[index];
                          return TransactionCard(
                            transaction: tx,
                            onDelete: () => _deleteTransaction(tx.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
    );
  }
}
