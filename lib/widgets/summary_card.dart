import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'shimmer_loading.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBg;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isLoading;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBg,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
    this.isSelected = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color textColor = theme.colorScheme.onSurface;
    final Color cardColor = theme.cardColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? badgeColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkSlate.withValues(alpha: isDark ? 0.25 : 0.07),
              blurRadius: 12,
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
                isLoading
                    ? const SkeletonContainer(
                        width: 34,
                        height: 34,
                        borderRadius: 10,
                      )
                    : Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: iconColor, size: 17),
                      ),
                isLoading
                    ? const SkeletonContainer(
                        width: 34,
                        height: 14,
                        borderRadius: 8,
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 14),
            isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 2, bottom: 2),
                    child: SkeletonContainer(
                      width: 80,
                      height: 11,
                      borderRadius: 4,
                    ),
                  )
                : Text(
                    title,
                    style: TextStyle(
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
            const SizedBox(height: 3),
            isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.5),
                    child: SkeletonContainer(
                      width: 90,
                      height: 15,
                      borderRadius: 4,
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
