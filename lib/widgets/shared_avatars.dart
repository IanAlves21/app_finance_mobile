import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'shimmer_loading.dart';

class SharedAvatars extends StatelessWidget {
  final double size;
  final double overlap;
  final double borderWidth;
  final bool hasBorder;
  final bool isLoading;

  const SharedAvatars({
    super.key,
    this.size = 40.0,
    this.overlap = 24.0,
    this.borderWidth = 2.5,
    this.hasBorder = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: size + overlap,
        height: size,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: SkeletonContainer(
                width: size,
                height: size,
                borderRadius: size / 2,
              ),
            ),
            Positioned(
              left: overlap,
              child: SkeletonContainer(
                width: size,
                height: size,
                borderRadius: size / 2,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: size + overlap,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: hasBorder
                    ? Border.all(
                        color: AppColors.primarySeed,
                        width: borderWidth,
                      )
                    : null,
                gradient: const LinearGradient(
                  colors: [AppColors.accentOrange, AppColors.accentOrangeLight],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'L',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            left: overlap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: hasBorder
                    ? Border.all(
                        color: AppColors.primarySeed,
                        width: borderWidth,
                      )
                    : null,
                gradient: const LinearGradient(
                  colors: [AppColors.accentViolet, AppColors.accentVioletLight],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
