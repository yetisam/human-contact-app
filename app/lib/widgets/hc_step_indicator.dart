import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Step progress indicator for onboarding flow
/// Shows: Email → Phone → Profile → Done
class HCStepIndicator extends StatelessWidget {
  final int currentStep; // 0-based: 0=email, 1=phone, 2=profile
  final int totalSteps;

  const HCStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  static const _labels = ['Email', 'Phone', 'Profile'];
  static const _icons = [Icons.email, Icons.phone, Icons.person];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HCSpacing.lg, vertical: HCSpacing.md),
      child: Column(
        children: [
          // Step dots with connecting lines
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                // Step dot
                final step = index ~/ 2;
                final isCompleted = step < currentStep;
                final isCurrent = step == currentStep;

                return _buildStepDot(step, isCompleted, isCurrent);
              } else {
                // Connecting line
                final step = index ~/ 2;
                final isCompleted = step < currentStep;

                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? HCColors.success
                        : HCColors.border,
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 8),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (step) {
              final isCompleted = step < currentStep;
              final isCurrent = step == currentStep;

              return SizedBox(
                width: 70,
                child: Text(
                  _labels[step],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    color: isCompleted
                        ? HCColors.success
                        : isCurrent
                            ? HCColors.primary
                            : HCColors.textMuted,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, bool isCompleted, bool isCurrent) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? HCColors.success
            : isCurrent
                ? HCColors.primary
                : HCColors.bgInput,
        border: Border.all(
          color: isCompleted
              ? HCColors.success
              : isCurrent
                  ? HCColors.primary
                  : HCColors.border,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Icon(
                _icons[step],
                color: isCurrent ? Colors.white : HCColors.textMuted,
                size: 14,
              ),
      ),
    );
  }
}
