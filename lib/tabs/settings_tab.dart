import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart'; // Import Custom Localization
import '../main.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/shared_avatars.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel();
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

    // Dynamic styles based on theme
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
                    l10n.settings,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.customizePreferences,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
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
                          color: AppColors.darkSlate.withValues(
                            alpha: isDark ? 0.25 : 0.04,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SharedAvatars(
                          size: 36.0,
                          overlap: 20.0,
                          hasBorder: false,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ValueListenableBuilder<User?>(
                            valueListenable: currentUserNotifier,
                            builder: (context, user, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Lucas & Mariana',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    user?.email ?? l10n.premiumPlan,
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
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
                  _buildSectionHeader(l10n.accountSettings, subTextColor),
                  _buildSettingTile(
                    Icons.person_outline_rounded,
                    l10n.editProfiles,
                    l10n.managePersonalProfiles,
                    cardColor,
                    textColor,
                    subTextColor,
                    isDark,
                  ),
                  _buildSettingTile(
                    Icons.link_rounded,
                    l10n.connectedBanks,
                    l10n.banksLinked,
                    cardColor,
                    textColor,
                    subTextColor,
                    isDark,
                  ),
                  _buildSettingTile(
                    Icons.card_giftcard_outlined,
                    l10n.cardsSettings,
                    l10n.cardsSubtitle,
                    cardColor,
                    textColor,
                    subTextColor,
                    isDark,
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader(l10n.preferences, subTextColor),
                  _buildToggleTile(
                    Icons.translate_rounded,
                    'English Language',
                    _viewModel.isEnglish,
                    cardColor,
                    textColor,
                    isDark,
                    (v) {
                      _viewModel.toggleLanguage(v);
                    },
                  ),
                  _buildToggleTile(
                    Icons.dark_mode_outlined,
                    l10n.darkModeLabel,
                    _viewModel.darkMode,
                    cardColor,
                    textColor,
                    isDark,
                    (v) {
                      _viewModel.toggleDarkMode(v);
                    },
                  ),
                  _buildToggleTile(
                    Icons.notifications_none_rounded,
                    l10n.pushNotifications,
                    _viewModel.pushNotifications,
                    cardColor,
                    textColor,
                    isDark,
                    (v) {
                      _viewModel.togglePushNotifications(v);
                    },
                  ),
                  _buildToggleTile(
                    Icons.fingerprint_rounded,
                    l10n.biometricSignIn,
                    _viewModel.biometricAuth,
                    cardColor,
                    textColor,
                    isDark,
                    (v) {
                      _viewModel.toggleBiometricAuth(v);
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader(l10n.support, subTextColor),
                  _buildSettingTile(
                    Icons.help_outline_rounded,
                    l10n.helpCenter,
                    l10n.faqsSupport,
                    cardColor,
                    textColor,
                    subTextColor,
                    isDark,
                  ),
                  _buildSettingTile(
                    Icons.policy_outlined,
                    l10n.privacyPolicy,
                    l10n.dataSecurity,
                    cardColor,
                    textColor,
                    subTextColor,
                    isDark,
                  ),
                  _buildSettingTile(
                    Icons.logout_rounded,
                    _viewModel.isEnglish ? 'Sign Out' : 'Sair',
                    _viewModel.isEnglish ? 'Disconnect from joint account' : 'Desconectar da conta conjunta',
                    cardColor,
                    isDark ? AppColors.redAccent : Colors.red,
                    subTextColor,
                    isDark,
                    onTap: _viewModel.logout,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkSlate.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDark ? AppColors.accentVioletLight : AppColors.primarySeed,
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
          color: isDark ? Colors.white30 : AppColors.slate300,
          size: 14,
        ),
        onTap: onTap ?? () {},
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
            color: AppColors.darkSlate.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: isDark ? AppColors.accentVioletLight : AppColors.primarySeed,
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
        activeThumbColor: AppColors.accentOrange,
        activeTrackColor: AppColors.accentOrange.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
