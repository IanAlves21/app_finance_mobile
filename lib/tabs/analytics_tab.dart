import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart'; // Import Custom Localization
import '../theme/app_colors.dart';
import '../viewmodels/analytics_view_model.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/filter_segmented_control.dart';
import '../widgets/progress_bar_card.dart';
import '../widgets/donut_chart.dart';
import '../widgets/category_transactions_bottom_sheet.dart';
import '../widgets/interactive_card.dart';
import '../utils/currency_formatter.dart';
import '../utils/ui_utils.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  late final AnalyticsViewModel _viewModel;
  String? _currentLocale;

  @override
  void initState() {
    super.initState();
    _viewModel = AnalyticsViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_currentLocale != locale) {
      _currentLocale = locale;
      _viewModel.loadMonthlySpending(locale: locale);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomInset = 90 + bottomPadding + 24;

    // Dynamic colors for Light/Dark Mode
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark
        ? AppColors.slate400
        : AppColors.slate600; // Slate 400 vs Slate 600
    final Color cardColor = theme.cardColor;

    // Resolve localization translations
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final SystemUiOverlayStyle overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: AppColors.darkCard,
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarContrastEnforced: false,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          );

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 60,
                left: 24,
                right: 24,
                bottom: totalBottomInset,
              ),
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
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle filter tabs (Componentized)
                  FilterSegmentedControl(
                    filters: [l10n.weekly, l10n.monthly, l10n.yearly],
                    activeFilter: _viewModel.activeFilter == 'Weekly'
                        ? l10n.weekly
                        : (_viewModel.activeFilter == 'Yearly' ? l10n.yearly : l10n.monthly),
                    onFilterSelected: (filter) {
                      final String langCode = Localizations.localeOf(context).languageCode;
                      if (filter == l10n.weekly) {
                        _viewModel.setActiveFilter('Weekly', locale: langCode);
                      } else if (filter == l10n.monthly) {
                        _viewModel.setActiveFilter('Monthly', locale: langCode);
                      } else if (filter == l10n.yearly) {
                        _viewModel.setActiveFilter('Yearly', locale: langCode);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Spending Division by Partner Section
                  Text(
                    l10n.familySpendingDivision,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkSlate.withValues(
                            alpha: isDark ? 0.20 : 0.04,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Centered Donut/Pie Chart on the left
                        _viewModel.isLoading
                            ? const SkeletonContainer(
                                width: 100,
                                height: 100,
                                borderRadius: 50,
                              )
                            : SizedBox(
                                width: 100,
                                height: 100,
                                child: DonutChart(
                                  strokeWidth: 12,
                                  sections: _viewModel.activeUserBreakdown.asMap().entries.map((entry) {
                                    final int index = entry.key;
                                    final Map<String, dynamic> uData = entry.value;
                                    final double percentage = (uData['percentage'] as num).toDouble();
                                    
                                    final List<Color> partnerColors = [
                                      AppColors.accentViolet,
                                      AppColors.accentOrange,
                                      AppColors.greenAccent,
                                      AppColors.purpleAccent,
                                    ];
                                    return DonutChartSection(
                                      percentage: percentage,
                                      color: partnerColors[index % partnerColors.length],
                                    );
                                  }).toList(),
                                ),
                              ),
                        const SizedBox(width: 24),
                        
                        // Partners spending breakdown list on the right
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _viewModel.isLoading
                                ? List.generate(
                                    2,
                                    (index) => const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 6.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              SkeletonContainer(width: 70, height: 12, borderRadius: 4),
                                              Spacer(),
                                              SkeletonContainer(width: 50, height: 12, borderRadius: 4),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          SkeletonContainer(width: double.infinity, height: 6, borderRadius: 3),
                                        ],
                                      ),
                                    ),
                                  )
                                : (_viewModel.activeUserBreakdown.isEmpty
                                    ? [
                                        Text(
                                          Localizations.localeOf(context).languageCode == 'pt'
                                              ? 'Nenhum lançamento registrado'
                                              : 'No entries registered',
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      ]
                                    : _viewModel.activeUserBreakdown.asMap().entries.map((entry) {
                                        final int index = entry.key;
                                        final Map<String, dynamic> uData = entry.value;

                                        final String name = uData['name'] as String;
                                        final double amount = (uData['amount'] as num).toDouble();
                                        final double percentage = (uData['percentage'] as num).toDouble();

                                        final List<Color> partnerColors = [
                                          AppColors.accentViolet,
                                          AppColors.accentOrange,
                                          AppColors.greenAccent,
                                          AppColors.purpleAccent,
                                        ];
                                        final Color barColor = partnerColors[index % partnerColors.length];

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: barColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: TextStyle(
                                                        color: textColor,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${(percentage * 100).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                CurrencyFormatter.formatBalanceParts(amount).join(),
                                                style: TextStyle(
                                                  color: subTextColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList()),
                          ),
                        ),
                      ],
                    ),
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
                          color: AppColors.darkSlate.withValues(
                            alpha: isDark ? 0.25 : 0.06,
                          ),
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
                                  _viewModel.isLoading
                                      ? ''
                                      : '${l10n.spendingIn} ${_viewModel.activeMonth.toUpperCase()}',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _viewModel.isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.0),
                                        child: SkeletonContainer(
                                          width: 120,
                                          height: 24,
                                          borderRadius: 6,
                                        ),
                                      )
                                    : RichText(
                                        text: TextSpan(
                                          text: CurrencyFormatter.formatBalanceParts(
                                            _viewModel.activeExpense,
                                          )[0],
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: CurrencyFormatter.formatBalanceParts(
                                                _viewModel.activeExpense,
                                              )[1],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            ),
                            if (!_viewModel.isLoading)
                              (() {
                                final comparison = _viewModel.activeComparison;
                                final bool isNeutral = comparison['isNeutral'] == true;
                                final bool isIncrease = comparison['isIncrease'] == true;

                                final Color bg = isNeutral
                                    ? (isDark ? AppColors.darkInterfaceColor : AppColors.slate100)
                                    : (isIncrease ? AppColors.redBg : AppColors.greenBg);

                                final Color fg = isNeutral
                                    ? subTextColor
                                    : (isIncrease ? AppColors.redAccent : AppColors.greenAccent);

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        comparison['icon'] as IconData,
                                        color: fg,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        comparison['text'] as String,
                                        style: TextStyle(
                                          color: fg,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }()),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Customized Bar Chart Representation
                        SizedBox(
                          height: 180,
                          child: _viewModel.isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(
                                    6,
                                    (index) => const Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            SkeletonContainer(
                                              width: 26,
                                              height: 120,
                                              borderRadius: 8,
                                            ),
                                            SizedBox(height: 10),
                                            SkeletonContainer(
                                              width: 32,
                                              height: 14,
                                              borderRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(
                                    _viewModel.chartValues.length,
                                    (index) {
                                      final bool isActive =
                                          _viewModel.activeBarIndex == index;
                                      final double percentage =
                                          _viewModel.chartValues[index];

                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              _viewModel.setActiveBarIndex(index),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment: Alignment.bottomCenter,
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 250,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    width: 26,
                                                    height: 150 * percentage,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                      gradient: LinearGradient(
                                                        colors: isActive
                                                            ? [
                                                                AppColors
                                                                    .accentOrangeLight,
                                                                AppColors
                                                                    .accentOrange,
                                                              ]
                                                            : (isDark
                                                                  ? [
                                                                      AppColors
                                                                          .darkBarBg,
                                                                      AppColors
                                                                          .darkBarFg,
                                                                    ]
                                                                  : [
                                                                      AppColors
                                                                          .slate200,
                                                                      AppColors
                                                                          .slate300,
                                                                    ]),
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                      ),
                                                      boxShadow: isActive
                                                          ? [
                                                              BoxShadow(
                                                                color: AppColors
                                                                    .accentOrange
                                                                    .withValues(
                                                                      alpha: 0.3,
                                                                    ),
                                                                blurRadius: 8,
                                                                offset: const Offset(
                                                                  0,
                                                                  4,
                                                                ),
                                                              ),
                                                            ]
                                                          : [],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                _viewModel.chartMonths[index],
                                                style: TextStyle(
                                                  color: isActive
                                                      ? textColor
                                                      : subTextColor,
                                                  fontSize: 12,
                                                  fontWeight: isActive
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
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

                  if (_viewModel.isLoading)
                    ...List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            children: [
                              Row(
                                children: [
                                  SkeletonContainer(width: 18, height: 18, borderRadius: 4),
                                  SizedBox(width: 8),
                                  SkeletonContainer(width: 100, height: 14, borderRadius: 4),
                                  Spacer(),
                                  SkeletonContainer(width: 70, height: 14, borderRadius: 4),
                                ],
                              ),
                              SizedBox(height: 12),
                              SkeletonContainer(width: double.infinity, height: 8, borderRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_viewModel.activeCategories.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pie_chart_outline_rounded,
                              size: 48,
                              color: subTextColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              Localizations.localeOf(context).languageCode == 'pt'
                                  ? 'Nenhum gasto registrado neste período'
                                  : 'No spending registered in this period',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._viewModel.activeCategories.map((cat) {
                      final double amount = (cat['amount'] as num).toDouble();
                      final double percentage = (cat['percentage'] as num).toDouble();
                      final String categoryName = cat['name'] as String;
                      final String iconStr = cat['icon'] as String;
                      final String colorStr = cat['color'] as String;

                      // Traduz os nomes das categorias padrão caso o locale seja pt ou en
                      String localizedName = categoryName;
                      if (categoryName.toLowerCase() == 'shopping' || categoryName.toLowerCase() == 'compras') {
                        localizedName = l10n.shopping;
                      } else if (categoryName.toLowerCase() == 'food & dining' || categoryName.toLowerCase() == 'comida & jantar' || categoryName.toLowerCase() == 'comida') {
                        localizedName = l10n.foodDining;
                      } else if (categoryName.toLowerCase() == 'transportation' || categoryName.toLowerCase() == 'transporte') {
                        localizedName = l10n.transportation;
                      } else if (categoryName.toLowerCase() == 'others' || categoryName.toLowerCase() == 'outros') {
                        localizedName = l10n.others;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: InteractiveCard(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CategoryTransactionsBottomSheet(
                                categoryId: cat['id'] as String,
                                categoryName: localizedName,
                                startDate: _viewModel.activeStartDate,
                                endDate: _viewModel.activeEndDate,
                              ),
                            );
                          },
                          child: ProgressBarCard(
                            title: localizedName,
                            amount: CurrencyFormatter.formatBalanceParts(amount).join(),
                            percentage: percentage,
                            color: UIUtils.parseHexColor(colorStr),
                            icon: UIUtils.getIconData(iconStr),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
