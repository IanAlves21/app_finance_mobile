import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'interactive_card.dart';
import 'custom_toast.dart';

class AddCategoryBottomSheet extends StatefulWidget {
  final Category? categoryToEdit;

  const AddCategoryBottomSheet({super.key, this.categoryToEdit});

  @override
  State<AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends State<AddCategoryBottomSheet> {
  final _nameController = TextEditingController();
  String _selectedType = 'EXPENSE';
  String _selectedIcon = 'category';
  String _selectedColor = '#1A2D5A'; // Default Primary Blue
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!.name;
      _selectedType = widget.categoryToEdit!.type;
      _selectedIcon = widget.categoryToEdit!.icon ?? 'category';
      _selectedColor = widget.categoryToEdit!.color;
    }
  }

  List<Map<String, dynamic>> get _currentAvailableIcons {
    if (_selectedType == 'INCOME') {
      return [
        {'name': 'money', 'icon': Icons.monetization_on_outlined},
        {'name': 'briefcase', 'icon': Icons.savings_rounded},
      ];
    } else {
      return [
        {'name': 'category', 'icon': Icons.category_rounded},
        {'name': 'shopping-cart', 'icon': Icons.shopping_cart_outlined},
        {'name': 'restaurant', 'icon': Icons.restaurant_rounded},
        {'name': 'directions-car', 'icon': Icons.directions_car_rounded},
        {'name': 'money', 'icon': Icons.monetization_on_outlined},
        {'name': 'briefcase', 'icon': Icons.savings_rounded},
        {'name': 'subscriptions', 'icon': Icons.subscriptions_rounded},
        {'name': 'home', 'icon': Icons.home_outlined},
        {'name': 'medical', 'icon': Icons.medical_services_outlined},
        {'name': 'school', 'icon': Icons.school_outlined},
        {'name': 'pets', 'icon': Icons.pets_rounded},
      ];
    }
  }

  final List<String> _availableColors = [
    '#1A2D5A', // Deep Blue
    '#F97316', // Orange
    '#DC2626', // Red
    '#16A34A', // Green
    '#7C3AED', // Purple
    '#0284C7', // Sky Blue
  ];

  Color _parseHexColor(String hexStr) {
    try {
      final String cleanHex = hexStr.replaceAll('#', '').trim();
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return AppColors.primarySeed;
    }
  }

  Future<void> _saveCategory() async {
    final String name = _nameController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (name.isEmpty) {
      CustomToast.showError(context, l10n.categoryNameError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.categoryToEdit != null) {
        await _apiService.updateCategory(
          id: widget.categoryToEdit!.id,
          name: name,
          type: _selectedType,
          icon: _selectedIcon,
          color: _selectedColor,
        );
      } else {
        await _apiService.createCategory(
          name: name,
          type: _selectedType,
          icon: _selectedIcon,
          color: _selectedColor,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        CustomToast.showSuccess(
          context,
          widget.categoryToEdit != null
              ? l10n.categoryUpdatedSuccess
              : l10n.categoryCreatedSuccess,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomToast.showError(
          context,
          widget.categoryToEdit != null
              ? '${l10n.categoryUpdateError}: $e'
              : '${l10n.categoryCreateError}: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7A99);
    final Color cardColor = theme.cardColor;
    final Color inputFillColor = isDark ? const Color(0xFF222E45) : const Color(0xFFF1F5F9);

    final l10n = AppLocalizations.of(context)!;

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
              widget.categoryToEdit != null ? l10n.editCategory : l10n.newCategory,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),

            // Income / Expense Selector Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedType = 'EXPENSE';
                      _selectedIcon = 'category';
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == 'EXPENSE'
                            ? AppColors.redAccent
                            : inputFillColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.expense.toUpperCase(),
                        style: TextStyle(
                          color: _selectedType == 'EXPENSE' ? Colors.white : subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedType = 'INCOME';
                      _selectedIcon = 'money';
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == 'INCOME'
                            ? AppColors.greenAccent
                            : inputFillColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.income.toUpperCase(),
                        style: TextStyle(
                          color: _selectedType == 'INCOME' ? Colors.white : subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Name Field
            Text(
              l10n.categoryName,
              style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: l10n.categoryNameHint,
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

            // Icon Picker
            Text(
              l10n.categoryIconLabel,
              style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: _currentAvailableIcons.map((item) {
                  final bool isSelected = _selectedIcon == item['name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIcon = item['name']),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? _parseHexColor(_selectedColor) : inputFillColor,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _parseHexColor(_selectedColor).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          item['icon'],
                          color: isSelected ? Colors.white : subTextColor,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Color Picker
            Text(
              l10n.categoryColorLabel,
              style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _availableColors.map((colorHex) {
                final bool isSelected = _selectedColor == colorHex;
                final Color color = _parseHexColor(colorHex);
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorHex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: isDark ? Colors.white : AppColors.darkSlate,
                              width: 3,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Submit Button
            InteractiveCard(
              onTap: _isLoading ? null : _saveCategory,
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
                        l10n.saveCategory,
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
