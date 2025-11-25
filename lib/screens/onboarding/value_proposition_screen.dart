import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../theme.dart';
import '../main_screen.dart';

class ValuePropositionScreen extends StatelessWidget {
  final UserProfile userProfile;

  const ValuePropositionScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final goalDate =
        userProfile.estimatedGoalDate ??
        DateTime.now().add(const Duration(days: 90));
    final formattedDate = DateFormat('d MMMM yyyy', 'tr_TR').format(goalDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Header
              Text(
                "Sözümüz Söz.",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 24),

              // Value Props
              _buildPromiseItem(
                icon: Icons.calendar_today_rounded,
                text: "$formattedDate tarihine kadar hedefine ulaşacaksın.",
              ),
              _buildPromiseItem(
                icon: Icons.no_food_rounded,
                text: "Aç kalmadan, sevdiğin yemekleri yiyerek.",
              ),
              _buildPromiseItem(
                icon: Icons.psychology_rounded,
                text:
                    "${userProfile.mainChallenge} sorununu birlikte aşacağız.",
              ),
              _buildPromiseItem(
                icon: Icons.trending_up_rounded,
                text: "Her gün %1 daha iyi olacaksın.",
              ),

              const Spacer(),

              // CTA
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainScreen(
                          initialDailyGoal: userProfile.dailyCalorieLimit,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Ücretsiz Başla",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "Kredi kartı gerekmez.",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromiseItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
