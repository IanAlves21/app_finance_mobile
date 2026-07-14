import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart'; // Import Custom Localization
import '../main.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/custom_toast.dart';
import '../widgets/shared_avatars.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(
    0.0,
  );

  late final HomeViewModel _viewModel;

  Future<void> _loadData() async {
    await _viewModel.loadTransactions(
      onUnauthorized: () {
        if (!mounted) return;
        final localizations = AppLocalizations.of(context);
        if (localizations != null) {
          CustomToast.showError(context, localizations.sessionExpiredMessage);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollOffsetNotifier.value = _scrollController.offset.clamp(
          0.0,
          150.0,
        );
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();
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

    // Resolve localization translations
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: isDark
                ? AppColors.darkCard
                : Colors.white,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Column(
            children: [
              // ── DYNAMIC COLLAPSING GRADIENT HEADER (Isolated rebuilds via ValueListenableBuilder) ──
              ValueListenableBuilder<double>(
                valueListenable: _scrollOffsetNotifier,
                builder: (context, scrollOffset, _) {
                  final double t = scrollOffset / 150.0;

                  return Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primarySeed, AppColors.darkSlate],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: 60.0 - (t * 15.0),
                      left: 24,
                      right: 24,
                      bottom: 36.0 - (t * 26.0),
                    ),
                    child: Column(
                      children: [
                        // Greeting row & avatars
                        SizedBox(
                          height: 48.0 * (1.0 - t),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 48,
                              child: Opacity(
                                opacity: (1.0 - (t * 2.0)).clamp(0.0, 1.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          l10n.goodMorning,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.55,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        ValueListenableBuilder<User?>(
                                          valueListenable: currentUserNotifier,
                                          builder: (context, user, _) {
                                            return Text(
                                              user?.name ?? 'Lucas & Mariana',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    // Shared overlapping avatars
                                    const SharedAvatars(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 32.0 * (1.0 - t)),

                        // SHARED TOTAL BALANCE Label
                        SizedBox(
                          height: 16.0 * (1.0 - t),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 16,
                              child: Opacity(
                                opacity: (1.0 - (t * 2.5)).clamp(0.0, 1.0),
                                child: Text(
                                  l10n.sharedTotalBalance,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.0 * (1.0 - t)),

                        // Dynamic Resizing Balance Amount
                        RichText(
                          text: TextSpan(
                            text: CurrencyFormatter.formatBalanceParts(
                              _viewModel.balance,
                            )[0],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42.0 - (t * 18.0),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: CurrencyFormatter.formatBalanceParts(
                                  _viewModel.balance,
                                )[1],
                                style: TextStyle(
                                  fontSize: 28.0 - (t * 12.0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.0 * (1.0 - t)),

                        // Trend Growth Badge
                        SizedBox(
                          height: 32.0 * (1.0 - t),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 32,
                              child: Opacity(
                                opacity: (1.0 - (t * 2.0)).clamp(0.0, 1.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.north_east_rounded,
                                        color: AppColors.greenGrowth,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+8.2% ${l10n.vsLastMonth}',
                                        style: const TextStyle(
                                          color: AppColors.greenGrowth,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── SCROLLABLE BODY CONTENT ──
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.accentOrange,
                  backgroundColor: isDark ? AppColors.slate800 : Colors.white,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Income Card
                              Expanded(
                                child: SummaryCard(
                                  title: l10n.monthlyIncome,
                                  value: CurrencyFormatter.formatSummaryValue(
                                    _viewModel.income,
                                  ),
                                  badgeText: '+12%',
                                  badgeColor: AppColors.greenAccent,
                                  badgeBg: AppColors.greenBg,
                                  icon: Icons.trending_up_rounded,
                                  iconColor: AppColors.greenAccent,
                                  iconBg: AppColors.greenBg,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Expense Card
                              Expanded(
                                child: SummaryCard(
                                  title: l10n.monthlyExpenses,
                                  value: CurrencyFormatter.formatSummaryValue(
                                    _viewModel.expenses,
                                  ),
                                  badgeText: '-5%',
                                  badgeColor: AppColors.redAccent,
                                  badgeBg: AppColors.redBg,
                                  icon: Icons.trending_down_rounded,
                                  iconColor: AppColors.redAccent,
                                  iconBg: AppColors.redBg,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.recentTransactions,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  l10n.seeAll,
                                  style: const TextStyle(
                                    color: AppColors.accentOrange,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _viewModel.isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.accentOrange,
                                      ),
                                    ),
                                  ),
                                )
                              : _viewModel.transactions.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                    ),
                                    child: Text(
                                      'Nenhuma transação encontrada',
                                      style: TextStyle(color: subTextColor),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: _viewModel.transactions.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final tx = _viewModel.transactions[index];
                                    return TransactionCard(transaction: tx);
                                  },
                                ),
                          SizedBox(height: totalBottomInset),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
