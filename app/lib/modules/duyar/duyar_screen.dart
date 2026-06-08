import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';

/// Duyar — SÜREKLİ AÇIK ortam ses asistanı.
///
/// Ekran açıldığında otomatik dinlemeye başlar; 1 sn'lik pencereler halinde
/// ML servisine gönderir, kritik bir ses tanınırsa türüne özel titreşim +
/// görsel uyarı verir. Canlı ses seviyesi ölçer ve son algılamalar listesi gösterir.
class DuyarScreen extends StatefulWidget {
  const DuyarScreen({super.key});

  @override
  State<DuyarScreen> createState() => _DuyarScreenState();
}

class _DuyarScreenState extends State<DuyarScreen> with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  final _api = ApiClient();

  late final AnimationController _pulse;
  Timer? _loop;
  Timer? _ampTimer;

  bool _listening = false;
  String _status = 'Başlatılıyor…';
  double _level = 0; // 0..1 anlık ses seviyesi
  DuyarResult? _current;
  bool _flash = false;
  final List<_Detection> _history = [];

  // Aynı kritik sesi kısa sürede tekrar titretmemek için debounce
  String? _lastAlertLabel;
  DateTime _lastAlertTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _cooldown = Duration(seconds: 3);

  // Kritik seslere özel titreşim desenleri
  static const _patterns = <String, List<int>>{
    'siren': [0, 500, 180, 500, 180, 500],
    'kapi_zili': [0, 250, 120, 250],
    'bebek_aglamasi': [0, 180, 90, 180, 90, 180, 90, 180],
    'alarm': [0, 600, 250, 600],
    'kapi_vurma': [0, 130, 90, 130, 90, 130],
    'isim_cagirma': [0, 400, 150, 200, 150, 200],
  };

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _start();
  }

  @override
  void dispose() {
    _loop?.cancel();
    _ampTimer?.cancel();
    _pulse.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      setState(() => _status = 'Mikrofon izni gerekli');
      return;
    }
    setState(() {
      _listening = true;
      _status = 'Dinleniyor';
    });
    _captureOnce();
    _loop = Timer.periodic(const Duration(milliseconds: 1100), (_) => _captureOnce());
    _ampTimer = Timer.periodic(const Duration(milliseconds: 140), (_) => _pollLevel());
  }

  Future<void> _stop() async {
    _loop?.cancel();
    _ampTimer?.cancel();
    await _recorder.stop();
    setState(() {
      _listening = false;
      _status = 'Duraklatıldı';
      _level = 0;
    });
  }

  Future<void> _pollLevel() async {
    if (!_listening) return;
    try {
      final amp = await _recorder.getAmplitude();
      // dBFS (~-60..0) -> 0..1
      final norm = ((amp.current + 50) / 50).clamp(0.0, 1.0);
      if (mounted) setState(() => _level = norm);
    } catch (_) {}
  }

  Future<void> _captureOnce() async {
    if (!_listening) return;
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/duyar_clip.wav';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        path: path,
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      final saved = await _recorder.stop();
      if (saved == null || !_listening) return;

      final bytes = await File(saved).readAsBytes();
      final result = await _api.duyarPredict(base64Encode(bytes));
      if (!mounted) return;
      setState(() => _current = result);

      if (result.critical) {
        final now = DateTime.now();
        final sameRecent = result.label == _lastAlertLabel &&
            now.difference(_lastAlertTime) < _cooldown;
        if (!sameRecent) {
          _lastAlertLabel = result.label;
          _lastAlertTime = now;
          _onCritical(result);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Bağlantı bekleniyor…');
    }
  }

  Future<void> _onCritical(DuyarResult r) async {
    setState(() {
      _flash = true;
      _history.insert(0, _Detection(r.displayName, DateTime.now()));
      if (_history.length > 8) _history.removeLast();
    });
    final pattern = _patterns[r.label] ?? [0, 400, 200, 400];
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: pattern);
    }
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _flash = false);
  }

  @override
  Widget build(BuildContext context) {
    final critical = _flash;
    return Scaffold(
      backgroundColor: critical ? ErisimTheme.danger : const Color(0xFF0E2A2A),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 8),
            _listeningHero(),
            const SizedBox(height: 16),
            _levelMeter(),
            const SizedBox(height: 20),
            _currentCard(),
            const Spacer(),
            _historyStrip(),
            _controlBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Text('Duyar',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _listening ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(_listening ? Icons.fiber_manual_record : Icons.pause,
                      size: 12, color: _listening ? Colors.greenAccent : Colors.white70),
                  const SizedBox(width: 6),
                  Text(_status,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _listeningHero() => SizedBox(
        height: 200,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // yayılan halkalar
                for (int i = 0; i < 3; i++)
                  _ring(((_pulse.value + i / 3) % 1.0)),
                // merkez mikrofon
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening ? Colors.tealAccent.shade400 : Colors.white24,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.tealAccent.withValues(alpha: 0.4 + 0.4 * _level),
                        blurRadius: 30 + 40 * _level,
                        spreadRadius: 4 * _level,
                      ),
                    ],
                  ),
                  child: Icon(_listening ? Icons.mic : Icons.mic_off,
                      size: 56, color: const Color(0xFF06302E)),
                ),
              ],
            );
          },
        ),
      );

  Widget _ring(double t) {
    final size = 110 + t * 110;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.tealAccent.withValues(alpha: (1 - t) * 0.5 * (_listening ? 1 : 0)),
          width: 2.5,
        ),
      ),
    );
  }

  Widget _levelMeter() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(20, (i) {
            final active = _level * 20 > i;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: active ? 8 + (i * 1.4) : 6,
                decoration: BoxDecoration(
                  color: active
                      ? Color.lerp(Colors.tealAccent, Colors.amber, i / 20)
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      );

  Widget _currentCard() {
    final r = _current;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (r?.critical ?? false) ? Colors.amberAccent : Colors.white24,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            r == null ? 'Ses dinleniyor…' : r.displayName,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (r != null) ...[
            const SizedBox(height: 8),
            Text('Güven: %${(r.confidence * 100).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, color: Colors.white70)),
          ],
        ],
      ),
    );
  }

  Widget _historyStrip() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 64,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final d = _history[i];
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(d.timeLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _controlBar() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: FilledButton.icon(
          onPressed: _listening ? _stop : _start,
          icon: Icon(_listening ? Icons.pause : Icons.play_arrow),
          label: Text(_listening ? 'Duraklat' : 'Dinlemeyi Sürdür'),
          style: FilledButton.styleFrom(
            backgroundColor: _listening ? Colors.white24 : Colors.tealAccent.shade400,
            foregroundColor: _listening ? Colors.white : const Color(0xFF06302E),
          ),
        ),
      );
}

class _Detection {
  _Detection(this.label, this.time);
  final String label;
  final DateTime time;
  String get timeLabel =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
}
