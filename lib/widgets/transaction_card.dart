import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../utils/transaction_ui_extension.dart';
import 'interactive_card.dart';
import 'transaction_detail_bottom_sheet.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_extension.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark ? AppColors.slate400 : AppColors.slate600;

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isPositive = transaction.amount > 0;

    return InteractiveCard(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => TransactionDetailBottomSheet(
            transaction: transaction,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkSlate.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: transaction.iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                transaction.icon,
                color: transaction.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.getTransactionName(transaction.name), // Dynamic Translation!
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.date,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.north_east_rounded : Icons.south_east_rounded,
                  color: isPositive ? AppColors.greenAccent : AppColors.redAccent,
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  '${isPositive ? '+' : ''}R\$ ${transaction.amount.abs().toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isPositive ? AppColors.greenAccent : AppColors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
