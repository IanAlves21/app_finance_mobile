import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'interactive_card.dart';
import 'custom_toast.dart';
import '../l10n/app_localizations.dart'; // Import Custom Localization
import '../theme/app_colors.dart';
import '../viewmodels/add_transaction_view_model.dart';
import '../services/service_locator.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  State<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'Expense';
  String _selectedCategory = '';
  String? _selectedPaymentMethod;
  int _installments = 1;
  late final AddTransactionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = locator<AddTransactionViewModel>();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadCategories();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onViewModelChanged() {
    if (mounted) {
      final filtered = _viewModel.categories
          .where((cat) => cat.type == _selectedType.toUpperCase() && !cat.id.startsWith('offline_cat_'))
          .toList();
      
      if (filtered.isNotEmpty && (_selectedCategory.isEmpty || !filtered.any((cat) => cat.id == _selectedCategory))) {
        _selectedCategory = filtered.first.id;
      }
      setState(() {});
    }
  }

  Color _parseHexColor(String hexStr) {
    try {
      final String cleanHex = hexStr.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return AppColors.primarySeed;
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'briefcase':
      case 'savings':
        return Icons.savings_rounded;
      case 'shopping-cart':
      case 'food':
        return Icons.shopping_cart_outlined;
      case 'restaurant':
      case 'dining':
        return Icons.restaurant_rounded;
      case 'directions-car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'money':
      case 'monetization-on':
        return Icons.monetization_on_outlined;
      case 'subscriptions':
      case 'streaming':
        return Icons.subscriptions_rounded;
      case 'home':
      case 'rent':
        return Icons.home_outlined;
      case 'medical':
      case 'health':
        return Icons.medical_services_outlined;
      case 'school':
      case 'education':
        return Icons.school_outlined;
      case 'pets':
      case 'pet':
        return Icons.pets_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> _saveTransaction() async {
    final String description = _nameController.text.trim();
    final String cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    final l10n = AppLocalizations.of(context)!;

    if (description.isEmpty) {
      CustomToast.showError(context, l10n.descriptionHint);
      return;
    }

    final double? amount = cleanAmount.isEmpty ? null : double.tryParse(cleanAmount)! / 100;
    if (amount == null || amount <= 0) {
      CustomToast.showError(context, 'Por favor, insira um valor válido');
      return;
    }

    if (_selectedType == 'Expense' && _selectedPaymentMethod == null) {
      CustomToast.showError(context, 'Por favor, selecione uma forma de pagamento');
      return;
    }

    try {
      await _viewModel.saveTransaction(
        description: description,
        amount: amount,
        type: _selectedType.toUpperCase(), // 'INCOME' ou 'EXPENSE'
        categoryId: _selectedCategory.isNotEmpty ? _selectedCategory : null,
        paymentMethod: _selectedType == 'Expense' ? _selectedPaymentMethod : null,
        installments: _selectedType == 'Expense' && _selectedPaymentMethod == 'CREDIT' ? _installments : null,
      );

      if (!mounted) return;
      
      Navigator.pop(context, true);
      CustomToast.showSuccess(context, l10n.transactionSaved);
    } catch (e) {
      if (!mounted) return;
      CustomToast.showError(context, 'Erro ao salvar transação: $e');
    }
  }

  Widget _buildPaymentMethodButton({
    required String value,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color inputFillColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentOrange.withValues(alpha: 0.1) : inputFillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.accentOrange : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.accentOrange : subTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.accentOrange : textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInstallmentPreview() {
    final String cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanAmount.isEmpty) return '';
    final double? totalAmount = double.tryParse(cleanAmount) == null ? null : double.tryParse(cleanAmount)! / 100;
    if (totalAmount == null || totalAmount <= 0) return '';

    final double installmentAmount = totalAmount / _installments;
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final String formattedInstallment = formatter.format(installmentAmount);

    return '($formattedInstallment por mês)';
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required Color textColor,
    bool isPending = false,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isPending ? iconBgColor.withValues(alpha: 0.05) : iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: isPending ? iconColor.withValues(alpha: 0.4) : iconColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isPending ? textColor.withValues(alpha: 0.4) : textColor,
            ),
          ),
        ),
        if (isPending) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Pendente ⏳',
              style: TextStyle(
                color: AppColors.accentOrange,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _nameController.dispose();
    _amountController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
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
                final bool isExpense = type == l10n.expense;
                final bool isSelected = (_selectedType == 'Expense' && isExpense) ||
                    (_selectedType == 'Income' && !isExpense);
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = isExpense ? 'Expense' : 'Income';
                        final filtered = _viewModel.categories
                            .where((cat) => cat.type == _selectedType.toUpperCase() && !cat.id.startsWith('offline_cat_'))
                            .toList();
                        if (filtered.isNotEmpty) {
                          _selectedCategory = filtered.first.id;
                        } else {
                          _selectedCategory = '';
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (isExpense ? AppColors.redAccent : AppColors.greenAccent) 
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
            const SizedBox(height: 18),

            // Payment Method Selector (Only for Expense) - Moved to Top
            if (_selectedType == 'Expense') ...[
              Text(
                'Forma de Pagamento',
                style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      _buildPaymentMethodButton(
                        value: 'CREDIT',
                        label: 'Crédito',
                        icon: Icons.credit_card_rounded,
                        isSelected: _selectedPaymentMethod == 'CREDIT',
                        inputFillColor: inputFillColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(width: 8),
                      _buildPaymentMethodButton(
                        value: 'DEBIT',
                        label: 'Débito',
                        icon: Icons.credit_card_outlined,
                        isSelected: _selectedPaymentMethod == 'DEBIT',
                        inputFillColor: inputFillColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPaymentMethodButton(
                        value: 'PIX',
                        label: 'Pix',
                        icon: Icons.qr_code_rounded,
                        isSelected: _selectedPaymentMethod == 'PIX',
                        inputFillColor: inputFillColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(width: 8),
                      _buildPaymentMethodButton(
                        value: 'CASH',
                        label: 'Dinheiro',
                        icon: Icons.payments_rounded,
                        isSelected: _selectedPaymentMethod == 'CASH',
                        inputFillColor: inputFillColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),
                  if (_selectedPaymentMethod == 'CREDIT') ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: inputFillColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantidade de Parcelas',
                                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              if (_getInstallmentPreview().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _getInstallmentPreview(),
                                  style: const TextStyle(
                                    color: AppColors.accentOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_installments > 1) {
                                    setState(() {
                                      _installments--;
                                    });
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF151B2D) : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 18,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$_installments',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  if (_installments < 36) {
                                    setState(() {
                                      _installments++;
                                    });
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF151B2D) : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ] else ...[
              const SizedBox(height: 4),
            ],

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
                hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.5)),
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'R\$ 0,00',
                hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.5)),
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
              isExpanded: true,
              isDense: false,
              menuMaxHeight: 300,
              initialValue: _selectedCategory.isNotEmpty ? _selectedCategory : null,
              dropdownColor: cardColor,
              borderRadius: BorderRadius.circular(16),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: subTextColor.withValues(alpha: 0.8),
              ),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              hint: Text(
                _viewModel.isLoading ? 'Carregando... ⏳' : 'Selecione uma categoria',
                style: TextStyle(
                  color: subTextColor.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
              items: _viewModel.categories
                  .where((cat) => cat.type == _selectedType.toUpperCase())
                  .map((category) {
                final categoryColor = _parseHexColor(category.color);
                final bool isPending = category.id.startsWith('offline_cat_');
                return DropdownMenuItem<String>(
                  value: category.id,
                  enabled: !isPending,
                  child: _buildDropdownItem(
                    icon: _getIconData(category.icon),
                    iconColor: categoryColor,
                    iconBgColor: categoryColor.withValues(alpha: 0.15),
                    label: category.name,
                    textColor: textColor,
                    isPending: isPending,
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? ''),
            ),
            const SizedBox(height: 24),

            // Submit Button
            InteractiveCard(
              onTap: _viewModel.isLoading ? null : _saveTransaction,
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
                      color: const Color(0xFFF97316).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _viewModel.isLoading
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: 'R\$ 0,00',
        selection: TextSelection.collapsed(offset: 7),
      );
    }

    double value = double.parse(cleanText) / 100;
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    String newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
