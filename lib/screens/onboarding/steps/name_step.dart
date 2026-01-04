import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class NameStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;

  const NameStep({super.key, required this.profile, required this.onNext});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.profile.name);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    widget.profile.name = value;
    if (value.isNotEmpty && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (value.isEmpty) {
      _animationController.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final name = _controller.text.trim();
    final hasName = name.isNotEmpty;

    return OnboardingStepLayout(
      title: "Sana nasıl\nseslenelim?",
      subtitle:
          "Seninle daha samimi konuşabilmemiz için ismini öğrenmek istiyoruz.",
      canProceed: hasName,
      onNext: hasName ? widget.onNext : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Text Field
          // Minimal Text Field
          TextField(
            controller: _controller,
            onChanged: _onNameChanged,
            autofocus: true,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: "İsmin",
              hintStyle: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.2),
                letterSpacing: -0.5,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),

          const SizedBox(height: 32),

          // Greeting Preview
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text("👋", style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Merhaba, $name!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
