import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/service_locator.dart';
import '../widgets/custom_toast.dart';
import '../viewmodels/register_view_model.dart';
import '../widgets/interactive_card.dart';

class RegisterScreen extends StatefulWidget {
  final RegisterViewModel? viewModel;

  const RegisterScreen({super.key, this.viewModel});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterViewModel _viewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmPasswordFocusNode;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? locator<RegisterViewModel>();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _nameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();

    // Bind text controllers to viewmodel
    _nameController.addListener(() {
      _viewModel.setName(_nameController.text);
    });
    _emailController.addListener(() {
      _viewModel.setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      _viewModel.setPassword(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      _viewModel.setConfirmPassword(_confirmPasswordController.text);
    });

    // Detect focus states to animate borders dynamically
    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        _viewModel.setFocusedField('name');
      } else if (_viewModel.focusedField == 'name') {
        _viewModel.setFocusedField(null);
      }
    });

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

    _confirmPasswordFocusNode.addListener(() {
      if (_confirmPasswordFocusNode.hasFocus) {
        _viewModel.setFocusedField('confirmPassword');
      } else if (_viewModel.focusedField == 'confirmPassword') {
        _viewModel.setFocusedField(null);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      CustomToast.showError(context, l10n.pleaseFillAllFields);
      return;
    }

    if (_passwordController.text.length < 6) {
      CustomToast.showError(context, l10n.passwordTooShort);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      CustomToast.showError(context, l10n.passwordsDoNotMatch);
      return;
    }

    _viewModel.submitRegister(
      onSuccess: () {
        CustomToast.showSuccess(context, l10n.registerSuccess);
        Navigator.of(context).pop(); // Volta para o login
      },
      onError: (errorMsg) {
        CustomToast.showError(context, errorMsg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color textColor = theme.colorScheme.onSurface;
    final Color subTextColor = isDark ? AppColors.slate400 : AppColors.slate600;
    final Color cardBg = theme.cardColor;

    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor:
          isDark ? AppColors.darkCard : AppColors.lightScaffold,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final bool isNameFocused = _viewModel.focusedField == 'name';
        final bool isEmailFocused = _viewModel.focusedField == 'email';
        final bool isPasswordFocused = _viewModel.focusedField == 'password';
        final bool isConfirmPasswordFocused =
            _viewModel.focusedField == 'confirmPassword';

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Scaffold(
            backgroundColor:
                isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
            body: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // ── TOP NAVY SECTION ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 60,
                      left: 32,
                      right: 32,
                      bottom: 36,
                    ),
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
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Logo Mark
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.accentOrangeLight,
                                AppColors.accentOrange,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentOrange.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.registerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.registerSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── FORM SECTION ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        Text(
                          l10n.nameLabel,
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
                              color: isNameFocused
                                  ? AppColors.accentOrange
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            boxShadow: [
                              isNameFocused
                                  ? BoxShadow(
                                      color: AppColors.accentOrange.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  : BoxShadow(
                                      color: AppColors.darkSlate.withValues(
                                        alpha: isDark ? 0.20 : 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                color: isNameFocused
                                    ? AppColors.accentOrange
                                    : AppColors.slate400,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  focusNode: _nameFocusNode,
                                  keyboardType: TextInputType.name,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: l10n.namePlaceholder,
                                    hintStyle: TextStyle(
                                      color: subTextColor.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontWeight: FontWeight.normal,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Email Field
                        Text(
                          l10n.emailLabel,
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
                              color: isEmailFocused
                                  ? AppColors.accentOrange
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            boxShadow: [
                              isEmailFocused
                                  ? BoxShadow(
                                      color: AppColors.accentOrange.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  : BoxShadow(
                                      color: AppColors.darkSlate.withValues(
                                        alpha: isDark ? 0.20 : 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                color: isEmailFocused
                                    ? AppColors.accentOrange
                                    : AppColors.slate400,
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
                                    hintText: l10n.emailPlaceholder,
                                    hintStyle: TextStyle(
                                      color: subTextColor.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontWeight: FontWeight.normal,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        Text(
                          l10n.passwordLabel,
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
                              color: isPasswordFocused
                                  ? AppColors.accentOrange
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            boxShadow: [
                              isPasswordFocused
                                  ? BoxShadow(
                                      color: AppColors.accentOrange.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  : BoxShadow(
                                      color: AppColors.darkSlate.withValues(
                                        alpha: isDark ? 0.20 : 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: isPasswordFocused
                                    ? AppColors.accentOrange
                                    : AppColors.slate400,
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
                                      color: subTextColor.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontWeight: FontWeight.normal,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
                        const SizedBox(height: 18),

                        // Confirm Password Field
                        Text(
                          l10n.confirmPasswordLabel,
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
                              color: isConfirmPasswordFocused
                                  ? AppColors.accentOrange
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            boxShadow: [
                              isConfirmPasswordFocused
                                  ? BoxShadow(
                                      color: AppColors.accentOrange.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  : BoxShadow(
                                      color: AppColors.darkSlate.withValues(
                                        alpha: isDark ? 0.20 : 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: isConfirmPasswordFocused
                                    ? AppColors.accentOrange
                                    : AppColors.slate400,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  obscureText: !_viewModel.showConfirmPassword,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: l10n.confirmPasswordPlaceholder,
                                    hintStyle: TextStyle(
                                      color: subTextColor.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontWeight: FontWeight.normal,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _viewModel.toggleShowConfirmPassword,
                                child: Icon(
                                  _viewModel.showConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.slate400,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

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
                                      colors: [
                                        AppColors.accentOrangeLight,
                                        AppColors.accentOrange,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: _viewModel.loading
                                  ? AppColors.accentOrange.withValues(
                                      alpha: 0.6,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: _viewModel.loading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppColors.accentOrange
                                            .withValues(alpha: 0.38),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.registerButton,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        // Signup Footer
                        const SizedBox(height: 36),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.alreadyHaveAccount,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.loginLink,
                                style: const TextStyle(
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
