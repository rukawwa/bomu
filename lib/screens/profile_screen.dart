import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart'; // FoodEntry modelini kullanmak için

class ProfileScreen extends StatefulWidget {
  // Gerçek uygulamada bu veriler bir State Management veya DB'den gelir.
  // Şimdilik mock data olarak alıyoruz veya HomeScreen'den paslanabilir.
  final List<FoodEntry> savedFoods;
  final Function(FoodEntry) onRemoveFood;

  const ProfileScreen({
    super.key,
    required this.savedFoods,
    required this.onRemoveFood,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profil Form Kontrolcüleri
  final TextEditingController _nameController = TextEditingController(text: "Misafir Kullanıcı");
  final TextEditingController _weightController = TextEditingController(text: "70");
  final TextEditingController _heightController = TextEditingController(text: "175");
  final TextEditingController _goalController = TextEditingController(text: "2200");

  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Profil ve Ayarlar", style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: AppColors.primary),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                // Kaydetme mantığı buraya eklenebilir
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PROFİL KARTI ---
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      image: const DecorationImage(
                        image: NetworkImage("https://ui-avatars.com/api/?name=User&background=10B981&color=fff"), // Placeholder
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isEditing 
                    ? SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none, hintText: "İsim Giriniz"),
                        ),
                      )
                    : Text(_nameController.text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // --- VÜCUT ÖLÇÜLERİ & HEDEF ---
            const Text("VÜCUT & HEDEF", style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem("Kilo", _weightController, "kg"),
                  _buildDivider(),
                  _buildStatItem("Boy", _heightController, "cm"),
                  _buildDivider(),
                  _buildStatItem("Hedef", _goalController, "kcal"),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- YEMEK DEFTERİ (FOOD BOOK) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("YEMEK DEFTERİ", style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text("${widget.savedFoods.length} Kayıt", style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.savedFoods.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 48, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text("Henüz yemek kaydetmedin.", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Text("Ana sayfada yemeklerin yanındaki 'Kaydet' ikonuna basarak buraya ekleyebilirsin.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.savedFoods.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final food = widget.savedFoods[index];
                  return Dismissible(
                    key: Key(food.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => widget.onRemoveFood(food),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: (food.type == FoodType.healthy ? AppColors.primary : AppColors.secondary).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.restaurant, color: food.type == FoodType.healthy ? AppColors.primary : AppColors.secondary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(food.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text("${food.calories} kcal", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white24),
                            onPressed: () => widget.onRemoveFood(food),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              
             const SizedBox(height: 50), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, TextEditingController controller, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: 50,
              child: TextField(
                controller: controller,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Text(unit, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.white10);
  }
}