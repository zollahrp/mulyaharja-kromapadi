import 'leaf_detector_stub.dart'
    if (dart.library.html) 'leaf_detector_web.dart';

class LeafDetectionResult {
  final bool isRiceLeafPresent;
  final bool isTooFar;
  final double coverageRatio; // 0.0 to 1.0 (proporsi area hijau daun padi di reticle)
  final String statusMessage;

  const LeafDetectionResult({
    required this.isRiceLeafPresent,
    required this.isTooFar,
    required this.coverageRatio,
    required this.statusMessage,
  });

  static const LeafDetectionResult initial = LeafDetectionResult(
    isRiceLeafPresent: false,
    isTooFar: false,
    coverageRatio: 0.0,
    statusMessage: "Posisikan daun padi di dalam kotak",
  );
}

abstract class LeafDetectorPlatform {
  factory LeafDetectorPlatform() => getLeafDetector();

  void start({
    required Function(LeafDetectionResult result) onResult,
    double Function()? getZoomLevel,
  });

  void stop();
  void dispose();
}
