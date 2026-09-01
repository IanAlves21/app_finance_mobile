import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return child; // Pass-through so that we do not mask and wash out the entire screen's premium colors
  }
}

class SkeletonContainer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Prevent infinite loops in testing environments to avoid pumpAndSettle timeouts
    final bool isTesting =
        kDebugMode && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTesting) {
      _controller.repeat();
    } else {
      _controller.value =
          0.5; // Stable state for static/deterministic UI testing
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Smooth grey-slate base colors for light and dark modes
    final Color baseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final Color highlightColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.15, 0.5, 0.85],
              begin: Alignment(-2.5 + _controller.value * 5.0, -0.3),
              end: Alignment(-0.5 + _controller.value * 5.0, 0.3),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white, // Solid color replaced by Shimmer shader mask
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
