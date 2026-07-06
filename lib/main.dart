import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tabs/home_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/wallets_tab.dart';
import 'tabs/settings_tab.dart';
import 'widgets/interactive_card.dart';
import 'widgets/add_transaction_bottom_sheet.dart';

// Global Notifier for App Theme Mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Finance Shared App',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          
          // LIGHT THEME (Clean corporate blue & grey)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            fontFamily: 'Nunito',
            cardColor: Colors.white,
            scaffoldBackgroundColor: const Color(0xFFF4F5F8),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A2D5A),
              primary: const Color(0xFFF97316),
              secondary: const Color(0xFF6366F1),
              surface: const Color(0xFFF4F5F8),
              onSurface: const Color(0xFF0F1B35),
            ),
          ),

          // DARK THEME (Stunning Midnight Navy & Obsidian Palette)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            fontFamily: 'Nunito',
            cardColor: const Color(0xFF151B2D), // Rich midnight navy card
            scaffoldBackgroundColor: const Color(0xFF0B0F19), // Deep obsidian midnight background
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A2D5A),
              brightness: Brightness.dark,
              primary: const Color(0xFFF97316),
              secondary: const Color(0xFF818CF8),
              surface: const Color(0xFF151B2D),
              onSurface: const Color(0xFFF1F5F9), // Gorgeous soft off-white text
            ),
          ),
          
          home: const DashboardScreen(),
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

  void _showAddTransactionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AddTransactionBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final SystemUiOverlayStyle systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? const Color(0xFF151B2D) : Colors.white,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );

    // We wrap the main screen in AnnotatedRegion to color the Android system navigation bar
    // and in AnimatedTheme to create a beautiful 400ms cross-fade animation!
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
                      _buildNavItem(0, Icons.home_rounded, 'Home', isDark),
                      _buildNavItem(1, Icons.bar_chart_rounded, 'Analytics', isDark),
                      const SizedBox(width: 80),
                      _buildNavItem(2, Icons.account_balance_wallet_rounded, 'Wallets', isDark),
                      _buildNavItem(3, Icons.settings_rounded, 'Settings', isDark),
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
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7A99)); // Slate 400 for dark, Slate 600 for light

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
