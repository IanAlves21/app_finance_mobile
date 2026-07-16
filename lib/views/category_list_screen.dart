import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../services/service_locator.dart';
import '../theme/app_colors.dart';
import '../widgets/add_category_bottom_sheet.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CategoryRepository _categoryRepository = locator<CategoryRepository>();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats = await _categoryRepository.fetchCategories();
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.categoryLoadError}: $e')),
        );
      }
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

  void _confirmDeleteCategory(Category category) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteCategory,
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.deleteCategoryConfirm(category.name),
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fecha o dialog
              _executeDeleteCategory(category.id);
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeleteCategory(String categoryId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      await _categoryRepository.deleteCategory(categoryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.categoryDeleteSuccess)),
        );
      }
      _loadCategories();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final cleanMsg = e.toString().replaceAll('HttpException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cleanMsg)),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCategoryList(String type) {
    final filtered = _categories.where((cat) => cat.type == type).toList();
    final l10n = AppLocalizations.of(context)!;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: AppColors.slate400.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noCategoriesCreated,
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tapToAddCategory,
              style: TextStyle(
                color: AppColors.slate400.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomPadding + 86, // Espaço para a barra de navegação do Android + FAB (Floating Action Button)
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final category = filtered[index];
        final Color catColor = _parseHexColor(category.color);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkSlate.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(category.icon),
                color: catColor,
                size: 20,
              ),
            ),
            title: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  category.familyId != null ? l10n.customLabel : l10n.systemLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (category.id.startsWith('offline_cat_')) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.12),
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
            ),
            trailing: category.familyId != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final bool? edited = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddCategoryBottomSheet(categoryToEdit: category),
                          );
                          if (edited == true) {
                            _loadCategories();
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.edit_outlined, color: AppColors.primarySeed, size: 23),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _confirmDeleteCategory(category),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 4, top: 4, bottom: 4),
                          child: Icon(Icons.delete_outline_rounded, color: AppColors.redAccent, size: 23),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.manageCategories,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primarySeed,
          unselectedLabelColor: AppColors.slate400,
          indicatorColor: AppColors.accentOrange,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: l10n.expensesTab),
            Tab(text: l10n.incomesTab),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentOrange,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList('EXPENSE'),
                _buildCategoryList('INCOME'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentOrange,
        onPressed: () async {
          final bool? added = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddCategoryBottomSheet(),
          );
          if (added == true) {
            _loadCategories();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
