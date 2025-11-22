import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../theme.dart';
import 'profile_screen.dart'; // Profil sayfasına gitmek için

// --- MODELLER ---
enum FoodType { healthy, unhealthy }

class FoodEntry {
  final String id;
  String name; // Editable (Düzenlenebilir)
  int calories; // Editable (Düzenlenebilir)
  final FoodType type;
  final double time; 
  final File? imageFile;

  FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.type,
    required this.time,
    this.imageFile,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // --- AYARLAR ---
  final String apiKey = ""; // BURAYA API KEY GELECEK
  final int dailyGoal = 2200;
  
  // --- STATE ---
  List<FoodEntry> entries = [];
  // Simule edilmiş "Yemek Defteri"
  List<FoodEntry> savedFoods = []; 
  
  bool isScanning = false;
  bool isGettingAdvice = false;
  DateTime currentTime = DateTime.now();
  late Timer _timer;
  
  // Animasyon Kontrolcüleri
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _pulseController;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Mock Data (Başlangıç verisi)
    entries = [
      FoodEntry(id: '1', name: 'Yulaf', calories: 300, type: FoodType.healthy, time: 8.5),
      FoodEntry(id: '2', name: 'Kahve', calories: 50, type: FoodType.healthy, time: 10.0),
    ];

    // İlerleme Animasyonu
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _updateProgressAnimation(0);

    // Nabız Animasyonu
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    // Saat Güncelleyici
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() => currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateProgressAnimation(int oldTotalCalories) {
    double oldProgress = oldTotalCalories / dailyGoal;
    double newProgress = totalCalories / dailyGoal;
    
    // Görsel sınırlandırma (1.0 = %100)
    if (oldProgress > 1.0) oldProgress = 1.0;
    if (newProgress > 1.0) newProgress = 1.0;
    
    _progressAnimation = Tween<double>(begin: oldProgress, end: newProgress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward(from: 0);
  }

  int get totalCalories => entries.fold(0, (sum, item) => sum + item.calories);
  int get remaining => dailyGoal - totalCalories;

  // --- ACTIONS (EYLEMLER) ---

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          savedFoods: savedFoods,
          onRemoveFood: (food) {
            setState(() {
              savedFoods.removeWhere((element) => element.id == food.id);
            });
          },
        ),
      ),
    );
  }

  // + Butonuna Basınca Çıkan Menü
  void _showAddMealOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nasıl eklemek istersin?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.camera_alt,
                    title: "Kamera",
                    subtitle: "AI Analizi",
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.menu_book_rounded,
                    title: "Defter",
                    subtitle: "Kayıtlılar",
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _openFoodBookSelection();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Yemek Defterinden Seçim Ekranı
  void _openFoodBookSelection() {
    if (savedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yemek defterin boş. Önce yemek kaydetmelisin.")));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Yemek Defterinden Seç", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: savedFoods.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final food = savedFoods[index];
                  return ListTile(
                    onTap: () {
                      // Seçilen yemeği bugüne ekle
                      final now = DateTime.now();
                      final decimalTime = now.hour + now.minute / 60.0;
                      int oldTotal = totalCalories;
                      
                      setState(() {
                        entries.add(FoodEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: food.name,
                          calories: food.calories,
                          type: food.type,
                          time: decimalTime,
                          imageFile: null, 
                        ));
                      });
                      _updateProgressAnimation(oldTotal);
                      Navigator.pop(context);
                    },
                    tileColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(Icons.restaurant, color: food.type == FoodType.healthy ? AppColors.primary : AppColors.secondary),
                    title: Text(food.name, style: const TextStyle(color: Colors.white)),
                    trailing: Text("${food.calories} kcal", style: const TextStyle(color: AppColors.textMuted)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kalori/İsim Düzenleme Penceresi
  void _editEntry(FoodEntry entry) {
    final nameCtrl = TextEditingController(text: entry.name);
    final calCtrl = TextEditingController(text: entry.calories.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Düzenle", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Yemek Adı", labelStyle: TextStyle(color: AppColors.textMuted)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Kalori", labelStyle: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("İptal", style: TextStyle(color: AppColors.textMuted))
          ),
          TextButton(
            onPressed: () {
              setState(() {
                entry.name = nameCtrl.text;
                entry.calories = int.tryParse(calCtrl.text) ?? entry.calories;
              });
              Navigator.pop(context);
            }, 
            child: const Text("Kaydet", style: TextStyle(color: AppColors.primary))
          ),
        ],
      ),
    );
  }

  // Yemeği Deftere Kaydetme Fonksiyonu
  void _saveToFoodBook(FoodEntry entry) {
    setState(() {
      savedFoods.add(FoodEntry(
        id: "saved_${DateTime.now().millisecondsSinceEpoch}",
        name: entry.name,
        calories: entry.calories,
        type: entry.type,
        time: 0, 
        imageFile: null,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yemek deftere kaydedildi!")));
  }

  // --- API LOGIC (GEMINI) ---
  Future<void> _analyzeImage(File imageFile) async {
    if (apiKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen API Key giriniz.")));
        return;
    }
    setState(() => isScanning = true);
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      const prompt = """
        Bu yemek fotoğrafını analiz et. Aşağıdaki JSON formatında yanıt ver. Başka hiçbir metin ekleme.
        Eğer fotoğrafta yemek yoksa "name" alanına "Bilinmiyor" yaz.
        Format:
        {
          "name": "Yemeğin Adı (Türkçe)",
          "calories": (Tahmini Kalori - sadece sayı),
          "type": "healthy" veya "unhealthy" (genel sağlık algısına göre seç)
        }
      """;

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": prompt},
                {"inlineData": {"mimeType": "image/jpeg", "data": base64Image}}
              ]
            }
          ],
          "generationConfig": {"responseMimeType": "application/json"}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resultText = data['candidates']?[0]['content']?['parts']?[0]['text'];
        
        if (resultText != null) {
           final analysis = jsonDecode(resultText);
           final now = DateTime.now();
           final decimalTime = now.hour + now.minute / 60.0;
           int oldTotal = totalCalories;

           setState(() {
             entries.add(FoodEntry(
               id: DateTime.now().millisecondsSinceEpoch.toString(),
               name: analysis['name'],
               calories: analysis['calories'] ?? 0,
               type: analysis['type'] == 'healthy' ? FoodType.healthy : FoodType.unhealthy,
               time: decimalTime,
               imageFile: imageFile,
             ));
           });
           _updateProgressAnimation(oldTotal);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      setState(() => isScanning = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _analyzeImage(File(photo.path));
    }
  }

  Future<void> _getAdvice() async {
    if (apiKey.isEmpty) return;
    setState(() => isGettingAdvice = true);
    try {
      final eatenFoods = entries.map((e) => "${e.name} (${e.calories} kcal)").join(', ');
      final prompt = """
        Sen Hakone AI adında bilge bir yapay zeka koçusun.
        Durum: Hedef $dailyGoal, Yenilen $totalCalories, Kalan $remaining.
        Yenilenler: $eatenFoods. Saat: ${DateFormat('HH:mm').format(currentTime)}.
        Kullanıcıya kısa, motive edici, tek cümlelik bir tavsiye ver.
      """;

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"contents": [{"parts": [{"text": prompt}]}]}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final adviceText = data['candidates']?[0]['content']?['parts']?[0]['text'];
        if (adviceText != null && mounted) _showAdviceDialog(adviceText);
      }
    } catch (e) {
      // Silent fail
    } finally {
      setState(() => isGettingAdvice = false);
    }
  }

  // --- UI BİLEŞENLERİ ---

  void _showAdviceDialog(String advice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        icon: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 40),
        title: const Text('AI Koç', style: TextStyle(color: AppColors.primary, fontSize: 16)),
        content: Text(advice, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool limitExceeded = totalCalories > dailyGoal;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // --- HEADER (Üst Kısım) ---
              Container(
                padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 20),
                color: AppColors.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BUGÜNÜN ÖZETİ', style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(DateFormat('d MMMM, EEEE', 'tr_TR').format(currentTime), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      ],
                    ),
                    Row(
                      children: [
                        // Profil Butonu
                        GestureDetector(
                          onTap: _goToProfile,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=User&background=18181B&color=fff"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // AI Butonu
                        GestureDetector(
                          onTap: isGettingAdvice ? null : _getAdvice,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: isGettingAdvice 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                              : const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- TRACKER (Halkasal Grafik) ---
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Nabız Animasyonu
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 260 + (_pulseController.value * 20),
                                height: 260 + (_pulseController.value * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (limitExceeded ? AppColors.secondary : AppColors.primary)
                                      .withOpacity(0.05 - (_pulseController.value * 0.05)),
                                ),
                              );
                            },
                          ),
                          // Halkasal Grafik
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: CalorieRingPainter(
                                    percentage: _progressAnimation.value,
                                    color: limitExceeded ? AppColors.secondary : AppColors.primary,
                                    backgroundColor: AppColors.surface,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_fire_department_rounded, color: AppColors.textMuted, size: 24),
                                        const SizedBox(height: 8),
                                        Text(
                                          limitExceeded ? "+${totalCalories - dailyGoal}" : "$remaining",
                                          style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w900,
                                            color: limitExceeded ? AppColors.secondary : AppColors.textMain,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          limitExceeded ? "KCAL FAZLA" : "KCAL KALDI",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: limitExceeded ? AppColors.secondary.withOpacity(0.8) : AppColors.textMuted,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- FOOD LIST (Yemek Listesi) ---
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      Container(margin: const EdgeInsets.only(top: 16, bottom: 16), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("SON YENİLENLER", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            Text("${entries.length} ÖĞÜN", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[entries.length - 1 - index];
                            return _buildFoodListItem(entry);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- FAB (Yemek Ekleme Butonu) ---
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: isScanning
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.primary.withOpacity(0.5))),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          SizedBox(width: 12),
                          Text("Hesaplanıyor...", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ]),
                    )
                  : GestureDetector(
                      onTap: _showAddMealOptions, // Menüyü açar
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF34D399)]),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.black, size: 32),
                            SizedBox(width: 8),
                            Text("Öğün Ekle", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodListItem(FoodEntry entry) {
    final isHealthy = entry.type == FoodType.healthy;
    final color = isHealthy ? AppColors.primary : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Yemek Görseli
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              image: entry.imageFile != null ? DecorationImage(image: FileImage(entry.imageFile!), fit: BoxFit.cover) : null,
            ),
            child: entry.imageFile == null ? Icon(Icons.restaurant_menu, color: color) : null,
          ),
          const SizedBox(width: 16),
          // Yemek Bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("${entry.calories} kcal", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                    const SizedBox(width: 8),
                    Text(_formatTime(entry.time), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    // Düzenle Butonu
                    GestureDetector(
                      onTap: () => _editEntry(entry),
                      child: const Icon(Icons.edit, size: 14, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Kaydet Butonu
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.textMuted),
            onPressed: () => _saveToFoodBook(entry),
          )
        ],
      ),
    );
  }

  String _formatTime(double decimalTime) {
    final hour = decimalTime.floor();
    final minute = ((decimalTime - hour) * 60).floor();
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

// --- CUSTOM PAINTER (Grafik Çizimi) ---
class CalorieRingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  CalorieRingPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 25.0;

    // Arka Plan Halkası
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // İlerleme Halkası
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    // Gradyan
    progressPaint.shader = SweepGradient(
      startAngle: -math.pi / 2, 
      endAngle: 3 * math.pi / 2,
      colors: [color.withOpacity(0.5), color],
      stops: [0.0, percentage],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    final sweepAngle = 2 * math.pi * percentage;
    
    // Gölge (Glow)
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    if (percentage > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, shadowPaint);
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
    }

    // Uç Nokta Parlaklığı
    if (percentage > 0) {
      final endAngle = -math.pi / 2 + sweepAngle;
      final capX = center.dx + radius * math.cos(endAngle);
      final capY = center.dy + radius * math.sin(endAngle);
      canvas.drawCircle(Offset(capX, capY), strokeWidth / 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CalorieRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}