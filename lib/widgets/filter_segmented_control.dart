import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FilterSegmentedControl extends StatelessWidget {
  final List<String> filters;
  final String activeFilter;
  final Function(String) onFilterSelected;

  const FilterSegmentedControl({
    super.key,
    required this.filters,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color subTextColor = isDark ? AppColors.slate400 : AppColors.slate600;

    return Row(
      children: filters.map((filter) {
        final bool isSelected =
            activeFilter.toLowerCase() == filter.toLowerCase();
        return Expanded(
          child: GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySeed : cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.darkSlate.withValues(
                            alpha: isDark ? 0.20 : 0.04,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Text(
                filter,
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
    );
  }
}
