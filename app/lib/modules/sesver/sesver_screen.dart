import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// SesVer — işaret dili → konuşma demo'su (kamera tabanlı pipeline).
///
/// Kamera önizlemesini açar ve düzenli aralıklarla kare yakalayıp landmark
/// pipeline'ını ml_service /sesver/predict'e bağlar.
///
/// EL LANDMARK TAKİBİ (MediaPipe/ML Kit) NEREDE?
/// Google ML Kit Pose/Hand, Apple Silicon arm64 iOS SİMÜLATÖRÜNÜ desteklemez
/// (yalnızca fiziksel cihaz). Bu yüzden simülatörde çalışabilmek için ML Kit
/// bağımlılığı kaldırıldı. Gerçek cihazda el landmark'ı eklemek için:
///   1) pubspec'e google_mlkit_pose_detection ekle
///   2) PoseDetector ile bu ekranda yakalanan kareyi işle
///   3) pose.landmarks (bilek/parmak) -> _sendLandmarks(vector)
/// Bkz. docs/ARCHITECTURE.md → SesVer.
class SesVerScreen extends StatefulWidget {
  const SesVerScreen({super.key});

  @override
  State<SesVerScreen> createState() => _SesVerScreenState();
}

class _SesVerScreenState extends State<SesVerScreen> {
  final _api = ApiClient();
  CameraController? _camera;
  Timer? _loop;
  bool _busy = false;
  String _status = 'Başlatılıyor…';
  int _frames = 0;
  String _gloss = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _status =
            'Kamera bulunamadı.\nSesVer kamera gerektirir — iOS simülatöründe kamera yoktur, gerçek cihazda çalışır.');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _camera = controller;
        _status = 'Landmark pipeline açık';
      });
      _loop = Timer.periodic(const Duration(milliseconds: 900), (_) => _processFrame());
    } catch (e) {
      setState(() => _status = 'Kamera hatası: $e');
    }
  }

  Future<void> _processFrame() async {
    final cam = _camera;
    if (cam == null || _busy || !cam.value.isInitialized) return;
    _busy = true;
    try {
      // Gerçek cihazda: burada yakalanan kareden ML Kit ile landmark çıkarılır.
      // Şimdilik pipeline'ı doğrulamak için kare sayısından türetilmiş bir
      // sözde-landmark vektörü gönderiyoruz.
      _frames++;
      final vector = [
        [(_frames % 5).toDouble(), (_frames % 3).toDouble()],
      ];
      final r = await _api.sesverPredict(vector);
      if (mounted) setState(() => _gloss = (r['sentence'] as String?) ?? '');
    } catch (_) {
      // tek kare hatasını yut
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _loop?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    return Scaffold(
      appBar: AppBar(title: const Text('SesVer')),
      body: Column(
        children: [
          Expanded(
            child: cam != null && cam.value.isInitialized
                ? CameraPreview(cam)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_off, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(_status,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text('İşlenen kare: $_frames', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text(_gloss.isEmpty ? '—' : _gloss,
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
