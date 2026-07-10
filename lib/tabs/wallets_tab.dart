import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart'; // Import Custom Localization
import '../theme/app_colors.dart';
import '../widgets/quick_action_item.dart';

class WalletsTab extends StatefulWidget {
  const WalletsTab({super.key});

  @override
  State<WalletsTab> createState() => _WalletsTabState();
}

class _WalletsTabState extends State<WalletsTab> {
  final PageController _cardPageController = PageController(viewportFraction: 0.85);
  int _activeCardIndex = 0;

  final List<Map<String, dynamic>> _mockCards = [
    {
      'holder': 'Lucas Shared',
      'number': '•••• •••• •••• 4820',
      'balance': 'R\$ 18.231,50',
      'expiry': '12/31',
      'colors': [AppColors.slate800, AppColors.slate900],
      'brand': 'VISA',
    },
    {
      'holder': 'Mariana Shared',
      'number': '•••• •••• •••• 9210',
      'balance': 'R\$ 6.150,00',
      'expiry': '08/30',
      'colors': [AppColors.indigoAccent, AppColors.indigoBg],
      'brand': 'Mastercard',
    },
  ];

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomInset = 90 + bottomPadding + 24;

    // Dynamic styles based on theme
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : AppColors.darkSlate;
    final Color subTextColor = isDark ? AppColors.slate600.withValues(alpha: 0.6) : AppColors.slate600;
    final Color cardColor = isDark ? AppColors.slate800 : Colors.white;

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(top: 60, left: 0, right: 0, bottom: totalBottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.wallets,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.manageSharedAccounts,
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Horizontal virtual card pager
              SizedBox(
                height: 210,
                child: PageView.builder(
                  controller: _cardPageController,
                  itemCount: _mockCards.length,
                  onPageChanged: (index) => setState(() => _activeCardIndex = index),
                  itemBuilder: (context, index) {
                    final card = _mockCards[index];
                    final List<Color> colors = card['colors'] as List<Color>;

                    return AnimatedBuilder(
                      animation: _cardPageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_cardPageController.position.haveDimensions) {
                          value = _cardPageController.page! - index;
                          value = (1 - (value.abs() * 0.08)).clamp(0.0, 1.0);
                        }
                        return Center(
                          child: Transform.scale(
                            scale: value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colors.first.withOpacity(isDark ? 0.20 : 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  card['brand'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const Icon(Icons.wifi_rounded, color: Colors.white, size: 22),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              card['balance'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.cardHolder,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      card['holder'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      l10n.expires,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      card['expiry'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_mockCards.length, (index) {
                  final bool isActive = _activeCardIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.accentOrange : AppColors.slate300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Quick actions grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quickActions,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        QuickActionItem(
                          icon: Icons.send_rounded,
                          label: l10n.send,
                          bg: AppColors.greenBg,
                          iconColor: AppColors.greenAccent,
                          textColor: textColor,
                          onTap: () {},
                        ),
                        QuickActionItem(
                          icon: Icons.arrow_downward_rounded,
                          label: l10n.request,
                          bg: AppColors.yellowBg,
                          iconColor: AppColors.yellowAccent,
                          textColor: textColor,
                          onTap: () {},
                        ),
                        QuickActionItem(
                          icon: Icons.payment_rounded,
                          label: l10n.payBills,
                          bg: AppColors.redBg,
                          iconColor: AppColors.redAccent,
                          textColor: textColor,
                          onTap: () {},
                        ),
                        QuickActionItem(
                          icon: Icons.grid_view_rounded,
                          label: l10n.more,
                          bg: AppColors.purpleBg,
                          iconColor: AppColors.purpleAccent,
                          textColor: textColor,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Monthly spending limit tracker
                    Text(
                      l10n.sharedMonthlyLimit,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkSlate.withValues(alpha: isDark ? 0.15 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.sharedLimitUsed,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  text: 'R\$ 3.418,00',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ' / R\$ 8.000,00',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 3418 / 8000,
                              minHeight: 8,
                              backgroundColor: isDark ? AppColors.slate700 : AppColors.slate100,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.limitText,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
