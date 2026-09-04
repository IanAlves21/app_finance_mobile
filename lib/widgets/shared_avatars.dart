import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'shimmer_loading.dart';

class SharedAvatars extends StatelessWidget {
  final List<dynamic>? members;
  final double size;
  final double overlap;
  final double borderWidth;
  final bool hasBorder;
  final bool isLoading;

  const SharedAvatars({
    super.key,
    this.members,
    this.size = 40.0,
    this.overlap = 24.0,
    this.borderWidth = 2.5,
    this.hasBorder = true,
    this.isLoading = false,
  });

  String _getInitial(dynamic member) {
    if (member == null) return '?';
    if (member is Map) {
      final String? name = member['name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        return name.trim()[0].toUpperCase();
      }
    } else if (member is String) {
      if (member.trim().isNotEmpty) {
        return member.trim()[0].toUpperCase();
      }
    }
    return '?';
  }

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

    // Default to 'L' and 'M' if members list is null or empty
    final displayMembers = (members != null && members!.isNotEmpty)
        ? members!
        : ['L', 'M'];

    final int count = displayMembers.length;

    return SizedBox(
      width: count > 1 ? (size + overlap) : size,
      height: size,
      child: Stack(
        children: List.generate(count > 2 ? 2 : count, (index) {
          final member = displayMembers[index];
          final double leftPos = index * overlap;
          
          final List<Color> gradientColors = index == 0
              ? [AppColors.accentOrange, AppColors.accentOrangeLight]
              : [AppColors.accentViolet, AppColors.accentVioletLight];

          return Positioned(
            left: leftPos,
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
                gradient: LinearGradient(
                  colors: gradientColors,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _getInitial(member),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
