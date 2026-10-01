import 'package:flutter/material.dart';
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

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  int _currentCameraIndex = 0;
  final ImagePicker _picker = ImagePicker();

  final LahanService _lahanService = LahanService();
  List<LahanModel> _lahans = [];
  LahanModel? _selectedLahan;
  bool _isLoadingLahan = true;
  bool _isCheckingLocation = true;

  @override
  void initState() {
    super.initState();
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
        _lahans = lahans.where((l) => l.isAktif).toList();
        if (_lahans.isNotEmpty) {
          _selectedLahan = _lahans.first;
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
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
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
          plantAgeDays = DateTime.now().difference(plantingDate).inDays;
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
          lahanId: _selectedLahan?.id ?? 0,
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Scan Daun Padi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                _buildCameraPreview(),
                _buildCameraOverlay(),
                _buildCameraControls(),
              ],
            ),
          ),
          _buildBottomPanel(),
        ],
      ),
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
          ? SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController!),
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  Widget _buildCameraOverlay() {
    return Positioned.fill(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Pastikan daun padi berada\ndalam area kotak",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 250,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _buildCorner(top: true, left: true)),
                  Positioned(top: 0, right: 0, child: _buildCorner(top: true, left: false)),
                  Positioned(bottom: 0, left: 0, child: _buildCorner(top: false, left: true)),
                  Positioned(bottom: 0, right: 0, child: _buildCorner(top: false, left: false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Positioned(
      left: 32,
      top: 100,
      child: Column(
        children: [
          _buildControlButton(
            icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
            label: "Flash",
            onTap: _toggleFlash,
          ),
          const SizedBox(height: 20),
          _buildControlButton(
            icon: Icons.photo_library,
            label: "Galeri",
            onTap: _pickFromGallery,
          ),
          const SizedBox(height: 20),
          _buildControlButton(
            icon: Icons.help_outline,
            label: "Panduan",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tips Pengambilan Gambar",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Ambil gambar daun yang jelas, fokus, dan pastikan cahaya cukup agar hasil analisis lebih akurat.",
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.close, color: Colors.black54, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: _switchCamera,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flip_camera_ios, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text("Ganti Kamera", style: TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGreen, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.document_scanner, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Auto Capture", style: TextStyle(fontSize: 12, color: Colors.black87)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("ON", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
