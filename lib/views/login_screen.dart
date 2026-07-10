import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../viewmodels/login_view_model.dart';
import '../widgets/interactive_card.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _viewModel;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    // Bind text controllers to viewmodel
    _emailController.addListener(() {
      _viewModel.setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      _viewModel.setPassword(_passwordController.text);
    });

    // Detect focus states to animate borders dynamically
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        _viewModel.setFocusedField('email');
      } else if (_viewModel.focusedField == 'email') {
        _viewModel.setFocusedField(null);
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        _viewModel.setFocusedField('password');
      } else if (_viewModel.focusedField == 'password') {
        _viewModel.setFocusedField(null);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos.'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }
    _viewModel.submitLogin(widget.onLogin);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark ? AppColors.slate400 : AppColors.slate600;
    final Color cardBg = theme.cardColor;

    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Ícones brancos pois o gradiente do topo é sempre escuro
      statusBarBrightness: Brightness.dark, // Ícones brancos no iOS
      systemNavigationBarColor: isDark ? AppColors.darkCard : AppColors.lightScaffold,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final bool isEmailFocused = _viewModel.focusedField == 'email';
        final bool isPasswordFocused = _viewModel.focusedField == 'password';

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Scaffold(
            backgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
            body: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // ── TOP NAVY SECTION ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 72, left: 32, right: 32, bottom: 48),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primarySeed, AppColors.darkSlate],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Animated Logo Mark
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentOrangeLight, AppColors.accentOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentOrange.withValues(alpha: 0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Bem-vindos de volta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sua vida financeira a dois',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── FORM SECTION ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email Field
                        Text(
                          'E-MAIL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: subTextColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isEmailFocused ? AppColors.accentOrange : Colors.transparent,
                              width: 2.0,
                            ),
                            boxShadow: [
                              isEmailFocused
                                  ? BoxShadow(
                                      color: AppColors.accentOrange.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  : BoxShadow(
                                      color: AppColors.darkSlate.withValues(alpha: isDark ? 0.20 : 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                color: isEmailFocused ? AppColors.accentOrange : AppColors.slate400,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'voces@email.com',
                                    hintStyle: TextStyle(
                                      color: subTextColor.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.normal,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        Text(
                          'SENHA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: subTextColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPasswordFocused ? AppColors.accentOrange : Colors.transparent,
                              width: 2.0,
                            ),
                            boxShadow: [
                              isPasswordFocused
                                  ? BoxShadow(
                                      color: AppColors.accentOrange.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  : BoxShadow(
                                      color: AppColors.darkSlate.withValues(alpha: isDark ? 0.20 : 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: isPasswordFocused ? AppColors.accentOrange : AppColors.slate400,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: !_viewModel.showPassword,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '••••••••',
                                    hintStyle: TextStyle(
                                      color: subTextColor.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.normal,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _viewModel.toggleShowPassword,
                                child: Icon(
                                  _viewModel.showPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.slate400,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Forgot Password Link
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Esqueceu a senha?',
                              style: TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        InteractiveCard(
                          onTap: _viewModel.loading ? () {} : _handleSubmit,
                          scaleOnPressed: 0.97,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: _viewModel.loading
                                  ? null
                                  : const LinearGradient(
                                      colors: [AppColors.accentOrangeLight, AppColors.accentOrange],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: _viewModel.loading ? AppColors.accentOrange.withValues(alpha: 0.6) : null,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: _viewModel.loading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppColors.accentOrange.withValues(alpha: 0.38),
                                        blurRadius: 24,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            alignment: Alignment.center,
                            child: _viewModel.loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Entrar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        // Divider
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: isDark ? AppColors.slate800 : AppColors.slate200,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'ou continue com',
                                style: TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: isDark ? AppColors.slate800 : AppColors.slate200,
                              ),
                            ),
                          ],
                        ),

                        // Social Buttons
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            // Google Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.slate800 : AppColors.slate200,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.darkSlate.withValues(alpha: isDark ? 0.20 : 0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google Icon Representation
                                      Image.network(
                                        'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                        width: 18,
                                        height: 18,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.g_mobiledata_rounded,
                                          color: AppColors.accentOrange,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Google',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Apple Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.slate800 : AppColors.slate200,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.darkSlate.withValues(alpha: isDark ? 0.20 : 0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.apple_rounded,
                                        color: textColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Apple',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Signup Footer
                        const SizedBox(height: 36),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Novo casal? ',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Criar conta juntos',
                                style: TextStyle(
                                  color: AppColors.accentOrange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        },
        );
        }
        }
