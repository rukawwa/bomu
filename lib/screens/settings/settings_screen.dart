import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import '../onboarding/subscription_screen.dart';
import 'policy_screen.dart';

import '../../models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdate;

  const SettingsScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdate,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Ayarlar",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader("Hesap"),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: "Profili Düzenle",
            onTap: () {
              // Navigate to Edit Profile
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: "Şifre Değiştir",
            onTap: () {},
          ),

          const SizedBox(height: 32),
          _buildSectionHeader("Üyelik"),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 20),
              ),
              title: const Text(
                "Premium'a Yükselt",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                "Sınırsız özelliklerin kilidini aç",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionScreen(
                      userProfile: widget.userProfile,
                      isFromOnboarding: false,
                      onPlanSelected: (isPremium) {
                        setState(() {
                          widget.userProfile.isPremium = isPremium;
                        });
                        widget.onProfileUpdate(widget.userProfile);
                      },
                    ),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader("Uygulama"),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: "Bildirimler",
            trailing: Switch(
              value: true,
              onChanged: (val) {},
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: "Dil / Language",
            subtitle: "Türkçe",
            onTap: () {},
          ),

          const SizedBox(height: 32),
          _buildSectionHeader("Hakkında"),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: "Kullanım Koşulları",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PolicyScreen(
                    title: "Kullanım Koşulları",
                    type: PolicyType.terms,
                  ),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: "Gizlilik Politikası",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PolicyScreen(
                    title: "Gizlilik Politikası",
                    type: PolicyType.privacy,
                  ),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.mail_outline,
            title: "Bize Ulaşın",
            onTap: () {},
          ),

          const SizedBox(height: 40),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: "Çıkış Yap",
            textColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            onTap: () {
              // Sign out logic
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              "v1.0.0",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.white).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              )
            : null,
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 14,
            ),
      ),
    );
  }
}
