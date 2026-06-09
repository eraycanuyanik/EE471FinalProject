import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/duyar_service.dart';
import 'core/theme.dart';
import 'modules/duyar/duyar_screen.dart';
import 'modules/sesver/sesver_screen.dart';
import 'modules/yanindayim/yanindayim_screen.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Duyar uygulama açılır açılmaz arka planda dinlemeye başlar (hep açık).
    WidgetsBinding.instance.addPostFrameCallback((_) => DuyarService.instance.start());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: ErisimTheme.headerGradient),
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.accessibility_new, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  const Text('Erişim',
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
                const SizedBox(height: 12),
                Text('Engelliler ve yaşlılar için\nyapay zekâ destekli asistan',
                    style: TextStyle(
                        fontSize: 17, color: Colors.white.withValues(alpha: 0.85), height: 1.4)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ModuleCard(
                  icon: Icons.front_hand_rounded,
                  title: 'SesVer',
                  subtitle: 'İşaret dilini konuşmaya çevirir',
                  gradient: const [ErisimTheme.sesverA, ErisimTheme.sesverB],
                  onTap: () => _go(const SesVerScreen()),
                ),
                const _DuyarLiveCard(),
                _ModuleCard(
                  icon: Icons.elderly_rounded,
                  title: 'Yanındayım',
                  subtitle: 'Yaşlılar için sesli asistan & ilaç hatırlatma',
                  gradient: const [ErisimTheme.yaninA, ErisimTheme.yaninB],
                  onTap: () => _go(const YanindayimScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _go(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

/// Duyar kartı — CANLI durum + aç/kapa anahtarı. Dinleme arka planda sürer;
/// karta basmak detay ekranını açar ama dinleme için gerekli değildir.
class _DuyarLiveCard extends StatelessWidget {
  const _DuyarLiveCard();

  @override
  Widget build(BuildContext context) {
    final svc = DuyarService.instance;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        elevation: 6,
        shadowColor: ErisimTheme.duyarB.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const DuyarScreen())),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                  colors: [ErisimTheme.duyarA, ErisimTheme.duyarB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.hearing_rounded, size: 38, color: Colors.white),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duyar',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    // Canlı durum
                    ValueListenableBuilder<bool>(
                      valueListenable: svc.running,
                      builder: (_, running, _) => ValueListenableBuilder<DuyarResult?>(
                        valueListenable: svc.current,
                        builder: (_, cur, _) {
                          final text = !running
                              ? 'Kapalı'
                              : (cur != null && cur.critical
                                  ? 'Son: ${cur.displayName}'
                                  : '🟢 Dinliyor…');
                          return Text(text,
                              style: TextStyle(
                                  fontSize: 15, color: Colors.white.withValues(alpha: 0.95)));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Aç/kapa anahtarı
              ValueListenableBuilder<bool>(
                valueListenable: svc.running,
                builder: (_, running, _) => Switch(
                  value: running,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white54,
                  onChanged: (v) => v ? svc.start() : svc.stop(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

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
                  colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, size: 38, color: Colors.white),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.3)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}
