import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_skeleton.dart';
import '../widgets/custom_toast.dart';
import '../viewmodels/transaction_history_view_model.dart';
import '../services/service_locator.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late final TransactionHistoryViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = locator<TransactionHistoryViewModel>();
    _scrollController.addListener(_onScroll);
    _initLoad();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _viewModel.loadNextPage().catchError((e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          CustomToast.showError(context, l10n.errorLoadingTransactions);
        }
      });
    }
  }

  Future<void> _initLoad() async {
    try {
      await _viewModel.loadTransactions(isRefresh: true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        CustomToast.showError(context, l10n.errorLoadingTransactions);
      }
    }
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
            initialStartDate: _viewModel.selectedDateRange?.start,
            initialEndDate: _viewModel.selectedDateRange?.end,
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            primaryColor: AppColors.accentOrange,
            onApplyClick: (start, end) {
              _viewModel.setDateRange(
                DateTimeRange(
                  start: start,
                  end: DateTime(end.year, end.month, end.day, 23, 59, 59),
                ),
              );
            },
            onCancelClick: () {
              // No pop needed here either, the package widget handles it internally
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  String _formatDateRange() {
    if (_viewModel.selectedDateRange == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    final DateFormat formatter = DateFormat('dd/MM/yyyy', locale);
    return '${formatter.format(_viewModel.selectedDateRange!.start)} - ${formatter.format(_viewModel.selectedDateRange!.end)}';
  }

  Future<void> _deleteTransaction(String id) async {
    try {
      await _viewModel.deleteTransaction(id);
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffold
          : AppColors.lightScaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark
              ? AppColors.darkScaffold
              : AppColors.lightScaffold,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
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
          l10n.transactionHistory,
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
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Column(
              children: [
                // Filter Pill Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: InkWell(
                    onTap: _selectCustomRange,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkSlate.withValues(
                              alpha: isDark ? 0.2 : 0.04,
                            ),
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
                                  l10n.selectedPeriod,
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
                  child: _viewModel.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: TransactionSkeleton(itemCount: 5),
                        )
                      : _viewModel.transactions.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noTransactionsInPeriod,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          itemCount:
                              _viewModel.transactions.length +
                              (_viewModel.hasMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == _viewModel.transactions.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.accentOrange,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final tx = _viewModel.transactions[index];
                            return TransactionCard(
                              transaction: tx,
                              onDelete: () => _deleteTransaction(tx.id),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
