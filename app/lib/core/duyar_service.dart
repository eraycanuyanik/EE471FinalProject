import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';

import 'api_client.dart';
import 'notifications.dart';

class DuyarDetection {
  DuyarDetection(this.label, this.time);
  final String label;
  final DateTime time;
  String get timeLabel =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
}

/// Duyar dinleme motoru — ekrandan BAĞIMSIZ, uygulama boyunca arka planda çalışır.
/// Kesintisiz PCM akışını 1 sn'lik pencerelere bölüp ML servisine gönderir,
/// kritik ses tanınınca türüne özel titreşim + bildirim verir.
class DuyarService {
  DuyarService._();
  static final DuyarService instance = DuyarService._();

  final _recorder = AudioRecorder();
  final api = ApiClient();
  StreamSubscription<Uint8List>? _sub;
  final List<int> _buf = [];
  bool _sending = false;

  // UI'nin dinleyebileceği gözlemlenebilir durumlar
  final running = ValueNotifier<bool>(false);
  final status = ValueNotifier<String>('Kapalı');
  final level = ValueNotifier<double>(0);
  final current = ValueNotifier<DuyarResult?>(null);
  final history = ValueNotifier<List<DuyarDetection>>([]);

  String? _lastAlertLabel;
  DateTime _lastAlertTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _cooldown = Duration(seconds: 3);
  static const _sampleRate = 16000;
  static const _windowBytes = _sampleRate * 2;

  static const _patterns = <String, List<int>>{
    'siren': [0, 500, 180, 500, 180, 500],
    'kapi_zili': [0, 250, 120, 250],
    'bebek_aglamasi': [0, 180, 90, 180, 90, 180, 90, 180],
    'alarm': [0, 600, 250, 600],
    'kapi_vurma': [0, 130, 90, 130, 90, 130],
    'isim_cagirma': [0, 400, 150, 200, 150, 200],
  };

  Future<bool> start() async {
    if (running.value) return true;
    await Notifications.init();
    if (!await _recorder.hasPermission()) {
      status.value = 'Mikrofon izni gerekli';
      return false;
    }
    try {
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      ));
      _sub = stream.listen(_onAudio);
      running.value = true;
      status.value = 'Dinleniyor';
      return true;
    } catch (e) {
      status.value = 'Başlatılamadı';
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _recorder.stop();
    _buf.clear();
    running.value = false;
    status.value = 'Kapalı';
    level.value = 0;
  }

  void _onAudio(Uint8List data) {
    _updateLevel(data);
    _buf.addAll(data);
    if (_buf.length >= _windowBytes) {
      final window = Uint8List.fromList(_buf.sublist(0, _windowBytes));
      _buf.removeRange(0, _windowBytes);
      if (!_sending) _classify(window);
    }
    if (_buf.length > _windowBytes * 3) {
      _buf.removeRange(0, _buf.length - _windowBytes);
    }
  }

  void _updateLevel(Uint8List data) {
    if (data.length < 2) return;
    final bd = ByteData.sublistView(data);
    final n = data.length ~/ 2;
    double sum = 0;
    for (var i = 0; i < n; i++) {
      final s = bd.getInt16(i * 2, Endian.little) / 32768.0;
      sum += s * s;
    }
    level.value = (sqrt(sum / n) * 5).clamp(0.0, 1.0);
  }

  Future<void> _classify(Uint8List pcm) async {
    _sending = true;
    try {
      final wav = _pcm16ToWav(pcm, _sampleRate);
      final result = await api.duyarPredict(base64Encode(wav));
      current.value = result;
      status.value = 'Dinleniyor';
      if (result.critical) {
        final now = DateTime.now();
        final sameRecent =
            result.label == _lastAlertLabel && now.difference(_lastAlertTime) < _cooldown;
        if (!sameRecent) {
          _lastAlertLabel = result.label;
          _lastAlertTime = now;
          _onCritical(result);
        }
      }
    } catch (e) {
      status.value = 'Sunucuya bağlanılamadı';
    } finally {
      _sending = false;
    }
  }

  Future<void> _onCritical(DuyarResult r) async {
    history.value = [DuyarDetection(r.displayName, DateTime.now()), ...history.value].take(10).toList();
    final pattern = _patterns[r.label] ?? [0, 400, 200, 400];
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: pattern);
    }
    // Ekran kapalı / başka uygulamadaysa görmek için bildirim
    await Notifications.showNow('${r.displayName} algılandı', 'Duyar kritik bir ses tespit etti');
  }

  Uint8List _pcm16ToWav(Uint8List pcm, int sampleRate) {
    final dataLen = pcm.length;
    final byteRate = sampleRate * 2;
    final out = BytesBuilder();
    Uint8List le32(int v) => (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();
    Uint8List le16(int v) => (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List();
    out.add(ascii.encode('RIFF'));
    out.add(le32(36 + dataLen));
    out.add(ascii.encode('WAVE'));
    out.add(ascii.encode('fmt '));
    out.add(le32(16));
    out.add(le16(1));
    out.add(le16(1));
    out.add(le32(sampleRate));
    out.add(le32(byteRate));
    out.add(le16(2));
    out.add(le16(16));
    out.add(ascii.encode('data'));
    out.add(le32(dataLen));
    out.add(pcm);
    return out.toBytes();
  }
}
