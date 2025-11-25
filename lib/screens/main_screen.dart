import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'food_library_screen.dart';
import 'profile_screen.dart';
import '../theme.dart';

class MainScreen extends StatefulWidget {
  final int initialDailyGoal;

  const MainScreen({super.key, required this.initialDailyGoal});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // SHARED STATE
  List<FoodEntry> entries = [];
  List<FoodEntry> savedFoods = [];

  void _addEntry(FoodEntry entry) {
    setState(() {
      entries.add(entry);
      // Sort by time (newest last or first, depending on preference. Let's keep newest last for now)
      entries.sort((a, b) => a.time.compareTo(b.time));
    });
  }

  void _removeEntry(FoodEntry entry) {
    setState(() {
      entries.removeWhere((e) => e.id == entry.id);
    });
  }

  void _saveFood(FoodEntry entry) {
    setState(() {
      savedFoods.add(entry);
    });
  }

  void _updateEntry(FoodEntry updatedEntry) {
    setState(() {
      final index = entries.indexWhere((e) => e.id == updatedEntry.id);
      if (index != -1) {
        entries[index] = updatedEntry;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Initial test data
    savedFoods = [
      FoodEntry(
        id: 'test_1',
        name: 'Hızlı Ekle (100 kcal)',
        calories: 100,
        protein: 5,
        carbs: 10,
        fat: 2,
        type: FoodType.healthy,
        time: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        initialDailyGoal: widget.initialDailyGoal,
        entries: entries,
        savedFoods: savedFoods,
        onAddEntry: _addEntry,
        onRemoveEntry: _removeEntry,
        onUpdateEntry: _updateEntry,
        onSaveFood: _saveFood,
      ),
      const FoodLibraryScreen(), // NEW
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.white38,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_rounded),
              activeIcon: Icon(Icons.bolt_rounded, size: 28),
              label: 'Tracker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded), // Changed Icon
              activeIcon: Icon(Icons.search_rounded, size: 28),
              label: 'Library', // Changed Label
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
