import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'modules/duyar/duyar_screen.dart';
import 'modules/sesver/sesver_screen.dart';
import 'modules/yanindayim/yanindayim_screen.dart';

// Not: Bildirim izni (Notifications.init) uygulama açılışında değil, ilk ilaç
// hatırlatması kurulurken istenir — daha iyi kullanıcı deneyimi için.
void main() => runApp(const ErisimApp());

class ErisimApp extends StatelessWidget {
  const ErisimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erişim',
      debugShowCheckedModeBanner: false,
      theme: ErisimTheme.light(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Degrade header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: ErisimTheme.headerGradient),
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.accessibility_new, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    const Text('Erişim',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Engelliler ve yaşlılar için\nyapay zekâ destekli asistan',
                  style: TextStyle(fontSize: 17, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
                ),
              ],
            ),
          ),
          // Modül kartları
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ModuleCard(
                  icon: Icons.front_hand_rounded,
                  title: 'SesVer',
                  subtitle: 'İşaret dilini konuşmaya çevirir',
                  gradient: const [ErisimTheme.sesverA, ErisimTheme.sesverB],
                  onTap: () => _go(context, const SesVerScreen()),
                ),
                _ModuleCard(
                  icon: Icons.hearing_rounded,
                  title: 'Duyar',
                  subtitle: 'Kritik sesleri tanır, titreşimle uyarır',
                  gradient: const [ErisimTheme.duyarA, ErisimTheme.duyarB],
                  badge: 'CANLI',
                  onTap: () => _go(context, const DuyarScreen()),
                ),
                _ModuleCard(
                  icon: Icons.elderly_rounded,
                  title: 'Yanındayım',
                  subtitle: 'Yaşlılar için sesli asistan & ilaç hatırlatma',
                  gradient: const [ErisimTheme.yaninA, ErisimTheme.yaninB],
                  onTap: () => _go(context, const YanindayimScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        elevation: 6,
        shadowColor: gradient.last.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 38, color: Colors.white),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                          if (badge != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(badge!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: gradient.last,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 15, color: Colors.white.withValues(alpha: 0.9), height: 1.3)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
