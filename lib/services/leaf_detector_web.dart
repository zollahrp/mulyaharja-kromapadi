// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'leaf_detector_service.dart';

LeafDetectorPlatform getLeafDetector() => LeafDetectorWeb();

class LeafDetectorWeb implements LeafDetectorPlatform {
  Timer? _timer;
  html.CanvasElement? _canvas;
  html.CanvasRenderingContext2D? _ctx;

  @override
  void start({
    required Function(LeafDetectionResult result) onResult,
    double Function()? getZoomLevel,
  }) {
    _timer?.cancel();
    _canvas ??= html.CanvasElement(width: 48, height: 48);
    _ctx = _canvas!.context2D;

    _timer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      try {
        final videoList = html.document.getElementsByTagName('video');
        if (videoList.isEmpty) {
          onResult(const LeafDetectionResult(
            isRiceLeafPresent: false,
            isTooFar: false,
            coverageRatio: 0.0,
            statusMessage: "Kamera pemindai siap",
          ));
          return;
        }

        final video = videoList.first as html.VideoElement;
        if (video.videoWidth <= 0 || video.videoHeight <= 0) return;

        // Gambar frame kamera saat ini ke offscreen canvas ukuran kecil (48x48)
        _ctx!.drawImageScaled(video, 0, 0, 48, 48);
        final imgData = _ctx!.getImageData(0, 0, 48, 48);
        final data = imgData.data;

        int totalCenterPixels = 0;
        int greenPixels = 0;

        // Area tengah (reticle fokus daun padi)
        const int minCoord = 10;
        const int maxCoord = 38;

        for (int y = minCoord; y < maxCoord; y++) {
          for (int x = minCoord; x < maxCoord; x++) {
            totalCenterPixels++;
            final index = (y * 48 + x) * 4;
            final r = data[index];
            final g = data[index + 1];
            final b = data[index + 2];

            // Deteksi spektrum klorofil daun padi (ExG / Excess Green Index):
            // 1. Hijau lebih dominan dari merah dan biru
            // 2. Klorofil indeks (2G - R - B) signifikan
            // 3. Saturasi dan kecerahan bukan hitam/bayangan pekat
            final brightness = 0.299 * r + 0.587 * g + 0.114 * b;
            final maxC = [r, g, b].reduce((c, n) => c > n ? c : n);
            final minC = [r, g, b].reduce((c, n) => c < n ? c : n);
            final saturation = maxC - minC;

            final bool isGreenLeaf = (g > r * 1.08) &&
                (g > b * 1.08) &&
                ((2 * g - r - b) > 16) &&
                saturation > 16 &&
                brightness > 28;

            if (isGreenLeaf) {
              greenPixels++;
            }
          }
        }

        final double coverage = totalCenterPixels > 0 ? (greenPixels / totalCenterPixels) : 0.0;
        final double zoom = getZoomLevel?.call() ?? 1.0;

        // Coverage efektif memperhitungkan magnifikasi zoom
        final double effectiveCoverage = (coverage * (zoom >= 1.4 ? (zoom * 0.95) : 1.0)).clamp(0.0, 1.0);

        if (coverage < 0.10) {
          // Tidak ada objek daun padi dalam reticle (misal mengarah ke wajah, ruangan, meja, dll)
          // TIDAK MUNCUL NOTIFIKASI
          onResult(const LeafDetectionResult(
            isRiceLeafPresent: false,
            isTooFar: false,
            coverageRatio: 0.0,
            statusMessage: "Posisikan daun padi di dalam kotak",
          ));
        } else if (effectiveCoverage < 0.38) {
          // Objek daun padi terdeteksi, tetapi ukurannya masih kecil/terlalu jauh dari reticle
          // MUNCUL NOTIFIKASI: Objek Terlalu Jauh
          onResult(LeafDetectionResult(
            isRiceLeafPresent: true,
            isTooFar: true,
            coverageRatio: effectiveCoverage,
            statusMessage: "Objek daun terlalu jauh (dekatkan atau gunakan zoom)",
          ));
        } else {
          // Objek daun padi berada di jarak ideal (15-20 cm) dan mengisi reticle dengan baik
          // TIDAK MUNCUL NOTIFIKASI PERINGATAN (Status siap pindai)
          onResult(LeafDetectionResult(
            isRiceLeafPresent: true,
            isTooFar: false,
            coverageRatio: effectiveCoverage,
            statusMessage: "Jarak Ideal (15–20 cm) ✓ Daun Terfokus",
          ));
        }
      } catch (_) {}
    });
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    _canvas = null;
    _ctx = null;
  }
}
