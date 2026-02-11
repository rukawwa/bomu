import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../theme.dart';
import '../../services/gemini_service.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;
  final String? context;

  const AnalysisScreen({super.key, required this.imagePath, this.context});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isAnalyzing = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _detectedFoods = [];
  Map<int, Uint8List> _croppedImages = {};
  img.Image? _decodedImage;

  // Selection state: which foods are checked for adding
  Set<int> _selectedFoods = {};
  // Portion multipliers: 0.5 = half, 1.0 = full, 1.5 = 1.5x
  Map<int, double> _portionMultipliers = {};

  @override
  void initState() {
    super.initState();
    _loadAndAnalyzeImage();
  }

  Future<void> _loadAndAnalyzeImage() async {
    try {
      // Load and decode image first
      final bytes = await File(widget.imagePath).readAsBytes();
      _decodedImage = img.decodeImage(bytes);

      await _analyzeImage(bytes);
    } catch (e) {
      debugPrint('Load error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _analyzeImage(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      const prompt = '''
Analyze this food image and detect ALL food items visible.
For each food, estimate its position in the image using normalized bounding box coordinates (0-1).

Return ONLY a JSON array, no other text:
[
  {
    "name": "Türkçe yemek adı",
    "calories": int,
    "protein": int,
    "carbs": int,
    "fat": int,
    "type": "healthy" veya "unhealthy",
    "bbox": {
      "x": float (0-1, left edge),
      "y": float (0-1, top edge),
      "width": float (0-1),
      "height": float (0-1)
    }
  }
]

If no food is detected, return empty array: []
''';

      // Use GeminiService to call Cloud Function (secure)
      final foods = await GeminiService.analyzeFood(
        base64Image: base64Image,
        prompt: prompt,
        context: widget.context,
      );

      debugPrint('Detected foods: $foods');

      if (!mounted) return;
      setState(() {
        _detectedFoods = foods;
      });

      // Crop food regions
      await _cropFoodRegions();

      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        // Initialize all foods as selected with 1.0 portion
        _selectedFoods = Set.from(
          List.generate(_detectedFoods.length, (i) => i),
        );
        _portionMultipliers = {
          for (var i = 0; i < _detectedFoods.length; i++) i: 1.0,
        };
      });
    } catch (e) {
      debugPrint('Analysis error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _cropFoodRegions() async {
    if (_decodedImage == null) return;

    final decoded = _decodedImage!;
    final Map<int, Uint8List> cropped = {};

    for (int i = 0; i < _detectedFoods.length; i++) {
      try {
        final bbox = _detectedFoods[i]['bbox'];
        if (bbox == null) continue;

        // Parse bbox values safely
        final x = ((bbox['x'] ?? 0.0) as num).toDouble();
        final y = ((bbox['y'] ?? 0.0) as num).toDouble();
        final w = ((bbox['width'] ?? 0.3) as num).toDouble();
        final h = ((bbox['height'] ?? 0.3) as num).toDouble();

        // Convert normalized coords to pixels
        int px = (x * decoded.width).round().clamp(0, decoded.width - 1);
        int py = (y * decoded.height).round().clamp(0, decoded.height - 1);
        int pw = (w * decoded.width).round().clamp(10, decoded.width - px);
        int ph = (h * decoded.height).round().clamp(10, decoded.height - py);

        final croppedImg = img.copyCrop(
          decoded,
          x: px,
          y: py,
          width: pw,
          height: ph,
        );

        // Make it square for display
        final size = croppedImg.width < croppedImg.height
            ? croppedImg.width
            : croppedImg.height;
        final squareImg = img.copyResizeCropSquare(
          croppedImg,
          size: size > 200 ? 200 : size,
        );

        cropped[i] = Uint8List.fromList(img.encodeJpg(squareImg, quality: 85));
      } catch (e) {
        debugPrint('Crop error for item $i: $e');
      }
    }

    if (mounted) {
      setState(() {
        _croppedImages = cropped;
      });
    }
  }

  int get _totalCalories {
    int total = 0;
    for (int i = 0; i < _detectedFoods.length; i++) {
      if (!_selectedFoods.contains(i)) continue;
      final cal = ((_detectedFoods[i]['calories'] as num?)?.toInt() ?? 0);
      total += (cal * (_portionMultipliers[i] ?? 1.0)).round();
    }
    return total;
  }

  int get _totalProtein {
    int total = 0;
    for (int i = 0; i < _detectedFoods.length; i++) {
      if (!_selectedFoods.contains(i)) continue;
      final val = ((_detectedFoods[i]['protein'] as num?)?.toInt() ?? 0);
      total += (val * (_portionMultipliers[i] ?? 1.0)).round();
    }
    return total;
  }

  int get _totalCarbs {
    int total = 0;
    for (int i = 0; i < _detectedFoods.length; i++) {
      if (!_selectedFoods.contains(i)) continue;
      final val = ((_detectedFoods[i]['carbs'] as num?)?.toInt() ?? 0);
      total += (val * (_portionMultipliers[i] ?? 1.0)).round();
    }
    return total;
  }

  int get _totalFat {
    int total = 0;
    for (int i = 0; i < _detectedFoods.length; i++) {
      if (!_selectedFoods.contains(i)) continue;
      final val = ((_detectedFoods[i]['fat'] as num?)?.toInt() ?? 0);
      total += (val * (_portionMultipliers[i] ?? 1.0)).round();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isAnalyzing
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _buildResultsState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isAnalyzing ? "ANALİZ EDİLİYOR..." : "ANALİZ TAMAMLANDI",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Square image preview
        _buildSquareImagePreview(),

        const Spacer(),

        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 4,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Analiz yapılıyor...",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Besin değerleri hesaplanıyor",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),

        const Spacer(),
      ],
    );
  }

  Widget _buildSquareImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withValues(alpha: 0.8),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              "Analiz Başarısız",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Bilinmeyen hata",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isAnalyzing = true;
                  _errorMessage = null;
                });
                _loadAndAnalyzeImage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text("Tekrar Dene"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsState() {
    if (_detectedFoods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSquareImagePreview(),
              const SizedBox(height: 32),
              Icon(
                Icons.no_food,
                color: Colors.white.withValues(alpha: 0.5),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                "Yemek Tespit Edilemedi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Lütfen tabağı daha net çekin",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Tekrar Çek"),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small square preview
          Center(
            child: Container(
              width: 120,
              height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
              ),
            ),
          ),

          // Summary Card
          _buildSummaryCard(),

          const SizedBox(height: 16),

          // Foods List - No container wrapper, save space
          ...List.generate(
            _detectedFoods.length,
            (index) => _buildFoodItem(_detectedFoods[index], index),
          ),

          const SizedBox(height: 16),

          // Add Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addToLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Günlüğe Ekle (+$_totalCalories)",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _addToLog() {
    // Return detected foods with cropped image paths
    final resultsWithImages = _detectedFoods.asMap().entries.map((entry) {
      final food = Map<String, dynamic>.from(entry.value);
      if (_croppedImages.containsKey(entry.key)) {
        food['croppedImageBytes'] = _croppedImages[entry.key];
      }
      food['originalImagePath'] = widget.imagePath;
      return food;
    }).toList();

    Navigator.pop(context, resultsWithImages);
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                "$_totalCalories",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "kcal",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroItem("Protein", _totalProtein, Colors.blue),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _buildMacroItem("Karb", _totalCarbs, Colors.orange),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _buildMacroItem("Yağ", _totalFat, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          "${value}g",
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food, int index) {
    final hasCroppedImage = _croppedImages.containsKey(index);
    final isSelected = _selectedFoods.contains(index);
    final portion = _portionMultipliers[index] ?? 1.0;

    // Calculate adjusted values
    final calories = ((food['calories'] as num?)?.toInt() ?? 0) * portion;
    final protein = ((food['protein'] as num?)?.toInt() ?? 0) * portion;
    final carbs = ((food['carbs'] as num?)?.toInt() ?? 0) * portion;
    final fat = ((food['fat'] as num?)?.toInt() ?? 0) * portion;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isSelected ? 1.0 : 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            // Main row: checkbox + image + name + calories
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFoods.remove(index);
                        } else {
                          _selectedFoods.add(index);
                        }
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Cropped food image thumbnail
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      image: hasCroppedImage
                          ? DecorationImage(
                              image: MemoryImage(_croppedImages[index]!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasCroppedImage
                        ? const Icon(
                            Icons.restaurant,
                            color: Colors.white54,
                            size: 22,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Name and macros
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food['name'] ?? 'Bilinmeyen',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "P:${protein.round()}g  K:${carbs.round()}g  Y:${fat.round()}g",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Calories - prominent with kcal
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${calories.round()}",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "kcal",
                          style: TextStyle(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Portion slider (only if selected)
            if (isSelected)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text(
                      "Porsiyon",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: Colors.white.withValues(
                            alpha: 0.1,
                          ),
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        child: Slider(
                          value: portion,
                          min: 0.25,
                          max: 2.0,
                          divisions: 7,
                          onChanged: (value) {
                            setState(() {
                              _portionMultipliers[index] = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${(portion * 100).round()}%",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
