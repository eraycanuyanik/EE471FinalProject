import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';

import '../../core/api_client.dart';

/// Duyar — ortam sesini dinler, 1 sn'lik pencereler halinde ML servisine
/// gönderir, kritik bir ses tanınırsa titreşim + görsel uyarı verir.
class DuyarScreen extends StatefulWidget {
  const DuyarScreen({super.key});

  @override
  State<DuyarScreen> createState() => _DuyarScreenState();
}

class _DuyarScreenState extends State<DuyarScreen> {
  final _recorder = AudioRecorder();
  final _api = ApiClient();

  bool _listening = false;
  String _status = 'Dinleme kapalı';
  DuyarResult? _last;
  Timer? _loop;

  @override
  void dispose() {
    _loop?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      _loop?.cancel();
      await _recorder.stop();
      setState(() {
        _listening = false;
        _status = 'Dinleme kapalı';
      });
      return;
    }

    if (!await _recorder.hasPermission()) {
      setState(() => _status = 'Mikrofon izni gerekli');
      return;
    }
    setState(() {
      _listening = true;
      _status = 'Dinleniyor…';
    });
    // 1 sn'lik pencereler halinde sürekli kaydet → sınıflandır.
    _captureOnce(); // ilk pencere hemen
    _loop = Timer.periodic(const Duration(milliseconds: 1100), (_) => _captureOnce());
  }

  Future<void> _captureOnce() async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/duyar_clip.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      final saved = await _recorder.stop();
      if (saved == null) return;

      final bytes = await File(saved).readAsBytes();
      final result = await _api.duyarPredict(base64Encode(bytes));
      if (!mounted) return;
      setState(() {
        _last = result;
        _status = 'Dinleniyor…';
      });
      if (result.critical && result.confidence > 0.6) {
        await _alert(result);
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Hata: $e');
    }
  }

  Future<void> _alert(DuyarResult r) async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 400, 200, 400]);
    }
    // gerçek uygulamada burada flutter_local_notifications ile bildirim de gider
  }

  @override
  Widget build(BuildContext context) {
    final r = _last;
    return Scaffold(
      appBar: AppBar(title: const Text('Duyar')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(_status, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: r == null
                    ? Text(
                        'Henüz ses algılanmadı',
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    : _ResultCard(result: r),
              ),
            ),
            FilledButton.icon(
              onPressed: _toggle,
              icon: Icon(_listening ? Icons.stop : Icons.mic),
              label: Text(_listening ? 'Dinlemeyi Durdur' : 'Dinlemeyi Başlat'),
              style: FilledButton.styleFrom(
                backgroundColor: _listening ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final DuyarResult result;

  @override
  Widget build(BuildContext context) {
    final critical = result.critical;
    return Card(
      color: critical ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.displayName,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Güven: %${(result.confidence * 100).toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (critical) ...[
              const SizedBox(height: 16),
              const Text(
                '⚠️ Kritik ses!',
                style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
