import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/api_client.dart';
import 'medication_screen.dart';

/// Yanındayım — yaşlılar için tek-buton sesli asistan.
///
/// Akış: büyük mikrofon butonu → STT (konuşma→metin) → /yanindayim/intent →
/// algılanan niyet (ilaç / arama / yardım). "ilaç" niyetinde ilaç ekranına yönlendirir.
class YanindayimScreen extends StatefulWidget {
  const YanindayimScreen({super.key});

  @override
  State<YanindayimScreen> createState() => _YanindayimScreenState();
}

class _YanindayimScreenState extends State<YanindayimScreen> {
  final _speech = SpeechToText();
  final _api = ApiClient();

  bool _available = false;
  bool _listening = false;
  String _heard = '';
  String _intent = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _speech.initialize();
    setState(() {});
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      await _resolveIntent();
      return;
    }
    if (!_available) {
      setState(() => _heard = 'Konuşma tanıma kullanılamıyor');
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
      _intent = '';
    });
    await _speech.listen(
      onResult: (r) => setState(() => _heard = r.recognizedWords),
      listenOptions: SpeechListenOptions(localeId: 'tr_TR'),
    );
  }

  Future<void> _resolveIntent() async {
    if (_heard.trim().isEmpty) return;
    try {
      final r = await _api.yanindayimIntent(_heard);
      final intent = r['intent'] as String;
      setState(() => _intent = _intentLabel(intent));
      if (intent == 'ilac_hatirlat' && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationScreen()));
      }
    } catch (e) {
      setState(() => _intent = 'Sunucuya ulaşılamadı');
    }
  }

  String _intentLabel(String intent) => const {
        'ilac_hatirlat': '💊 İlaç hatırlatma',
        'ara': '📞 Arama',
        'ilac_tani': '🔍 İlaç tanıma',
        'yardim': '🆘 Yardım çağrısı',
        'bilinmiyor': '🤔 Anlayamadım',
      }[intent] ??
      intent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yanındayım')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              _listening ? 'Dinliyorum… konuşun' : 'Konuşmak için butona basın',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Büyük tek mikrofon butonu
            GestureDetector(
              onTap: _toggleListen,
              child: CircleAvatar(
                radius: 90,
                backgroundColor: _listening ? Colors.red : Colors.deepOrange,
                child: Icon(_listening ? Icons.mic : Icons.mic_none,
                    size: 90, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            if (_heard.isNotEmpty)
              Text('"$_heard"',
                  style: const TextStyle(fontSize: 22, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_intent.isNotEmpty)
              Text(_intent, style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const MedicationScreen())),
              icon: const Icon(Icons.medication),
              label: const Text('İlaçlarım'),
            ),
          ],
        ),
      ),
    );
  }
}
