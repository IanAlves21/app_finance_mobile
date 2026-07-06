import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart'; // Import to access global themeNotifier

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late bool _darkMode;
  bool _pushNotifications = true;
  bool _biometricAuth = false;

  @override
  void initState() {
    super.initState();
    _darkMode = themeNotifier.value == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomInset = 90 + bottomPadding + 24;

    // Dynamic styles based on theme
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7A99); // Slate 400 vs Slate 600
    final Color cardColor = theme.cardColor;

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
            left: 24,
            right: 24,
            bottom: totalBottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Customize your shared app preferences',
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              // Profile Header Widget
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF0F1B35,
                      ).withOpacity(isDark ? 0.25 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 40,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF97316),
                                    Color(0xFFFB923C),
                                  ],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'L',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF818CF8),
                                  ],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'M',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lucas & Mariana',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Joint Account • Premium Plan',
                            style: TextStyle(
                              color: textColor.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: subTextColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildSectionHeader('Account settings', subTextColor),
              _buildSettingTile(
                Icons.person_outline_rounded,
                'Edit Profiles',
                'Manage personal profiles',
                cardColor,
                textColor,
                subTextColor,
                isDark,
              ),
              _buildSettingTile(
                Icons.link_rounded,
                'Connected Banks',
                '2 external bank accounts linked',
                cardColor,
                textColor,
                subTextColor,
                isDark,
              ),
              _buildSettingTile(
                Icons.card_giftcard_outlined,
                'Cards Settings',
                'Virtual cards and blockings',
                cardColor,
                textColor,
                subTextColor,
                isDark,
              ),
              const SizedBox(height: 28),
              _buildSectionHeader('Preferences', subTextColor),
              _buildToggleTile(
                Icons.dark_mode_outlined,
                'Dark Mode',
                _darkMode,
                cardColor,
                textColor,
                isDark,
                (v) {
                  setState(() {
                    _darkMode = v;
                    themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                  });
                },
              ),
              _buildToggleTile(
                Icons.notifications_none_rounded,
                'Push Notifications',
                _pushNotifications,
                cardColor,
                textColor,
                isDark,
                (v) => setState(() => _pushNotifications = v),
              ),
              _buildToggleTile(
                Icons.fingerprint_rounded,
                'Biometric Sign-In',
                _biometricAuth,
                cardColor,
                textColor,
                isDark,
                (v) => setState(() => _biometricAuth = v),
              ),
              const SizedBox(height: 28),
              _buildSectionHeader('Support', subTextColor),
              _buildSettingTile(
                Icons.help_outline_rounded,
                'Help Center',
                'FAQs and technical support',
                cardColor,
                textColor,
                subTextColor,
                isDark,
              ),
              _buildSettingTile(
                Icons.policy_outlined,
                'Privacy Policy',
                'Data security policies',
                cardColor,
                textColor,
                subTextColor,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String subtitle,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1B35).withOpacity(isDark ? 0.20 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF1A2D5A),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: subTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
          size: 14,
        ),
        onTap: () {},
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    bool value,
    Color cardColor,
    Color textColor,
    bool isDark,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1B35).withOpacity(isDark ? 0.20 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF1A2D5A),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFF97316),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
