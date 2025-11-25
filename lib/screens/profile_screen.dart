import 'package:flutter/material.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.background,
                    ],
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, size: 50, color: Colors.black),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Kullanıcı",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "İstatistikler",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Günlük Seri",
                          "5 Gün",
                          Icons.local_fire_department,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          "Toplam Kilo",
                          "-2.1 kg",
                          Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Ayarlar",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(Icons.person_outline, "Profil Bilgileri"),
                  _buildSettingItem(
                    Icons.notifications_outlined,
                    "Bildirimler",
                  ),
                  _buildSettingItem(Icons.lock_outline, "Gizlilik"),
                  _buildSettingItem(Icons.help_outline, "Yardım & Destek"),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Çıkış Yap",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {},
      ),
    );
  }
}
