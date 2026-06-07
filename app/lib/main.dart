import 'package:flutter/material.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erişim'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Erişilebilirlik Asistanı',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _ModuleTile(
              icon: Icons.front_hand,
              title: 'SesVer',
              subtitle: 'İşaret dilini konuşmaya çevir',
              color: Colors.indigo,
              onTap: () => _go(context, const SesVerScreen()),
            ),
            _ModuleTile(
              icon: Icons.hearing,
              title: 'Duyar',
              subtitle: 'Kritik sesleri tanı, titreşimle uyar',
              color: Colors.teal,
              onTap: () => _go(context, const DuyarScreen()),
            ),
            _ModuleTile(
              icon: Icons.elderly,
              title: 'Yanındayım',
              subtitle: 'Yaşlılar için sesli asistan',
              color: Colors.deepOrange,
              onTap: () => _go(context, const YanindayimScreen()),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color,
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
