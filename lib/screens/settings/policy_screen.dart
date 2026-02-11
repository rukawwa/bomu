import 'package:flutter/material.dart';
import '../../theme.dart';

enum PolicyType { privacy, terms }

class PolicyScreen extends StatelessWidget {
  final String title;
  final PolicyType type;

  const PolicyScreen({super.key, required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == PolicyType.privacy ? _privacyText : _termsText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Placeholder texts - Replace with real policies
  static const String _privacyText = """
**Gizlilik Politikası**

Son Güncelleme: 12 Şubat 2026

BoMu AI uygulamasını kullandığınız için teşekkür ederiz. Gizliliğiniz bizim için önemlidir. Bu Gizlilik Politikası, uygulamamızı kullandığınızda verilerinizi nasıl topladığımızı, kullandığımızı ve koruduğumuzu açıklar.

**1. Toplanan Veriler**
- Hesap Bilgileri: Ad, e-posta, profil fotoğrafı.
- Sağlık Verileri: Kilo, boy, kalori hedefleri, kaydedilen yemekler.
- Kullanım Verileri: Uygulama içi etkileşimler, cihaz bilgileri.

**2. Verilerin Kullanımı**
Verilerinizi size kişiselleştirilmiş bir deneyim sunmak, yemek analizleri yapmak ve uygulamayı geliştirmek için kullanırız.

**3. Veri Güvenliği**
Verileriniz güvenli sunucularda saklanır ve yetkisiz erişime karşı korunur.

**4. İletişim**
Gizlilikle ilgili sorularınız için support@bomuai.com adresine yazabilirsiniz.
  """;

  static const String _termsText = """
**Kullanım Koşulları**

Son Güncelleme: 12 Şubat 2026

Lütfen BoMu AI uygulamasını kullanmadan önce bu koşulları dikkatlice okuyun.

**1. Kabul**
Uygulamayı indirerek veya kullanarak, bu koşulları kabul etmiş olursunuz.

**2. Kullanım Hakkı**
Uygulamayı kişisel ve ticari olmayan amaçlarla kullanma hakkına sahipsiniz.

**3. Abonelikler**
Premium özellikler abonelik gerektirir. Ödemeler Google Play Store veya Apple App Store hesabınız üzerinden tahsil edilir.

**4. Sorumluluk Reddi**
BoMu AI tıbbi bir uygulama değildir. Sağlık kararları almadan önce bir uzmana danışmalısınız.

**5. Değişiklikler**
Bu koşulları zaman zaman güncelleme hakkımız saklıdır.
  """;
}
