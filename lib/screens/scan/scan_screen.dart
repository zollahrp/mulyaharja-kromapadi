import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_colors.dart';
import 'scan_result_screen.dart';
import '../../models/lahan_model.dart';
import '../../services/lahan_service.dart';
import '../../services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:light/light.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/leaf_detector_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  int _currentCameraIndex = 0;
  final ImagePicker _picker = ImagePicker();

  // Zoom control & distance guidance
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  double _baseZoom = 1.0;

  // Real-time leaf presence & distance detector
  final LeafDetectorPlatform _leafDetector = LeafDetectorPlatform();
  LeafDetectionResult? _detectionResult = LeafDetectionResult.initial;

  final LahanService _lahanService = LahanService();
  List<LahanModel> _lahans = [];
  LahanModel? _selectedLahan;
  bool _isLoadingLahan = true;
  bool _isCheckingLocation = true;
  bool _showTips = true;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _checkLocationAndInit();
  }

  Future<void> _checkLocationAndInit() async {
    try {
      if (kIsWeb) {
        // Skip strict location check on web for easier testing
        await _fetchLahans();
        await _initCamera();
        return;
      }

      final authService = AuthService();
      final user = await authService.getCurrentUser();
      
      if (user != null && user.wilayah != null && user.wilayah!.latitude != null && user.wilayah!.longitude != null) {
        final targetLat = double.tryParse(user.wilayah!.latitude!);
        final targetLng = double.tryParse(user.wilayah!.longitude!);
        
        if (targetLat != null && targetLng != null) {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            _showLocationError('Layanan lokasi tidak aktif.');
            return;
          }
          
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              _showLocationError('Izin lokasi ditolak.');
              return;
            }
          }
          
          if (permission == LocationPermission.deniedForever) {
            _showLocationError('Izin lokasi ditolak permanen.');
            return;
          }
          
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          double distanceInMeters = Geolocator.distanceBetween(
            position.latitude, position.longitude,
            targetLat, targetLng
          );
          
          // Tolerate distance, e.g. 50 km
          if (distanceInMeters > 50000) {
            _showLocationError('Anda tidak berada di wilayah KTD terdaftar.');
            return;
          }
        }
      } else {
        // Fallback: If Wilayah is not fully set, verify based on city mismatch (e.g. Bogor vs Karet Tengsin)
        if (user?.kelompokTaniName?.toLowerCase().contains('karet tengsin') ?? false) {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }
            if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
              Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
              List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
              if (placemarks.isNotEmpty) {
                String city = placemarks.first.subAdministrativeArea?.toLowerCase() ?? '';
                String locality = placemarks.first.locality?.toLowerCase() ?? '';
                
                if (city.contains('bogor') || locality.contains('bogor')) {
                  _showLocationError('Anda terdeteksi di Bogor, sedangkan KTD Anda (Karet Tengsin) berada di Jakarta Pusat.');
                  return;
                }
              }
            }
          }
        }
      }
      
      await _fetchLahans();
      await _initCamera();
    } catch (e) {
      _showLocationError('Gagal memverifikasi lokasi: $e');
    } finally {
      if (mounted) setState(() => _isCheckingLocation = false);
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Peringatan Lokasi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close screen
            },
            child: const Text('Kembali', style: TextStyle(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLahans() async {
    try {
      final lahans = await _lahanService.getLahan();
      if (!mounted) return;
      setState(() {
        _lahans = lahans;
        if (_lahans.isNotEmpty) {
          _selectedLahan = _lahans.firstWhere(
            (l) => l.isAktif,
            orElse: () => _lahans.first,
          );
        }
        _isLoadingLahan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLahan = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat lahan: $e')),
      );
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _setCamera(_currentCameraIndex);
    }
  }

  Future<void> _setCamera(int index) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final camera = _cameras![index];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      double minZ = 1.0;
      double maxZ = 4.0;
      try {
        minZ = await _cameraController!.getMinZoomLevel();
        maxZ = (await _cameraController!.getMaxZoomLevel()).clamp(1.0, 6.0);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _minZoom = minZ;
          _maxZoom = maxZ;
          _currentZoom = 1.0.clamp(minZ, maxZ);
        });

        // Jalankan pendeteksi jarak daun padi secara real-time
        _leafDetector.start(
          getZoomLevel: () => _currentZoom,
          onResult: (result) {
            if (!mounted) return;
            setState(() {
              _detectionResult = result;
            });
          },
        );
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    final target = zoom.clamp(_minZoom, _maxZoom);
    try {
      await _cameraController!.setZoomLevel(target);
      if (mounted) {
        setState(() {
          _currentZoom = target;
        });
      }
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint("Zoom error: $e");
    }
  }

  @override
  void dispose() {
    _leafDetector.dispose();
    _scanAnimationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    _isFlashOn = !_isFlashOn;
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    _isCameraInitialized = false;
    setState(() {});
    await _setCamera(_currentCameraIndex);
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (image != null) {
      _navigateToResult(image);
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      // Matikan flash jika menyala setelah foto
      if (_isFlashOn) {
        await _toggleFlash();
      }
      _navigateToResult(image);
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<void> _navigateToResult(XFile image) async {
    if (_selectedLahan == null || _selectedLahan!.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peringatan: Belum ada lahan yang terdaftar atau dipilih untuk akun Anda.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int? luxValue;
    if (!kIsWeb) {
      try {
        Light light = Light();
        luxValue = await light.lightSensorStream.first.timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint("Gagal membaca sensor cahaya: $e");
      }
    }

    int? plantAgeDays;
    if (_selectedLahan != null) {
      if (_selectedLahan!.hst != null) {
        plantAgeDays = _selectedLahan!.hst;
      } else if (_selectedLahan!.tanggalTanam != null && _selectedLahan!.tanggalTanam!.isNotEmpty) {
        try {
          DateTime plantingDate = DateTime.parse(_selectedLahan!.tanggalTanam!);
          // Hitung umur tanaman per 15 Oktober 2026 sesuai tanggal sampel penelitian
          plantAgeDays = DateTime(2026, 10, 15).difference(plantingDate).inDays;
        } catch (e) {
          debugPrint("Error parse tanggalTanam: $e");
        }
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(
          imageFile: image, 
          lahanId: _selectedLahan!.id,
          luxValue: luxValue,
          plantAgeDays: plantAgeDays,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Scan Daun Padi",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.amber[700] : Colors.black87,
            ),
            tooltip: "Flash",
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            tooltip: "Panduan",
            onPressed: _showGuideModal,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 2),
            _buildStepIndicator(),
            const SizedBox(height: 6),
            _buildLahanSelector(),
            const SizedBox(height: 6),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraPreview(),
                  _buildCameraOverlay(),
                ],
              ),
            ),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildLahanSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: InkWell(
        onTap: _lahans.length > 1 ? _showLahanPicker : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _selectedLahan != null
                      ? "Lahan: ${_selectedLahan!.name}"
                      : (_isLoadingLahan ? "Memuat lahan..." : "Tidak ada lahan aktif"),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_lahans.length > 1) ...[
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF1B5E20)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLahanPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pilih Lahan Tani",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBlack),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _lahans.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final lahan = _lahans[index];
                    final isSelected = lahan.id == _selectedLahan?.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        lahan.name,
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      ),
                      subtitle: Text(
                        lahan.isAktif ? 'Masa Tanam Aktif' : 'Masa Tanam Non-Aktif',
                        style: TextStyle(color: lahan.isAktif ? Colors.green : Colors.grey, fontSize: 12),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryGreen) : null,
                      onTap: () {
                        setState(() {
                          _selectedLahan = lahan;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem("Ambil Gambar", 1, true),
          _buildStepDivider(),
          _buildStepItem("Analisis", 2, false),
          _buildStepDivider(),
          _buildStepItem("Hasil", 3, false),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, int step, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryGreen : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primaryGreen : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primaryGreen : Colors.grey[400],
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 1,
        color: Colors.grey[300],
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isCheckingLocation) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text("Memverifikasi lokasi...", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black,
      ),
      clipBehavior: Clip.antiAlias,
      child: _isCameraInitialized
          ? GestureDetector(
              onScaleStart: (details) {
                _baseZoom = _currentZoom;
              },
              onScaleUpdate: (details) {
                if (_cameraController == null || !_isCameraInitialized) return;
                final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
                _setZoom(newZoom);
              },
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CameraPreview(_cameraController!),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  void _showGuideModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.help_outline, color: AppColors.primaryGreen, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Panduan Pemindaian Daun",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                Icons.center_focus_strong,
                "Fokus pada 1 Helai Daun",
                "Posisikan satu helai daun padi utama tepat di dalam kotak panduan.",
              ),
              const SizedBox(height: 12),
              _buildGuideItem(
                Icons.wb_sunny_outlined,
                "Pencahayaan Optimal",
                "Hindari bayangan tebal atau backlight. Gunakan tombol flash jika kondisi redup.",
              ),
              const SizedBox(height: 12),
              _buildGuideItem(
                Icons.straighten,
                "Jarak Ideal 15 - 25 cm",
                "Pegang ponsel secara stabil agar bercak daun tidak buram atau blur.",
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Mengerti, Lanjutkan", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxH = constraints.maxHeight;
        final double maxW = constraints.maxWidth;

        final detection = _detectionResult ?? LeafDetectionResult.initial;

        // Dimensi kotak pemindaian proporsional dan responsif secara dinamis
        final double boxWidth = (maxW * 0.72).clamp(160.0, 260.0);
        final double boxHeight = (maxH * 0.58).clamp(140.0, 310.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Area instruksi teks pill mengambang di atas reticle
            Positioned(
              top: (maxH / 2 - boxHeight / 2 - 44).clamp(10.0, maxH),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: detection.isRiceLeafPresent && !detection.isTooFar
                        ? AppColors.primaryGreen.withValues(alpha: 0.8)
                        : (detection.isTooFar
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.2)),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      detection.isRiceLeafPresent && !detection.isTooFar
                          ? Icons.check_circle_rounded
                          : (detection.isTooFar
                              ? Icons.straighten_rounded
                              : (_currentZoom > 1.2 ? Icons.zoom_in_rounded : Icons.center_focus_strong)),
                      color: detection.isRiceLeafPresent && !detection.isTooFar
                          ? Colors.greenAccent
                          : (detection.isTooFar ? const Color(0xFFFBBF24) : Colors.greenAccent),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      detection.isRiceLeafPresent
                          ? detection.statusMessage
                          : (_currentZoom > 1.2
                              ? "Zoom ${_currentZoom.toStringAsFixed(1)}x — Arahkan ke Daun"
                              : detection.statusMessage),
                      style: TextStyle(
                        color: detection.isRiceLeafPresent && !detection.isTooFar
                            ? Colors.greenAccent
                            : (detection.isTooFar ? const Color(0xFFFBBF24) : Colors.white),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Kotak Pemindaian dengan Garis Laser Animasi
            Center(
              child: Container(
                width: boxWidth,
                height: boxHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: detection.isRiceLeafPresent && !detection.isTooFar
                        ? AppColors.primaryGreen.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Corner Brackets dengan Warna Adaptif Terhadap Deteksi Daun
                    Builder(
                      builder: (context) {
                        final Color cornerColor = detection.isRiceLeafPresent
                            ? (detection.isTooFar ? const Color(0xFFFBBF24) : Colors.greenAccent)
                            : Colors.white.withValues(alpha: 0.7);
                        return Stack(
                          children: [
                            Positioned(top: 0, left: 0, child: _buildCorner(top: true, left: true, color: cornerColor)),
                            Positioned(top: 0, right: 0, child: _buildCorner(top: true, left: false, color: cornerColor)),
                            Positioned(bottom: 0, left: 0, child: _buildCorner(top: false, left: true, color: cornerColor)),
                            Positioned(bottom: 0, right: 0, child: _buildCorner(top: false, left: false, color: cornerColor)),
                          ],
                        );
                      },
                    ),

                    // Laser Scan Line Animasi Vertikal
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: boxHeight * _scanAnimation.value,
                          left: 6,
                          right: 6,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  detection.isTooFar ? const Color(0xFFF59E0B) : AppColors.primaryGreen,
                                  detection.isTooFar ? const Color(0xFFFBBF24) : Colors.greenAccent,
                                  detection.isTooFar ? const Color(0xFFF59E0B) : AppColors.primaryGreen,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (detection.isTooFar ? const Color(0xFFFBBF24) : Colors.greenAccent)
                                      .withValues(alpha: 0.7),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Notifikasi Peringatan: HANYA muncul jika objek daun padi terdeteksi DAN jaraknya terlalu jauh
            if (detection.isRiceLeafPresent && detection.isTooFar)
              Positioned(
                top: (maxH / 2 + boxHeight / 2 + 10).clamp(10.0, maxH - 85),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.9), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.straighten_rounded, color: Color(0xFFFBBF24), size: 15),
                      const SizedBox(width: 6),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Objek Terlalu Jauh",
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            "Dekatkan (15-20 cm) atau gunakan Zoom",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _setZoom(2.0),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                              SizedBox(width: 2),
                              Text(
                                "Zoom 2x",
                                style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Baris Pilihan Cepat Zoom Kamera (1x, 1.5x, 2x, 3x)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [1.0, 1.5, 2.0, 3.0].map((zoomVal) {
                    final bool isSelected = (_currentZoom - zoomVal).abs() < 0.24;
                    return GestureDetector(
                      onTap: () => _setZoom(zoomVal),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "${zoomVal.toStringAsFixed(zoomVal == 1.0 || zoomVal == 2.0 || zoomVal == 3.0 ? 0 : 1)}x",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner({required bool top, required bool left, Color? color}) {
    final cornerColor = color ?? Colors.greenAccent;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: cornerColor, width: 3.5) : BorderSide.none,
          bottom: !top ? BorderSide(color: cornerColor, width: 3.5) : BorderSide.none,
          left: left ? BorderSide(color: cornerColor, width: 3.5) : BorderSide.none,
          right: !left ? BorderSide(color: cornerColor, width: 3.5) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Tips Ringkas & Dismissible
          if (_showTips) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco, color: AppColors.primaryGreen, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Pastikan cahaya cukup dan daun padi fokus tajam.",
                      style: TextStyle(color: Color(0xFF1B5E20), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showTips = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.grey, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Baris Kontrol Kamera Ergonomis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tombol Pilih dari Galeri
              _buildBottomActionButton(
                icon: Icons.photo_library_outlined,
                label: "Galeri",
                onTap: _pickFromGallery,
              ),

              // Tombol Shutter Utama dengan Haptic Ring
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGreen, width: 3.5),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                  ),
                ),
              ),

              // Tombol Ganti / Flip Kamera
              _buildBottomActionButton(
                icon: Icons.flip_camera_ios_outlined,
                label: "Putar",
                onTap: _switchCamera,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(icon, color: AppColors.textDark, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
