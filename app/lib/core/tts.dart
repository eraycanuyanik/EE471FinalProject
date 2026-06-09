import 'package:flutter_tts/flutter_tts.dart';

/// Türkçe sesli yanıt (Text-to-Speech) yardımcısı — Yanındayım için.
class Tts {
  static final _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.45); // yaşlılar için biraz yavaş
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _ready = true;
  }

  static Future<void> speak(String text) async {
    await _init();
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> stop() async => _tts.stop();
}
