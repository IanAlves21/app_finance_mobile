import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomToast {
  static void showError(BuildContext context, String message) {
    _show(context, message, isError: true);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, isError: false);
  }

  static void _show(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Remove qualquer SnackBar ativo para que o novo apareça de imediato
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final Color bgColor = isError
        ? (isDark ? const Color(0xFF1E1416) : const Color(0xFFFFF5F5))
        : (isDark ? const Color(0xFF101B15) : const Color(0xFFF2FDF5));

    final Color borderColor = isError
        ? (isDark
              ? AppColors.redAccent.withValues(alpha: 0.4)
              : const Color(0xFFFEE2E2))
        : (isDark
              ? AppColors.greenAccent.withValues(alpha: 0.4)
              : const Color(0xFFDCFCE7));

    final Color iconColor = isError
        ? AppColors.redAccent
        : AppColors.greenAccent;
    final IconData icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    final Color textColor = isDark
        ? const Color(0xFFF1F5F9)
        : AppColors.darkSlate;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
