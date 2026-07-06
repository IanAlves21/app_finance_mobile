import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/interactive_card.dart';

class WalletsTab extends StatefulWidget {
  const WalletsTab({super.key});

  @override
  State<WalletsTab> createState() => _WalletsTabState();
}

class _WalletsTabState extends State<WalletsTab> {
  final PageController _cardPageController = PageController(
    viewportFraction: 0.85,
  );
  int _activeCardIndex = 0;

  final List<Map<String, dynamic>> _mockCards = [
    {
      'holder': 'Lucas Shared',
      'number': '•••• •••• •••• 4820',
      'balance': 'R\$ 18.231,50',
      'expiry': '12/31',
      'colors': [const Color(0xFF1E293B), const Color(0xFF0F172A)],
      'brand': 'VISA',
    },
    {
      'holder': 'Mariana Shared',
      'number': '•••• •••• •••• 9210',
      'balance': 'R\$ 6.150,00',
      'expiry': '08/30',
      'colors': [const Color(0xFF4338CA), const Color(0xFF312E81)],
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
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F1B35);
    final Color subTextColor = isDark
        ? const Color(0xFF6B7A99).withOpacity(0.6)
        : const Color(0xFF6B7A99);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

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
          padding: EdgeInsets.only(
            top: 60,
            left: 0,
            right: 0,
            bottom: totalBottomInset,
          ),
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
                      'Wallets',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your shared accounts & cards',
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
                  onPageChanged: (index) =>
                      setState(() => _activeCardIndex = index),
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
                          child: Transform.scale(scale: value, child: child),
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
                              color: colors.first.withOpacity(
                                isDark ? 0.20 : 0.35,
                              ),
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
                                const Icon(
                                  Icons.wifi_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
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
                                      'CARD HOLDER',
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
                                      'EXPIRES',
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
                      color: isActive
                          ? const Color(0xFFF97316)
                          : const Color(0xFFCBD5E1),
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
                      'Quick Actions',
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
                        _buildQuickAction(
                          Icons.send_rounded,
                          'Send',
                          const Color(0xFFDCFCE7),
                          const Color(0xFF16A34A),
                          textColor,
                        ),
                        _buildQuickAction(
                          Icons.arrow_downward_rounded,
                          'Request',
                          const Color(0xFFFEF3C7),
                          const Color(0xFFD97706),
                          textColor,
                        ),
                        _buildQuickAction(
                          Icons.payment_rounded,
                          'Pay Bills',
                          const Color(0xFFFEE2E2),
                          const Color(0xFFDC2626),
                          textColor,
                        ),
                        _buildQuickAction(
                          Icons.grid_view_rounded,
                          'More',
                          const Color(0xFFEDE9FE),
                          const Color(0xFF7C3AED),
                          textColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Monthly spending limit tracker
                    Text(
                      'Shared Monthly Limit',
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
                            color: const Color(
                              0xFF0F1B35,
                            ).withOpacity(isDark ? 0.15 : 0.04),
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
                                'Shared Limit Used',
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
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFF97316),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You have spent 42% of your shared threshold limit.',
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

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color bg,
    Color iconColor,
    Color textColor,
  ) {
    return InteractiveCard(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
