import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/tts.dart';
import 'contact.dart';
import 'medication.dart';
import 'medication_screen.dart';

/// Yanındayım — yaşlılar için tek-buton sesli asistan.
///
/// Tamamen CİHAZ ÜZERİNDE çalışır (internet/sunucu GEREKMEZ):
///   büyük mikrofon → STT (konuşma→metin) → komut algıla → EYLEM + sesli yanıt (TTS)
/// Komutlar: "ilacım ne zaman", "ilaç ekle", "annemi ara", "yardım".
class YanindayimScreen extends StatefulWidget {
  const YanindayimScreen({super.key});

  @override
  State<YanindayimScreen> createState() => _YanindayimScreenState();
}

class _YanindayimScreenState extends State<YanindayimScreen> {
  final _speech = SpeechToText();
  final _medStore = MedicationStore();
  final _contactStore = ContactStore();

  bool _available = false;
  bool _listening = false;
  String _heard = '';
  String _response = '';

  @override
  void initState() {
    super.initState();
    _speech.initialize().then((ok) => setState(() => _available = ok));
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    if (!_available) {
      _respond('Konuşma tanıma kullanılamıyor. Mikrofon iznini kontrol edin.');
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
      _response = '';
    });
    await _speech.listen(
      onResult: (r) {
        setState(() => _heard = r.recognizedWords);
        if (r.finalResult) {
          setState(() => _listening = false);
          _handle(r.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'tr_TR',
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  void _respond(String text) {
    setState(() => _response = text);
    Tts.speak(text);
  }

  Future<void> _handle(String raw) async {
    final t = raw.toLowerCase();
    if (t.trim().isEmpty) {
      _respond('Sizi duyamadım, tekrar deneyin.');
      return;
    }

    // ARAMA: "annemi ara", "telefon et", "ara"
    if (_has(t, ['ara', 'telefon', 'anne', 'oğl', 'kız', 'çocu'])) {
      await _callContact();
      return;
    }
    // İLAÇ EKLE
    if (_has(t, ['ekle', 'yeni ilaç', 'ilaç ekle'])) {
      _respond('İlaç ekleme açılıyor.');
      _openMeds(openAdd: true);
      return;
    }
    // İLAÇ SORGU: "ilacım ne zaman", "hangi ilaç", "ilaç vakti"
    if (_has(t, ['ilaç', 'ilac', 'hap', 'doz', 'ilacım'])) {
      await _speakMedications();
      return;
    }
    // YARDIM
    if (_has(t, ['yardım', 'imdat', 'düştüm', 'iyi değil', 'fenala'])) {
      _respond('Yardım için yakınınızı arıyorum.');
      await _callContact();
      return;
    }
    _respond('Bunu anlayamadım. "İlacım ne zaman", "ilaç ekle" veya "annemi ara" diyebilirsiniz.');
  }

  bool _has(String text, List<String> keys) => keys.any((k) => text.contains(k));

  Future<void> _speakMedications() async {
    final meds = await _medStore.load();
    if (meds.isEmpty) {
      _respond('Kayıtlı ilacınız yok. "İlaç ekle" diyerek ekleyebilirsiniz.');
      return;
    }
    meds.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    final parts = meds.map((m) => '${m.timeLabel}\'de ${m.name}').join(', ');
    _respond('Bugünkü ilaçlarınız: $parts.');
  }

  Future<void> _callContact() async {
    final c = await _contactStore.load();
    if (c == null) {
      _respond('Önce aranacak kişiyi kaydedin.');
      _showContactDialog();
      return;
    }
    final (name, number) = c;
    _respond('$name aranıyor.');
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _respond('Arama başlatılamadı.');
    }
  }

  void _openMeds({bool openAdd = false}) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MedicationScreen(openAddOnStart: openAdd)));
  }

  Future<void> _showContactDialog() async {
    final nameC = TextEditingController(text: 'Anne');
    final numC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aranacak Kişi'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameC, decoration: const InputDecoration(labelText: 'İsim')),
          TextField(
              controller: numC,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon (örn. 05xx...)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok == true && numC.text.trim().isNotEmpty) {
      await _contactStore.save(nameC.text.trim(), numC.text.trim());
      _respond('${nameC.text.trim()} kaydedildi. Tekrar "ara" diyebilirsiniz.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yanındayım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Aranacak kişi',
            onPressed: _showContactDialog,
          ),
        ],
      ),
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
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _toggleListen,
              child: CircleAvatar(
                radius: 92,
                backgroundColor: _listening ? Colors.red : Colors.deepOrange,
                child: Icon(_listening ? Icons.mic : Icons.mic_none, size: 92, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            if (_heard.isNotEmpty)
              Text('"$_heard"',
                  style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_response.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, color: Colors.deepOrange),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(_response,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openMeds(),
              icon: const Icon(Icons.medication),
              label: const Text('İlaçlarım'),
            ),
          ],
        ),
      ),
    );
  }
}
