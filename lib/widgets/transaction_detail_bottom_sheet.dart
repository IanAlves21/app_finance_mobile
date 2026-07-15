import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_extension.dart';
import '../utils/transaction_ui_extension.dart';
import '../utils/currency_formatter.dart';

class TransactionDetailBottomSheet extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailBottomSheet({
    super.key,
    required this.transaction,
  });

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

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Dynamic styles based on theme
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7A99); // Slate 400 vs Slate 600
    final Color cardColor = theme.cardColor;
    final Color detailBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8F9FB);
    final Color iconBgColor = isDark ? const Color(0xFF222E45) : const Color(0xFFEDEEF3);
    final Color rowDividerColor = isDark ? const Color(0xFF2E3B52) : const Color(0xFFEDEEF3);

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isPositive = transaction.amount > 0;

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
      if (transaction.note.trim().isNotEmpty && transaction.note != 'Standard shared transaction')
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
                  color: isDark ? const Color(0xFF2E3B52) : const Color(0xFFE2E5EE),
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
                    color: isDark ? const Color(0xFF222E45) : const Color(0xFFF0F1F5),
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
                      colors: [Color(0xFF1A2D5A), Color(0xFF0F1B35)],
                    ),
            ),
            child: Row(
              children: [
                // Circular Transaction Icon Container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
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
                        isPositive ? l10n.income.toUpperCase() : l10n.expense.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatBalanceParts(transaction.amount).join(),
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
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.completedStatus,
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
