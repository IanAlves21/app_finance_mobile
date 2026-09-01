import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../services/service_locator.dart';
import '../theme/app_colors.dart';
import 'transaction_card.dart';
import 'transaction_skeleton.dart';

class CategoryTransactionsBottomSheet extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final DateTime startDate;
  final DateTime endDate;

  const CategoryTransactionsBottomSheet({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<CategoryTransactionsBottomSheet> createState() =>
      _CategoryTransactionsBottomSheetState();
}

class _CategoryTransactionsBottomSheetState
    extends State<CategoryTransactionsBottomSheet> {
  final TransactionRepository _transactionRepository =
      locator<TransactionRepository>();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final txs = await _transactionRepository.fetchTransactions(
        page: 1,
        limit: 100, // Carrega todos correspondentes
        startDate: widget.startDate.toIso8601String(),
        endDate: widget.endDate.toIso8601String(),
        categoryId: widget.categoryId,
      );
      setState(() {
        _transactions = txs;
      });
    } catch (e) {
      debugPrint('Erro ao carregar transações por categoria: $e');
      setState(() {
        _errorMessage = e is HttpException ? e.message : e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = isDark ? AppColors.slate400 : AppColors.slate600;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 24,
        right: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alça de arrastar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate700 : AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            widget.categoryName,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.transactionsInPeriod,
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Corpo Dinâmico
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: _buildContent(context, subTextColor, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color subTextColor,
    AppLocalizations l10n,
  ) {
    if (_isLoading) {
      return const SingleChildScrollView(
        child: TransactionSkeleton(itemCount: 3),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.redAccent,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadTransactions,
                child: Text(
                  l10n.tryAgain,
                  style: const TextStyle(color: AppColors.primarySeed),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 48,
                color: subTextColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noTransactionsFound,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double totalAmount = _transactions.fold(
      0.0,
      (sum, item) => sum + item.amount.abs(),
    );
    final String localeCode = Localizations.localeOf(context).languageCode;

    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final double percentageOfTotal = totalAmount > 0
            ? (tx.amount.abs() / totalAmount) * 100
            : 0.0;
        final String percentageStr = percentageOfTotal.toStringAsFixed(1);
        final String badgeText = localeCode == 'pt'
            ? '${percentageStr.replaceAll('.', ',')}%'
            : '$percentageStr%';

        return TransactionCard(
          transaction: tx,
          onDelete: () async {
            _loadTransactions();
          },
          badgeText: badgeText,
        );
      },
    );
  }
}
