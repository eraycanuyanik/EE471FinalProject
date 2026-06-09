import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../core/tts.dart';

/// SesVer — kamera + ML Kit vücut/el takibi ile basit hareketleri tanıyıp
/// sesli söyler (gerçek cihazda çalışır; simülatörde kamera yoktur).
///
/// Tam Türk İşaret Dili çevirisi araştırma seviyesindedir; bu modül hareket
/// seviyesinde bir demodur: el kaldır → "Merhaba", iki el yukarı → "İmdat" vb.
class SesVerScreen extends StatefulWidget {
  const SesVerScreen({super.key});

  @override
  State<SesVerScreen> createState() => _SesVerScreenState();
}

class _SesVerScreenState extends State<SesVerScreen> {
  CameraController? _camera;
  final _detector = PoseDetector(options: PoseDetectorOptions());
  bool _busy = false;

  String _status = 'Başlatılıyor…';
  int _points = 0;
  String _phrase = '';

  // hareket kararlılığı / tekrar konuşmayı önleme
  String _candidate = '';
  int _candidateCount = 0;
  String _lastSpoken = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _camera?.stopImageStream().catchError((_) {});
    _camera?.dispose();
    _detector.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _status = 'Kamera yok (gerçek cihaz gerekir)');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final c = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await c.initialize();
      if (!mounted) return;
      setState(() {
        _camera = c;
        _status = 'Hareketini göster';
      });
      await c.startImageStream(_onFrame);
    } catch (e) {
      setState(() => _status = 'Kamera hatası: $e');
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final poses = await _detector.processImage(input);
      if (poses.isEmpty) {
        if (mounted) setState(() => _points = 0);
        _onGesture('');
        return;
      }
      final pose = poses.first;
      final n = pose.landmarks.values.where((l) => l.likelihood > 0.5).length;
      if (mounted) setState(() => _points = n);
      _onGesture(_detectGesture(pose));
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final cam = _camera;
    if (cam == null) return null;
    final rotation = InputImageRotationValue.fromRawValue(cam.description.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null || format == null) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Pose landmark'larından basit hareketleri çıkarır. (y küçükse = yukarıda)
  String _detectGesture(Pose pose) {
    PoseLandmark? lm(PoseLandmarkType t) {
      final l = pose.landmarks[t];
      return (l != null && l.likelihood > 0.5) ? l : null;
    }

    final nose = lm(PoseLandmarkType.nose);
    final ls = lm(PoseLandmarkType.leftShoulder);
    final rs = lm(PoseLandmarkType.rightShoulder);
    final lw = lm(PoseLandmarkType.leftWrist);
    final rw = lm(PoseLandmarkType.rightWrist);

    if (nose != null && lw != null && rw != null && lw.y < nose.y && rw.y < nose.y) {
      return 'İmdat! Yardım edin';
    }
    if ((lw != null && ls != null && lw.y < ls.y) ||
        (rw != null && rs != null && rw.y < rs.y)) {
      return 'Merhaba';
    }
    if (lw != null && rw != null && ls != null && rs != null) {
      final shoulderY = (ls.y + rs.y) / 2;
      final shoulderW = (ls.x - rs.x).abs();
      if (lw.y > shoulderY && rw.y > shoulderY && (lw.x - rw.x).abs() < shoulderW * 0.6) {
        return 'Teşekkür ederim';
      }
    }
    return '';
  }

  void _onGesture(String g) {
    if (g == _candidate) {
      _candidateCount++;
    } else {
      _candidate = g;
      _candidateCount = 1;
    }
    if (g.isEmpty) {
      _lastSpoken = ''; // hareket bitince aynı hareket tekrar tetiklenebilsin
      return;
    }
    // aynı hareket 3 kare üst üste + daha önce söylenmediyse seslendir
    if (_candidateCount >= 3 && g != _lastSpoken) {
      _lastSpoken = g;
      if (mounted) setState(() => _phrase = g);
      Tts.speak(g);
    }
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
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.videocam_off, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_status,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge),
                      ]),
                    ),
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(children: [
              Text('Algılanan nokta: $_points',
                  style: const TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(_phrase.isEmpty ? '—' : _phrase,
                  style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Dene: el kaldır · iki el yukarı · iki el göğüste',
                  style: TextStyle(fontSize: 13, color: Colors.black45)),
            ]),
          ),
        ],
      ),
    );
  }
}
