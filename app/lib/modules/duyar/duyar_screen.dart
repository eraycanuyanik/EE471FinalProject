import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/duyar_service.dart';

/// Duyar detay ekranı — DuyarService'in canlı GÖRÜNTÜLEYİCİSİ.
/// Dinleme bu ekran açık olmasa da arka planda sürer; burada sadece izlenir.
class DuyarScreen extends StatefulWidget {
  const DuyarScreen({super.key});

  @override
  State<DuyarScreen> createState() => _DuyarScreenState();
}

class _DuyarScreenState extends State<DuyarScreen> with SingleTickerProviderStateMixin {
  final _svc = DuyarService.instance;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _svc.running,
      builder: (_, running, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0E2A2A),
          body: SafeArea(
            child: Column(
              children: [
                _header(running),
                const SizedBox(height: 8),
                _hero(running),
                const SizedBox(height: 16),
                _levelMeter(),
                const SizedBox(height: 20),
                _currentCard(),
                const Spacer(),
                _historyStrip(),
                Text('Sunucu: ${_svc.api.baseUrl}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: FilledButton.icon(
                    onPressed: () => running ? _svc.stop() : _svc.start(),
                    icon: Icon(running ? Icons.pause : Icons.play_arrow),
                    label: Text(running ? 'Duraklat' : 'Dinlemeyi Başlat'),
                    style: FilledButton.styleFrom(
                      backgroundColor: running ? Colors.white24 : Colors.tealAccent.shade400,
                      foregroundColor: running ? Colors.white : const Color(0xFF06302E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(bool running) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          const Text('Duyar',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const Spacer(),
          ValueListenableBuilder<String>(
            valueListenable: _svc.status,
            builder: (_, status, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: running ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.white24,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(running ? Icons.fiber_manual_record : Icons.pause,
                    size: 12, color: running ? Colors.greenAccent : Colors.white70),
                const SizedBox(width: 6),
                Text(status,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      );

  Widget _hero(bool running) => SizedBox(
        height: 200,
        child: ValueListenableBuilder<double>(
          valueListenable: _svc.level,
          builder: (_, level, _) => AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Stack(alignment: Alignment.center, children: [
              for (int i = 0; i < 3; i++) _ring(((_pulse.value + i / 3) % 1.0), running),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: running ? Colors.tealAccent.shade400 : Colors.white24,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.tealAccent.withValues(alpha: 0.4 + 0.4 * level),
                        blurRadius: 30 + 40 * level,
                        spreadRadius: 4 * level)
                  ],
                ),
                child: Icon(running ? Icons.mic : Icons.mic_off,
                    size: 56, color: const Color(0xFF06302E)),
              ),
            ]),
          ),
        ),
      );

  Widget _ring(double t, bool running) {
    final size = 110 + t * 110;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.tealAccent.withValues(alpha: (1 - t) * 0.5 * (running ? 1 : 0)),
            width: 2.5),
      ),
    );
  }

  Widget _levelMeter() => ValueListenableBuilder<double>(
        valueListenable: _svc.level,
        builder: (_, level, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(20, (i) {
              final active = level * 20 > i;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: active ? 8 + (i * 1.4) : 6,
                  decoration: BoxDecoration(
                      color: active
                          ? Color.lerp(Colors.tealAccent, Colors.amber, i / 20)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(4)),
                ),
              );
            }),
          ),
        ),
      );

  Widget _currentCard() => ValueListenableBuilder<DuyarResult?>(
        valueListenable: _svc.current,
        builder: (_, r, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: (r?.critical ?? false) ? Colors.amberAccent : Colors.white24, width: 2),
          ),
          child: Column(children: [
            Text(r == null ? 'Ses dinleniyor…' : r.displayName,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
                textAlign: TextAlign.center),
            if (r != null) ...[
              const SizedBox(height: 8),
              Text('Güven: %${(r.confidence * 100).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ]),
        ),
      );

  Widget _historyStrip() => ValueListenableBuilder<List<DuyarDetection>>(
        valueListenable: _svc.history,
        builder: (_, history, _) {
          if (history.isEmpty) return const SizedBox.shrink();
          return Container(
            height: 64,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: history.length,
              itemBuilder: (_, i) {
                final d = history[i];
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(d.label,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text(d.timeLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ]),
                );
              },
            ),
          );
        },
      );
}
