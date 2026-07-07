import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart'; // Import Custom Localization

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int _activeBarIndex = 4; // Defaults to May
  String _activeFilter = 'Monthly';

  final List<double> _mockChartValues = [0.4, 0.65, 0.35, 0.8, 0.55, 0.9];
  final List<String> _mockChartMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  final List<double> _mockChartExpenses = [1200.0, 2100.0, 1050.0, 3100.0, 1850.0, 3418.0];

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomInset = 90 + bottomPadding + 24;

    // Dynamic colors for Light/Dark Mode
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7A99); // Slate 400 vs Slate 600
    final Color cardColor = theme.cardColor;

    // Resolve localization translations
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final SystemUiOverlayStyle overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: const Color(0xFF151B2D),
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarContrastEnforced: false,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(top: 60, left: 24, right: 24, bottom: totalBottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.analytics,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.sharedMonthlySpending,
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Toggle filter tabs
              Row(
                children: [l10n.weekly, l10n.monthly, l10n.yearly].map((filter) {
                  final bool isSelected = _activeFilter == filter || 
                      (_activeFilter == 'Monthly' && filter == l10n.monthly) ||
                      (_activeFilter == 'Weekly' && filter == l10n.weekly) ||
                      (_activeFilter == 'Yearly' && filter == l10n.yearly);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (filter == l10n.weekly) _activeFilter = 'Weekly';
                          if (filter == l10n.monthly) _activeFilter = 'Monthly';
                          if (filter == l10n.yearly) _activeFilter = 'Yearly';
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1A2D5A) : cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isSelected
                              ? []
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF0F1B35).withOpacity(isDark ? 0.20 : 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
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
              ),
              const SizedBox(height: 32),

              // Chart Container Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F1B35).withOpacity(isDark ? 0.25 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.spendingIn} ${_mockChartMonths[_activeBarIndex].toUpperCase()}',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'R\$ ${_mockChartExpenses[_activeBarIndex].toStringAsFixed(2).replaceAll('.', ',')}',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.trending_down_rounded, color: Color(0xFFDC2626), size: 14),
                              SizedBox(width: 4),
                              Text(
                                '-4.2%',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Customized Bar Chart Representation
                    SizedBox(
                      height: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(_mockChartValues.length, (index) {
                          final bool isActive = _activeBarIndex == index;
                          final double percentage = _mockChartValues[index];

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _activeBarIndex = index),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeOutCubic,
                                        width: 26,
                                        height: 150 * percentage,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          gradient: LinearGradient(
                                            colors: isActive
                                                ? [const Color(0xFFFB923C), const Color(0xFFF97316)]
                                                : (isDark
                                                    ? [const Color(0xFF223047), const Color(0xFF2A3A54)]
                                                    : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]),
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFFF97316).withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  )
                                                ]
                                              : [],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _mockChartMonths[index],
                                    style: TextStyle(
                                      color: isActive ? textColor : subTextColor,
                                      fontSize: 12,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Spending Category Progress Bars
              Text(
                l10n.categoryBreakdown,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),

              _buildCategoryProgress(
                context: context,
                title: l10n.shopping,
                amount: 'R\$ 1.250,00',
                percentage: 0.35,
                color: const Color(0xFF7C3AED),
                icon: Icons.shopping_cart_outlined,
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 14),
              _buildCategoryProgress(
                context: context,
                title: l10n.foodDining,
                amount: 'R\$ 1.120,50',
                percentage: 0.32,
                color: const Color(0xFFD97706),
                icon: Icons.restaurant_rounded,
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 14),
              _buildCategoryProgress(
                context: context,
                title: l10n.transportation,
                amount: 'R\$ 640,00',
                percentage: 0.18,
                color: const Color(0xFF6366F1),
                icon: Icons.directions_car_rounded,
                cardColor: cardColor,
                textColor: textColor,
              ),
              const SizedBox(height: 14),
              _buildCategoryProgress(
                context: context,
                title: l10n.others,
                amount: 'R\$ 407,50',
                percentage: 0.15,
                color: const Color(0xFF16A34A),
                icon: Icons.bubble_chart_outlined,
                cardColor: cardColor,
                textColor: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryProgress({
    required BuildContext context,
    required String title,
    required String amount,
    required double percentage,
    required Color color,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1B35).withOpacity(isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                amount,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF222E45) : const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
