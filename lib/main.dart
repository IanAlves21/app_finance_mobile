import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart'; // Import Custom Localization
import 'theme/app_colors.dart';
import 'tabs/home_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/wallets_tab.dart';
import 'tabs/settings_tab.dart';
import 'widgets/interactive_card.dart';
import 'widgets/add_transaction_bottom_sheet.dart';
import 'views/login_screen.dart';
import 'viewmodels/login_view_model.dart';
import 'models/user.dart';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global Notifier for App Logged In state
final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(false);

// Global Notifier for Refreshing Transactions across tabs
final ValueNotifier<int> transactionRefreshNotifier = ValueNotifier<int>(0);

// Global Notifier for App Current User data
final ValueNotifier<User?> currentUserNotifier = ValueNotifier<User?>(null);

// Global Notifier for App Theme Mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

// Global Notifier for App Locale - Dynamically follows system settings (defaults to 'en')
final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(_getInitialLocale());

Locale _getInitialLocale() {
  final ui.Locale systemLocale = ui.PlatformDispatcher.instance.locale;
  final String languageCode = systemLocale.languageCode;
  
  if (languageCode == 'pt') {
    return const Locale('pt');
  }
  
  // Default to English
  return const Locale('en');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Load persistent login session before running the app
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');
    
    // Verifica se temos um token salvo e se ele ainda é válido (não expirou)
    if (token != null && !ApiService.isTokenExpired(token)) {
      isLoggedInNotifier.value = true;
      final String? id = prefs.getString('user_id');
      final String? name = prefs.getString('user_name');
      final String? email = prefs.getString('user_email');
      if (id != null && name != null && email != null) {
        currentUserNotifier.value = User(id: id, name: name, email: email);
      }
    } else {
      // Se expirou ou não existe, limpa localmente para forçar nova autenticação
      isLoggedInNotifier.value = false;
      currentUserNotifier.value = null;
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('access_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
    }
  } catch (e) {
    debugPrint('Error loading persistent session: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final LoginViewModel? loginViewModel;

  const MyApp({super.key, this.loginViewModel});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (_, Locale currentLocale, __) {
            return MaterialApp(
              title: 'Finance Shared App',
              debugShowCheckedModeBanner: false,
              themeMode: currentMode,
              locale: currentLocale, // Dynamic locale driven by notifier
              
              // REGISTER OUR CUSTOM l10n DELEGATES
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              
              // LIGHT THEME (Clean corporate blue & grey)
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                fontFamily: 'Nunito',
                cardColor: AppColors.lightCard,
                scaffoldBackgroundColor: AppColors.lightScaffold,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primarySeed,
                  primary: AppColors.accentOrange,
                  secondary: AppColors.accentViolet,
                  surface: AppColors.lightScaffold,
                  onSurface: AppColors.darkSlate,
                ),
              ),

              // DARK THEME (Stunning Midnight Navy & Obsidian Palette)
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                fontFamily: 'Nunito',
                cardColor: AppColors.darkCard, // Rich midnight navy card
                scaffoldBackgroundColor: AppColors.darkScaffold, // Deep obsidian midnight background
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primarySeed,
                  brightness: Brightness.dark,
                  primary: AppColors.accentOrange,
                  secondary: AppColors.accentVioletLight,
                  surface: AppColors.darkCard,
                  onSurface: const Color(0xFFF1F5F9), // Gorgeous soft off-white text
                ),
              ),
              
              home: ValueListenableBuilder<bool>(
                valueListenable: isLoggedInNotifier,
                builder: (context, isLoggedIn, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final bool isDashboard = child.key == const ValueKey('DashboardScreen');
                      // Dashboard (Painel) fica posicionado à direita (1.0, 0.0) e Login fica à esquerda (-1.0, 0.0).
                      // O próprio AnimatedSwitcher reverte a animação automaticamente na saída (exit), fazendo com que
                      // o fluxo seja 100% simétrico e livre de dependências de estado externo (isLoggedIn) no cache!
                      final Offset beginOffset = isDashboard ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);

                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: beginOffset,
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: isLoggedIn
                        ? const DashboardScreen(key: ValueKey('DashboardScreen'))
                        : LoginScreen(
                            key: const ValueKey('LoginScreen'),
                            viewModel: loginViewModel,
                            onLogin: () async {
                              try {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('is_logged_in', true);
                              } catch (e) {
                                debugPrint('Error saving persistent session: $e');
                              }
                              isLoggedInNotifier.value = true;
                            },
                          ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ── MAIN DASHBOARD LAYOUT ──
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const AnalyticsTab(),
    const WalletsTab(),
    const SettingsTab(),
  ];

  void _showAddTransactionBottomSheet() async {
    final bool? shouldRefresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AddTransactionBottomSheet();
      },
    );

    if (shouldRefresh == true) {
      transactionRefreshNotifier.value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    // Resolve dynamic localization keys
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final SystemUiOverlayStyle systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? const Color(0xFF151B2D) : Colors.white,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: AnimatedTheme(
        data: theme,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: _tabs[_currentIndex],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 90 + bottomPadding,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F1B35).withOpacity(isDark ? 0.35 : 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12 + bottomPadding, left: 8, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, l10n.homeNav, isDark),
                        _buildNavItem(1, Icons.bar_chart_rounded, l10n.analyticsNav, isDark),
                        const SizedBox(width: 80),
                        _buildNavItem(2, Icons.account_balance_wallet_rounded, l10n.walletsNav, isDark),
                        _buildNavItem(3, Icons.settings_rounded, l10n.settingsNav, isDark),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 38 + bottomPadding,
                left: MediaQuery.of(context).size.width / 2 - 30,
                child: InteractiveCard(
                  scaleOnPressed: 0.92,
                  onTap: _showAddTransactionBottomSheet,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF4F5F8), 
                        width: 4,
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withOpacity(0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final bool isActive = _currentIndex == index;
    final Color color = isActive 
        ? const Color(0xFFF97316) 
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7A99));

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
