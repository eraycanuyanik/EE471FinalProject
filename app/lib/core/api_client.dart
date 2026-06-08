import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Erişim ML servisine (ml_service, FastAPI) bağlanan istemci.
///
/// baseUrl: gerçek cihazda bilgisayarının LAN IP'sini kullan (ör. http://192.168.1.20:8000).
/// Android emülatöründe makineye 10.0.2.2 ile erişilir; iOS simülatöründe localhost.
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  final String baseUrl;

  static String _defaultBaseUrl() {
    // Android emülatörü host makineyi 10.0.2.2 üzerinden görür.
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  Future<Map<String, dynamic>> health() async {
    final r = await http.get(Uri.parse('$baseUrl/health'));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Duyar: base64 WAV gönder, sınıflandırma sonucu al.
  Future<DuyarResult> duyarPredict(String audioBase64) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/duyar/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'audio_b64': audioBase64}),
        )
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception('Servis hatası ${r.statusCode}: ${r.body}');
    }
    return DuyarResult.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// SesVer: landmark vektörü gönder, işaret tahmini al (iskelet).
  Future<Map<String, dynamic>> sesverPredict(List<List<double>> landmarks) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/sesver/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'landmarks': landmarks}),
        )
        .timeout(const Duration(seconds: 10));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Yanındayım: metinden niyet çıkar (iskelet).
  Future<Map<String, dynamic>> yanindayimIntent(String text) async {
    final r = await http.post(
      Uri.parse('$baseUrl/yanindayim/intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}

class DuyarResult {
  DuyarResult({
    required this.label,
    required this.confidence,
    required this.critical,
    required this.allScores,
  });

  final String label;
  final double confidence;
  final bool critical;
  final Map<String, double> allScores;

  factory DuyarResult.fromJson(Map<String, dynamic> j) => DuyarResult(
        label: j['label'] as String,
        confidence: (j['confidence'] as num).toDouble(),
        critical: j['critical'] as bool,
        allScores: (j['all_scores'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      );

  /// Sınıf adını kullanıcıya gösterilecek Türkçe etikete çevirir.
  String get displayName => const {
        'sessizlik': '🔇 Sessizlik',
        'diger': '🎵 Ortam sesi',
        'konusma': '🗣️ Konuşma',
        'siren': '🚨 Siren',
        'kapi_zili': '🔔 Kapı zili',
        'bebek_aglamasi': '👶 Bebek ağlaması',
        'alarm': '⏰ Alarm',
        'kapi_vurma': '✊ Kapı vurma',
        'isim_cagirma': '🗣️ İsim çağrılması',
        'kopek_havlamasi': '🐕 Köpek havlaması',
      }[label] ??
      label;
}
