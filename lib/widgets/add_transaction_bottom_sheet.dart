import 'package:flutter/material.dart';
import 'interactive_card.dart';
import 'custom_toast.dart';
import '../l10n/app_localizations.dart'; // Import Custom Localization
import '../services/api_service.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  State<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'Expense';
  String _selectedCategory = 'Food';
  bool _isLoading = false;

  Future<void> _saveTransaction() async {
    final String description = _nameController.text.trim();
    final String amountStr = _amountController.text.trim().replaceAll(',', '.');
    
    final l10n = AppLocalizations.of(context)!;

    if (description.isEmpty) {
      CustomToast.showError(context, l10n.descriptionHint);
      return;
    }

    final double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      CustomToast.showError(context, 'Por favor, insira um valor válido');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      await apiService.createTransaction(
        description: description,
        amount: amount,
        type: _selectedType.toUpperCase(), // 'INCOME' ou 'EXPENSE'
        date: DateTime.now().toIso8601String(),
      );

      if (!mounted) return;
      
      Navigator.pop(context, true);
      CustomToast.showSuccess(context, l10n.transactionSaved);
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(context, 'Erro ao salvar transação: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    // Dynamic colors for Light/Dark Mode
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7A99); // Slate 400 vs Slate 600
    final Color cardColor = theme.cardColor;
    final Color inputFillColor = isDark ? const Color(0xFF222E45) : const Color(0xFFF1F5F9); // Slate midnight input

    // Resolve localization translations
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: keyboardPadding + bottomPadding + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slide Bar Indicator
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222E45) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form Title
            Text(
              l10n.addNewTransaction,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),

            // Income / Expense Selector Toggle
            Row(
              children: [l10n.expense, l10n.income].map((type) {
                final bool isSelected = (_selectedType == 'Expense' && type == l10n.expense) ||
                    (_selectedType == 'Income' && type == l10n.income);
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = type == l10n.expense ? 'Expense' : 'Income';
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF1A2D5A) 
                            : inputFillColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSelected ? Colors.white : subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Transaction Name Field
            Text(
              l10n.description,
              style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: l10n.descriptionHint,
                hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 18),

            // Transaction Amount Field
            Text(
              l10n.amountLabel,
              style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0,00',
                hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 18),

            // Category Selector
            Text(
              l10n.categoryLabel,
              style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: cardColor,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: 'Food',
                  child: Text(
                    l10n.food,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'Dining',
                  child: Text(
                    l10n.dining,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'Transport',
                  child: Text(
                    l10n.transport,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'Income',
                  child: Text(
                    l10n.income,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'Others',
                  child: Text(
                    l10n.others,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedCategory = v ?? 'Others'),
            ),
            const SizedBox(height: 32),

            // Submit Button
            InteractiveCard(
              onTap: _isLoading ? null : _saveTransaction,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.saveTransaction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
