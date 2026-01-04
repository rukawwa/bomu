import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;
  // We could pass detected objects here too for initial bounding boxes
  // final List<DetectedObject> initialDetections;

  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isAnalyzing = true;
  List<Map<String, dynamic>> _detectedFoods = [];

  @override
  void initState() {
    super.initState();
    _simulateAnalysis();
  }

  Future<void> _simulateAnalysis() async {
    // Simulate API call / Deep Learning processing
    await Future.delayed(const Duration(seconds: 3));

    // Mock results based on user request (Separate items)
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _detectedFoods = [
          {
            "name": "Izgara Tavuk",
            "calories": 280,
            "protein": 32,
            "carbs": 0,
            "fat": 12,
            "confidence": 0.95,
          },
          {
            "name": "Pilav",
            "calories": 200,
            "protein": 4,
            "carbs": 40,
            "fat": 2,
            "confidence": 0.88,
          },
          {
            "name": "Mevsim Salata",
            "calories": 45,
            "protein": 1,
            "carbs": 8,
            "fat": 0,
            "confidence": 0.92,
          },
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image
          Image.file(File(widget.imagePath), fit: BoxFit.cover),

          // 2. Dark Overlay
          Container(color: Colors.black87),

          // 3. Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isAnalyzing ? "ANALYZING..." : "ANALYSIS COMPLETE",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Results Panel
                if (!_isAnalyzing)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tespit Edilenler",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._detectedFoods.map((food) => _buildFoodItem(food)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Add to actual history list
                              Navigator.pop(context);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Besinler günlüğüne eklendi!"),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Günlüğe Ekle",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "AI Besin Değerlerini Hesaplarken Bekle...",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!_isAnalyzing) const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(Icons.check, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food["name"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "${food["calories"]} kcal • ${food["protein"]}g Protein",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "%${(food["confidence"] * 100).toInt()}",
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
