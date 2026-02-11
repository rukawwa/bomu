import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/custom_food.dart';
import '../../theme.dart';

class AddCustomFoodScreen extends StatefulWidget {
  final CustomFood? existingFood;

  const AddCustomFoodScreen({super.key, this.existingFood});

  bool get isEditing => existingFood != null;

  @override
  State<AddCustomFoodScreen> createState() => _AddCustomFoodScreenState();
}

class _AddCustomFoodScreenState extends State<AddCustomFoodScreen> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _ingredientsController = TextEditingController();

  File? _imageFile;
  bool _isPublic = false;
  List<TextEditingController> _stepControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    final food = widget.existingFood;
    if (food != null) {
      _nameController.text = food.name;
      _caloriesController.text = food.calories > 0
          ? food.calories.toString()
          : '';
      _proteinController.text = food.protein > 0 ? food.protein.toString() : '';
      _carbsController.text = food.carbs > 0 ? food.carbs.toString() : '';
      _fatController.text = food.fat > 0 ? food.fat.toString() : '';
      _ingredientsController.text = food.ingredients.join('\n');
      if (food.imagePath != null) {
        _imageFile = File(food.imagePath!);
      }
      if (food.instructions.isNotEmpty) {
        _stepControllers = food.instructions
            .map((s) => TextEditingController(text: s))
            .toList();
      }
      _isPublic = food.isPublic;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _ingredientsController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
      _showError("Galeri açılamadı. Lütfen uygulamayı yeniden başlatın.");
    }
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
    HapticFeedback.lightImpact();
  }

  void _removeStep(int index) {
    if (_stepControllers.length <= 1) return;
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError("Yemek adı gerekli");
      return;
    }

    final calories = int.tryParse(_caloriesController.text) ?? 0;
    if (calories <= 0) {
      _showError("Kalori değeri girin");
      return;
    }

    final instructions = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final ingredients = _ingredientsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final food = CustomFood(
      id: widget.existingFood?.id ?? const Uuid().v4(),
      name: name,
      imagePath: _imageFile?.path,
      calories: calories,
      protein: int.tryParse(_proteinController.text) ?? 0,
      carbs: int.tryParse(_carbsController.text) ?? 0,
      fat: int.tryParse(_fatController.text) ?? 0,
      isPublic: _isPublic,
      likes: widget.existingFood?.likes ?? 0,
      ingredients: ingredients,
      instructions: instructions,
    );

    Navigator.pop(context, food);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? "Yemeği Düzenle" : "Yeni Yemek",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _save,
              child: const Text(
                "Kaydet",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Photo Picker ---
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A292E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            color: AppColors.primary.withValues(alpha: 0.6),
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Fotoğraf Ekle",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 28),

            // --- Name ---
            _buildSectionLabel("İsim"),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: "Yemek adı",
              icon: Icons.restaurant_rounded,
            ),

            const SizedBox(height: 16),

            // --- Public Toggle ---
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A292E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: SwitchListTile(
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                title: const Text(
                  "Herkese Açık Paylaş",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  "Yemek kütüphanesinde görünsün",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
                secondary: Icon(
                  _isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                  color: _isPublic ? AppColors.primary : Colors.white38,
                ),
                activeThumbColor: AppColors.primary,
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Macros ---
            _buildSectionLabel("Besin Değerleri"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _caloriesController,
                    label: "Kalori",
                    suffix: "kcal",
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    controller: _proteinController,
                    label: "Protein",
                    suffix: "g",
                    color: Colors.purpleAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _carbsController,
                    label: "Karb",
                    suffix: "g",
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    controller: _fatController,
                    label: "Yağ",
                    suffix: "g",
                    color: Colors.amberAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // --- Ingredients ---
            _buildSectionLabel("Malzemeler"),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A292E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TextField(
                controller: _ingredientsController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      "Her satıra bir malzeme yazın...\nÖrn: 200g tavuk göğsü\nZeytinyağı\nTuz, karabiber",
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // --- Instructions ---
            _buildSectionLabel("Yapılışı"),
            const SizedBox(height: 12),

            ...List.generate(_stepControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Number
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(top: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A292E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: TextField(
                          controller: _stepControllers[index],
                          maxLines: 3,
                          minLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "Aşama ${index + 1}...",
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    // Remove button
                    if (_stepControllers.length > 1)
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () => _removeStep(index),
                      ),
                  ],
                ),
              );
            }),

            // Add Step Button
            Center(
              child: TextButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text("Aşama Ekle"),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A292E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A292E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: "0",
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 20,
              ),
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
