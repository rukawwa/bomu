import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class WeightStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const WeightStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<WeightStep> {
  final double _minWeight = 40;
  final double _maxWeight = 150;

  @override
  Widget build(BuildContext context) {
    // Show 1 decimal place if it has a decimal part, otherwise integer
    final isWhole = widget.profile.weightKg % 1 == 0;
    final displayWeight = isWhole
        ? widget.profile.weightKg.toInt().toString()
        : widget.profile.weightKg.toStringAsFixed(1);

    return OnboardingStepLayout(
      title: "Şu anki kilon?",
      subtitle:
          "Günlük kalori ihtiyacını hesaplamak için kilonu bilmemiz gerekiyor.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Weight Display (No Box)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayWeight,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  " kg",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Custom Slider
          Column(
            children: [
              // Scale ticks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (
                    var i = _minWeight.toInt();
                    i <= _maxWeight.toInt();
                    i += 20
                  )
                    Text(
                      "$i",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Slider Track
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 16,
                    elevation: 4,
                  ),
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 28,
                  ),
                ),
                child: Slider(
                  value: widget.profile.weightKg,
                  min: _minWeight,
                  max: _maxWeight,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      // Round to 0.1 precision for slider drag
                      widget.profile.weightKg =
                          (value * 10).roundToDouble() / 10;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Quick adjust buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAdjustButton(
                    icon: Icons.remove,
                    onTap: () {
                      if (widget.profile.weightKg > _minWeight) {
                        HapticFeedback.lightImpact();
                        setState(() => widget.profile.weightKg -= 0.5);
                      }
                    },
                  ),
                  const SizedBox(width: 24),
                  _buildAdjustButton(
                    icon: Icons.add,
                    onTap: () {
                      if (widget.profile.weightKg < _maxWeight) {
                        HapticFeedback.lightImpact();
                        setState(() => widget.profile.weightKg += 0.5);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
