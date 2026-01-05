import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class HeightStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const HeightStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<HeightStep> {
  late ScrollController _scrollController;
  final double _minHeight = 140;
  final double _maxHeight = 220;
  final double _itemWidth = 12;
  int? _lastHapticValue;

  @override
  void initState() {
    super.initState();
    final initialOffset = (widget.profile.heightCm - _minHeight) * _itemWidth;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final height = _minHeight + (offset / _itemWidth);
    final clampedHeight = height.clamp(_minHeight, _maxHeight);

    // Haptic feedback logic
    final int roundedHeight = clampedHeight.round();
    if (_lastHapticValue != roundedHeight) {
      HapticFeedback.selectionClick();
      _lastHapticValue = roundedHeight;
    }

    setState(() {
      widget.profile.heightCm = clampedHeight;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayHeight = widget.profile.heightCm.round();

    return OnboardingStepLayout(
      title: "Boyun kaç cm?",
      subtitle: "BMI ve kalori hesaplaması için boyunu bilmemiz gerekiyor.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Height Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$displayHeight",
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
                  " cm",
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

          // Ruler
          SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ruler Track
                SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width / 2 - 20,
                    ),
                    child: Row(
                      children: List.generate(
                        ((_maxHeight - _minHeight) + 1).toInt(),
                        (index) {
                          final value = _minHeight + index;
                          final isMajor = value % 10 == 0;
                          final isMedium = value % 5 == 0;

                          return SizedBox(
                            width: _itemWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: isMajor ? 3 : (isMedium ? 2 : 1),
                                  height: isMajor ? 50 : (isMedium ? 35 : 20),
                                  decoration: BoxDecoration(
                                    color: isMajor
                                        ? AppColors.primary
                                        : Colors.white.withValues(
                                            alpha: isMedium ? 0.5 : 0.2,
                                          ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                if (isMajor) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    "${value.toInt()}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Center Indicator
                IgnorePointer(
                  child: Container(
                    width: 4,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // Left/Right fade gradients
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 60,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.background,
                            AppColors.background.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 60,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            AppColors.background,
                            AppColors.background.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
