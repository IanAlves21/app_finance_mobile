import 'package:flutter/material.dart';
import 'shimmer_loading.dart';

class TransactionSkeleton extends StatelessWidget {
  final int itemCount;

  const TransactionSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              // Skeleton Icon Container
              SkeletonContainer(
                width: 44,
                height: 44,
                borderRadius: 14,
              ),
              SizedBox(width: 14),

              // Skeleton Title & Date Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skeleton Title
                    SkeletonContainer(
                      width: 120,
                      height: 14,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 8),

                    // Skeleton Date
                    SkeletonContainer(
                      width: 70,
                      height: 10,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),

              // Skeleton Amount
              SkeletonContainer(
                width: 80,
                height: 16,
                borderRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}
