import 'package:flutter/material.dart';
import '../config/theme.dart';

class HCOfflineBanner extends StatelessWidget {
  final ValueNotifier<bool> isOnline;
  final VoidCallback? onRetry;

  const HCOfflineBanner({
    super.key,
    required this.isOnline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isOnline,
      builder: (context, online, child) {
        if (online) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: HCSpacing.md,
            vertical: HCSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: HCColors.warning,
            border: Border(
              bottom: BorderSide(color: HCColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off,
                color: HCColors.bgDark,
                size: 18,
              ),
              const SizedBox(width: HCSpacing.sm),
              Expanded(
                child: Text(
                  'No internet connection — check your connection and try again',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HCColors.bgDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: HCSpacing.sm),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: HCColors.bgDark.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(HCRadius.sm),
                    ),
                    child: Text(
                      'Retry',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HCColors.bgDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}