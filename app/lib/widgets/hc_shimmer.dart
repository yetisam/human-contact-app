import 'package:flutter/material.dart';
import '../config/theme.dart';

/// A reusable shimmer loading widget that pulses between two colors
class HCShimmer extends StatefulWidget {
  final Widget child;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const HCShimmer({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.borderRadius,
  });

  /// Creates a shimmer card placeholder matching HCCard dimensions
  const HCShimmer.card({
    super.key,
    this.height = 200,
    this.width = double.infinity,
  }) : child = const SizedBox.shrink(),
       borderRadius = const BorderRadius.all(Radius.circular(HCRadius.md));

  /// Creates a shimmer list item placeholder
  const HCShimmer.listItem({
    super.key,
    this.height = 80,
    this.width = double.infinity,
  }) : child = const SizedBox.shrink(),
       borderRadius = const BorderRadius.all(Radius.circular(HCRadius.md));

  @override
  State<HCShimmer> createState() => _HCShimmerState();
}

class _HCShimmerState extends State<HCShimmer> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(
              HCColors.bgCard, 
              HCColors.bgInput, 
              _animation.value,
            ),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(HCRadius.md),
            border: Border.all(color: HCColors.border),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// A shimmer skeleton that shows content placeholders
class HCShimmerSkeleton extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const HCShimmerSkeleton({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return HCShimmer(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(HCSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// Pre-built shimmer placeholders for common UI elements
class HCShimmerElements {
  HCShimmerElements._();

  /// A shimmer line (for text placeholders)
  static Widget line({double? width, double height = 16}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: HCColors.bgInput.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// A shimmer circle (for avatar placeholders)
  static Widget circle({double radius = 24}) {
    return Container(
      height: radius * 2,
      width: radius * 2,
      decoration: BoxDecoration(
        color: HCColors.bgInput.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  /// A shimmer card placeholder for match cards
  static Widget matchCard() {
    return HCShimmerSkeleton(
      children: [
        // Header row
        Row(
          children: [
            circle(),
            const SizedBox(width: HCSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line(width: 120),
                  const SizedBox(height: 4),
                  line(width: 80, height: 12),
                ],
              ),
            ),
            line(width: 40, height: 24),
          ],
        ),
        const SizedBox(height: HCSpacing.md),
        
        // Purpose statement
        line(),
        const SizedBox(height: 4),
        line(width: 200),
        
        const SizedBox(height: HCSpacing.md),
        
        // Tags
        Wrap(
          spacing: 6,
          children: [
            line(width: 80, height: 20),
            line(width: 60, height: 20),
            line(width: 100, height: 20),
          ],
        ),
        
        const SizedBox(height: HCSpacing.md),
        
        // Button placeholder
        line(height: 48),
      ],
    );
  }

  /// A shimmer list item placeholder for connections
  static Widget connectionItem() {
    return HCShimmerSkeleton(
      children: [
        Row(
          children: [
            circle(radius: 20),
            const SizedBox(width: HCSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line(width: 100),
                  const SizedBox(height: 4),
                  line(width: 150, height: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}