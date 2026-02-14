import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Branded card container with optional gradient background
class HCCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool useGradient;
  final VoidCallback? onTap;

  const HCCard({
    super.key,
    required this.child,
    this.padding,
    this.useGradient = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(HCSpacing.md),
      decoration: BoxDecoration(
        gradient: useGradient ? HCColors.accentBoxGradient : null,
        color: useGradient ? null : HCColors.bgCard,
        borderRadius: BorderRadius.circular(HCRadius.md),
        border: Border.all(color: HCColors.border),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
