import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'onboarding_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // --- STATE ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  // Boy/Kilo Controllerları
  final TextEditingController _heightController = TextEditingController(); // cm veya ft
  final TextEditingController _heightInchController = TextEditingController(); // inch (sadece imperial)
  final TextEditingController _weightController = TextEditingController(); // kg veya lbs

  String _gender = "";
  bool _isMetric = true; // true: cm/kg, false: ft/lbs

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _heightInchController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // --- YARDIMCI MANTIK ---
  void _toggleUnit(bool isMetric) {
    setState(() {
      _isMetric = isMetric;
      // Mevcut değerleri dönüştür (Opsiyonel, kullanıcı deneyimi için)
      _convertValues(toMetric: isMetric);
    });
  }

  void _convertValues({required bool toMetric}) {
    // Bu fonksiyon ekranlar arası geçişte veriyi korumak ve çevirmek için
    // Basitlik adına şu an sadece inputları temizliyoruz, 
    // isterseniz buraya matematiksel dönüşüm ekleyebilirsiniz.
    _heightController.clear();
    _heightInchController.clear();
    _weightController.clear();
  }

  double _calculateBMI() {
    double weight = double.tryParse(_weightController.text) ?? 0;
    double height = double.tryParse(_heightController.text) ?? 0;

    if (weight <= 0 || height <= 0) return 0;

    if (_isMetric) {
      // kg / m^2
      return weight / ((height / 100) * (height / 100));
    } else {
      // 703 * lbs / in^2
      double heightInch = double.tryParse(_heightInchController.text) ?? 0;
      double totalInches = (height * 12) + heightInch;
      if (totalInches <= 0) return 0;
      return 703 * weight / (totalInches * totalInches);
    }
  }

  void _nextStep() {
    // Klavye açıksa kapat
    FocusScope.of(context).unfocus();

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      // BİTİŞ: BMI Hesapla ve Onboarding'e git
      double bmi = _calculateBMI();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(
            userName: _nameController.text,
            bmi: bmi,
          ),
        ),
      );
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentStep + 1) / _totalSteps;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Boşluğa tıklayınca klavyeyi kapat
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _prevStep,
                )
              : null,
          title: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
          centerTitle: true,
          actions: const [SizedBox(width: 48)],
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ADIM 1: İSİM
                  _buildStep(
                    title: "Sana nasıl hitap edelim?",
                    child: _buildBigInput(
                      controller: _nameController,
                      hint: "İsmin...",
                      keyboardType: TextInputType.name,
                    ),
                  ),

                  // ADIM 2: CİNSİYET
                  _buildStep(
                    title: "Cinsiyetin nedir?",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSelectableCard("Erkek", "♂️", _gender == "Male",
                            () => setState(() => _gender = "Male")),
                        _buildSelectableCard("Kadın", "♀️", _gender == "Female",
                            () => setState(() => _gender = "Female")),
                      ],
                    ),
                  ),

                  // ADIM 3: YAŞ (Slider yerine Input)
                  _buildStep(
                    title: "Kaç yaşındasın?",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: _buildBigInput(
                            controller: _ageController,
                            hint: "00",
                            keyboardType: TextInputType.number,
                            align: TextAlign.center,
                            maxLength: 3,
                          ),
                        ),
                        const Text("Yaş", style: TextStyle(fontSize: 24, color: AppColors.textMuted)),
                      ],
                    ),
                  ),

                  // ADIM 4: BOY VE KİLO (Birim Dönüştürücülü)
                  _buildStep(
                    title: "Vücut ölçülerin?",
                    child: Column(
                      children: [
                        // Birim Seçici (Toggle)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          padding: const EdgeInsets.all(4),
                          margin: const EdgeInsets.only(bottom: 32),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildUnitToggleOption("Metrik (cm/kg)", _isMetric, () => _toggleUnit(true)),
                              _buildUnitToggleOption("US (ft/lbs)", !_isMetric, () => _toggleUnit(false)),
                            ],
                          ),
                        ),

                        // Boy Inputları
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.height, color: AppColors.primary),
                            const SizedBox(width: 16),
                            if (_isMetric)
                              // CM Girdisi
                              Expanded(
                                child: _buildLabeledInput(
                                  controller: _heightController,
                                  label: "Boy (cm)",
                                  hint: "175",
                                ),
                              )
                            else
                              // FT / IN Girdisi
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildLabeledInput(
                                        controller: _heightController,
                                        label: "Feet",
                                        hint: "5",
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildLabeledInput(
                                        controller: _heightInchController,
                                        label: "Inch",
                                        hint: "9",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),

                        // Kilo Inputları
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.monitor_weight_outlined, color: AppColors.secondary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildLabeledInput(
                                controller: _weightController,
                                label: _isMetric ? "Kilo (kg)" : "Kilo (lbs)",
                                hint: _isMetric ? "70" : "150",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // İLERLE BUTONU
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textMain,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentStep == _totalSteps - 1 ? "Yolculuğa Başla" : "Devam Et",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildStep({required String title, required Widget child}) {
    return SingleChildScrollView( // Küçük ekranlarda taşmayı önlemek için
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBigInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextAlign align = TextAlign.start,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: align,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        counterText: "", // Max length sayacını gizle
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24, width: 2)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildLabeledInput({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Sadece sayı
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableCard(
      String label, String emoji, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 140,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white10,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitToggleOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}