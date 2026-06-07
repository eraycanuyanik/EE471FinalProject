import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// Yanındayım — yaşlılar için tek-buton sesli asistan. İSKELET ekranı.
///
/// Şimdilik metin girişiyle /yanindayim/intent uç noktasını test eder.
/// Gerçek akış: tek buton → STT → intent → eylem (ilaç hatırlat / ara / tanı).
class YanindayimScreen extends StatefulWidget {
  const YanindayimScreen({super.key});

  @override
  State<YanindayimScreen> createState() => _YanindayimScreenState();
}

class _YanindayimScreenState extends State<YanindayimScreen> {
  final _api = ApiClient();
  final _controller = TextEditingController(text: 'ilaç vaktim geldi mi');
  String _result = '';

  Future<void> _detect() async {
    try {
      final r = await _api.yanindayimIntent(_controller.text);
      setState(() => _result = 'Niyet: ${r['intent']}');
    } catch (e) {
      setState(() => _result = 'Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yanındayım')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Chip(label: Text('İskelet — STT/diarization eklenecek')),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Komut (şimdilik yazılı)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _detect,
              icon: const Icon(Icons.psychology),
              label: const Text('Niyeti Anla'),
            ),
            const SizedBox(height: 24),
            Text(_result, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
