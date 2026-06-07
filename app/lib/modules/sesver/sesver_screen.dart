import 'package:flutter/material.dart';

/// SesVer — işaret dili → konuşma. İSKELET ekranı.
///
/// Yol haritası:
///  1) camera + google_mlkit_pose/hands ile el+yüz landmark çıkar
///  2) landmark dizisini ml_service /sesver/predict'e gönder
///  3) dönen cümleyi TTS ile seslendir (Azure)
///  4) ters mod: STT → işaret animasyonu
class SesVerScreen extends StatelessWidget {
  const SesVerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SesVer')),
      body: const _ComingSoon(
        icon: Icons.front_hand,
        title: 'İşaret Dili → Konuşma',
        bullets: [
          'Kamera ile el + yüz landmark takibi (MediaPipe)',
          'PyTorch işaret sınıflandırıcı (ml_service)',
          'Azure TTS ile sesli çıktı',
          'Ters mod: konuşma → işaret animasyonu',
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.icon, required this.title, required this.bullets});
  final IconData icon;
  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(icon, size: 96, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Chip(label: Text('Yakında — iskelet aşaması')),
          const SizedBox(height: 24),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontSize: 20)),
                  Expanded(child: Text(b, style: Theme.of(context).textTheme.bodyLarge)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
