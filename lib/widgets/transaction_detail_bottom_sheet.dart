import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_extension.dart';
import '../utils/transaction_ui_extension.dart';
import '../utils/currency_formatter.dart';
import 'custom_toast.dart';

class TransactionDetailBottomSheet extends StatefulWidget {
  final Transaction transaction;
  final Future<void> Function()? onDelete;

  const TransactionDetailBottomSheet({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  @override
  State<TransactionDetailBottomSheet> createState() =>
      _TransactionDetailBottomSheetState();
}

class _TransactionDetailBottomSheetState
    extends State<TransactionDetailBottomSheet> {
  bool _isDeleting = false;

  Transaction get transaction => widget.transaction;
  Future<void> Function()? get onDelete => widget.onDelete;

  String _getCategoryTranslation(String category, AppLocalizations l10n) {
    switch (category.toLowerCase()) {
      case 'income':
        return l10n.income;
      case 'food':
        return l10n.food;
      case 'dining':
        return l10n.dining;
      case 'transport':
      case 'transportation':
        return l10n.transport;
      default:
        return category;
    }
  }

  String _getPaymentMethodTranslation(String? method) {
    switch (method) {
      case 'CREDIT':
        return 'Cartão de Crédito';
      case 'DEBIT':
        return 'Cartão de Débito';
      case 'PIX':
        return 'Pix';
      case 'CASH':
        return 'Dinheiro';
      default:
        return 'Outro';
    }
  }

  IconData _getPaymentMethodIcon(String? method) {
    switch (method) {
      case 'CREDIT':
        return Icons.credit_card_rounded;
      case 'DEBIT':
        return Icons.credit_card_outlined;
      case 'PIX':
        return Icons.qr_code_rounded;
      case 'CASH':
        return Icons.payments_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Future<bool> _showConfirmDeleteDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color modalBgColor = isDark ? AppColors.darkCard : Colors.white;
    final Color textColor = isDark ? Colors.white : AppColors.darkSlate;
    final Color subTextColor = isDark ? AppColors.slate400 : AppColors.slate600;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              decoration: BoxDecoration(
                color: modalBgColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular icon header
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3F1B1F) : AppColors.redBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: AppColors.redAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    l10n.deleteTransaction,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Message Body
                  Text(
                    l10n.deleteTransactionConfirm,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Confirm Delete button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.delete,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Dynamic styles based on theme
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7A99); // Slate 400 vs Slate 600
    final Color cardColor = theme.cardColor;
    final Color detailBgColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF8F9FB);
    final Color iconBgColor = isDark
        ? const Color(0xFF222E45)
        : const Color(0xFFEDEEF3);
    final Color rowDividerColor = isDark
        ? const Color(0xFF2E3B52)
        : const Color(0xFFEDEEF3);

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isPositive = transaction.amount > 0;

    // Lógica para detectar e formatar parcelas com regex (ex: "Compra (1/3)")
    final regex = RegExp(r'\((\d+)\/(\d+)\)');
    final match = regex.firstMatch(transaction.name);
    String? installmentValue;
    String? totalPurchaseValue;

    if (match != null) {
      final current = int.parse(match.group(1)!);
      final total = int.parse(match.group(2)!);
      installmentValue = '$current de $total';

      // Estima o valor total original da compra multiplicando o valor absoluto pela quantidade de parcelas
      final double absoluteAmount = transaction.amount.abs();
      final double totalOriginalAmount = absoluteAmount * total;
      final double signedTotalAmount = transaction.amount > 0
          ? totalOriginalAmount
          : -totalOriginalAmount;

      totalPurchaseValue = CurrencyFormatter.formatBalanceParts(
        signedTotalAmount,
      ).join();
    }

    // Define detail rows mapping
    final List<Map<String, dynamic>> detailRows = [
      {
        'icon': Icons.tag_rounded,
        'label': l10n.categoryLabel,
        'value': _getCategoryTranslation(transaction.category, l10n),
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': l10n.dateLabel,
        'value': transaction.date,
      },
      {
        'icon': Icons.person_rounded,
        'label': l10n.paidByLabel,
        'value': transaction.paidBy,
      },
      {
        'icon': Icons.credit_card_rounded,
        'label': l10n.accountLabel,
        'value': transaction.account,
      },
      if (transaction.paymentMethod != null)
        {
          'icon': _getPaymentMethodIcon(transaction.paymentMethod),
          'label': 'Forma de Pagamento',
          'value': _getPaymentMethodTranslation(transaction.paymentMethod),
        },
      if (installmentValue != null) ...[
        {
          'icon': Icons.layers_rounded,
          'label': 'Parcela',
          'value': installmentValue,
        },
        {
          'icon': Icons.shopping_bag_rounded,
          'label': 'Valor Total da Compra',
          'value': totalPurchaseValue ?? '',
        },
      ],
      if (transaction.note.trim().isNotEmpty &&
          transaction.note != 'Standard shared transaction')
        {
          'icon': Icons.description_rounded,
          'label': l10n.noteLabel,
          'value': transaction.note,
        },
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: bottomPadding + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Indicator Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2E3B52)
                      : const Color(0xFFE2E5EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.transactionDetails,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF222E45)
                          : const Color(0xFFF0F1F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: subTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: isPositive
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF166534), Color(0xFF16A34A)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                      ),
              ),
              child: Row(
                children: [
                  // Circular Transaction Icon Container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      transaction.icon,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Texts Details column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPositive
                              ? l10n.income.toUpperCase()
                              : l10n.expense.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatBalanceParts(
                            transaction.amount,
                          ).join(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.getTransactionName(transaction.name),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detail Rows Card Container
            Container(
              decoration: BoxDecoration(
                color: detailBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: List.generate(detailRows.length, (index) {
                  final row = detailRows[index];
                  final isLast = index == detailRows.length - 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: rowDividerColor,
                                width: 1,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        // Detail Row Icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            row['icon'] as IconData,
                            size: 15,
                            color: subTextColor,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Label
                        Text(
                          row['label'] as String,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Value
                        Expanded(
                          child: Text(
                            row['value'] as String,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Status Badge Pill
            Center(
              child: () {
                final bool isPending = transaction.status == 'Pending';
                final Color badgeBgColor = isPending
                    ? (isDark
                          ? const Color(0xFF78350F)
                          : const Color(0xFFFEF3C7))
                    : (isDark
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFDCFCE7));
                final Color badgeTextColor = isPending
                    ? const Color(0xFFD97706)
                    : const Color(0xFF16A34A);
                final String statusText = isPending
                    ? (Localizations.localeOf(context).languageCode == 'pt'
                          ? 'Pendente'
                          : 'Pending')
                    : l10n.completedStatus;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: badgeTextColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }(),
            ),
            if (onDelete != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isDeleting
                    ? null
                    : () async {
                        final confirm = await _showConfirmDeleteDialog(
                          context,
                          l10n,
                        );
                        if (confirm && context.mounted) {
                          setState(() {
                            _isDeleting = true;
                          });
                          try {
                            await onDelete!();
                            if (context.mounted) {
                              Navigator.pop(context); // Close bottom sheet
                              CustomToast.showSuccess(
                                context,
                                l10n.transactionDeleteSuccess,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(
                                context,
                              ); // Close bottom sheet first so the error toast is visible on the home screen
                              CustomToast.showError(
                                context,
                                l10n.transactionDeleteError,
                              );
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF991B1B)
                      : const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.deleteTransaction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
