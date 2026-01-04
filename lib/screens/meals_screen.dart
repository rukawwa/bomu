import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart'; // For FoodEntry class

class MealsScreen extends StatelessWidget {
  final List<FoodEntry> entries;
  final Function(FoodEntry) onRemoveEntry;

  const MealsScreen({
    super.key,
    required this.entries,
    required this.onRemoveEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Yemek Geçmişi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.no_meals_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz yemek eklenmedi",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                // Show newest first
                final entry = entries[entries.length - 1 - index];
                return _buildTimelineItem(
                  context,
                  entry,
                  index == entries.length - 1,
                );
              },
            ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    FoodEntry entry,
    bool isLast,
  ) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemoveEntry(entry),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Line & Dot
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.white10)),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Image or Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          image: entry.imageFile != null
                              ? DecorationImage(
                                  image: FileImage(entry.imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: entry.imageFile == null
                            ? Icon(
                                Icons.restaurant,
                                color: entry.type == FoodType.healthy
                                    ? AppColors.primary
                                    : AppColors.secondary,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${entry.calories} kcal • ${_formatTime(entry.time)}",
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(double decimalTime) {
    final hour = decimalTime.floor();
    final minute = ((decimalTime - hour) * 60).floor();
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
