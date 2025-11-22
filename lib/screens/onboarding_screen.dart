import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userName;
  final double bmi;

  const OnboardingScreen({
    super.key,
    required this.userName,
    required this.bmi,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedGoal = "";

  // BMI Durumu Hesaplama
  String _getBMIStatus(double bmi) {
    if (bmi < 18.5) return "Zayıf";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Fazla Kilolu";
    return "Obez";
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blueAccent;
    if (bmi < 25) return AppColors.primary;
    if (bmi < 30) return Colors.orange;
    return AppColors.secondary;
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bmiStatus = _getBMIStatus(widget.bmi);
    final bmiColor = _getBMIColor(widget.bmi);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              // 1. BMI SONUÇ EKRANI
              _buildSlide(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Merhaba ${widget.userName}!",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: bmiColor, width: 4),
                        boxShadow: [BoxShadow(color: bmiColor.withOpacity(0.3), blurRadius: 30)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("BMI", style: TextStyle(color: AppColors.textMuted)),
                          Text(
                            widget.bmi.toStringAsFixed(1),
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: bmiColor),
                          ),
                          Text(bmiStatus, style: TextStyle(fontSize: 16, color: bmiColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "Vücut analizine göre $bmiStatus kategorisindesin. Senin için en uygun rotayı oluşturacağız.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. HEDEF SEÇİMİ
              _buildSlide(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Hedefin Ne?",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Sana özel planı hazırlamamız için seç.",
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 40),
                    _buildGoalOption("Kilo Vermek", "🔥", "Daha fit bir vücut"),
                    const SizedBox(height: 16),
                    _buildGoalOption("Korumak", "⚖️", "Mevcut formunu koru"),
                    const SizedBox(height: 16),
                    _buildGoalOption("Kas Yapmak", "💪", "Güçlen ve hacim kazan"),
                  ],
                ),
              ),
            ],
          ),

          // İLERLEME VE BUTONLAR
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dots Indicator
                Row(
                  children: List.generate(2, (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    height: 6,
                    width: _currentPage == index ? 24 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : Colors.white10,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
                ),
                
                // Next / Finish Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == 0) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else {
                      if (_selectedGoal.isNotEmpty) {
                        _finishOnboarding();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Lütfen bir hedef seçin")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_currentPage == 0 ? "Devam Et" : "Başla"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  Widget _buildGoalOption(String title, String icon, String subtitle) {
    final isSelected = _selectedGoal == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}