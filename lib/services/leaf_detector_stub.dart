import 'dart:async';
import 'leaf_detector_service.dart';

LeafDetectorPlatform getLeafDetector() => LeafDetectorStub();

class LeafDetectorStub implements LeafDetectorPlatform {
  Timer? _timer;

  @override
  void start({
    required Function(LeafDetectionResult result) onResult,
    double Function()? getZoomLevel,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      final zoom = getZoomLevel?.call() ?? 1.0;
      if (zoom >= 1.5) {
        onResult(LeafDetectionResult(
          isRiceLeafPresent: true,
          isTooFar: false,
          coverageRatio: 0.65,
          statusMessage: "Zoom ${zoom.toStringAsFixed(1)}x — Daun Terfokus",
        ));
      } else {
        // Pada perangkat native saat zoom rendah, beri instruksi posisi tanpa memunculkan false-warning
        onResult(const LeafDetectionResult(
          isRiceLeafPresent: false,
          isTooFar: false,
          coverageRatio: 0.0,
          statusMessage: "Posisikan daun padi di dalam kotak",
        ));
      }
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
  }
}
