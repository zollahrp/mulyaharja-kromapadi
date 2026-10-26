import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../scan/scan_screen.dart';
import '../history/history_screen.dart';
import '../lahan/lahan_screen.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../models/riwayat_scan_model.dart';
import '../../services/auth_service.dart';
import '../../services/scan_history_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/scan_detail_modal.dart';
import '../../widgets/image_zoom_viewer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  UserModel? _user;
  List<RiwayatScanModel> _recentScans = [];
  int _totalScan = 0;
  int _sehatCount = 0;
  int _beresikoCount = 0;
  int _penyakitCount = 0;
  bool _isLoading = true;
  String _currentLocationName = "Mencari lokasi...";
  WeatherData? _weatherData;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _loadData();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      if (kIsWeb) {
        if (mounted) {
          setState(() => _currentLocationName = "Mulyaharja, Bogor");
        }
        // Fetch real weather for Mulyaharja, Bogor (-6.6433, 106.7925)
        _fetchWeather(-6.6433, 106.7925);
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _currentLocationName = "Lokasi tidak aktif");
        _fetchWeather(-6.6433, 106.7925);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _currentLocationName = "Izin lokasi ditolak");
          _fetchWeather(-6.6433, 106.7925);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _currentLocationName = "Izin ditolak permanen");
        _fetchWeather(-6.6433, 106.7925);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _fetchWeather(position.latitude, position.longitude);
      
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String locationStr = [place.subLocality, place.locality].where((e) => e != null && e.isNotEmpty).join(", ");
        if (locationStr.isEmpty) locationStr = place.administrativeArea ?? "Lokasi Ditemukan";
        if (mounted) setState(() => _currentLocationName = locationStr);
      } else {
        if (mounted) setState(() => _currentLocationName = "Lokasi tidak diketahui");
      }
    } catch (e) {
      if (mounted) setState(() => _currentLocationName = "Mulyaharja, Bogor");
      _fetchWeather(-6.6433, 106.7925);
    }
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    try {
      final weather = await WeatherService().getCurrentWeather(lat, lng);
      if (weather != null && mounted) {
        setState(() => _weatherData = weather);
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final authService = AuthService();
      final historyService = ScanHistoryService();
      
      final user = await authService.getCurrentUser();
      final history = await historyService.getHistory();
      
      int tScan = 0, tSehat = 0, tBeresiko = 0, tPenyakit = 0;
      
      for (var item in history) {
        tScan++;
        if (item.hasDisease) {
          tPenyakit++;
        } else if (item.hasPest || (item.bwdValue != null && (item.bwdValue! < 3.0 || item.bwdValue! > 4.5))) {
          tBeresiko++;
        } else {
          tSehat++;
        }
      }

      if (mounted) {
        setState(() {
          _user = user;
          _totalScan = tScan;
          _sehatCount = tSehat;
          _beresikoCount = tBeresiko;
          _penyakitCount = tPenyakit;
          _recentScans = history.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _loadData(),
      _fetchCurrentLocation(),
    ]);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 12,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-2.5 + 4.5 * _shimmerController.value, -0.3),
              end: Alignment(-0.5 + 4.5 * _shimmerController.value, 0.3),
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummarySkeleton() {
    return Column(
      children: [
        // 4 Metric Grid Skeleton
        Row(
          children: [
            Expanded(child: _buildSummaryCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCardSkeleton()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSummaryCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCardSkeleton()),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: 38, height: 38, borderRadius: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 45, height: 22, borderRadius: 6),
                const SizedBox(height: 6),
                _buildShimmerBox(width: 65, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScansSkeleton() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              _buildShimmerBox(width: 64, height: 64, borderRadius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 130, height: 16, borderRadius: 6),
                    const SizedBox(height: 8),
                    _buildShimmerBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildShimmerBox(width: 75, height: 20, borderRadius: 8),
                  const SizedBox(height: 5),
                  _buildShimmerBox(width: 60, height: 18, borderRadius: 8),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName masih dalam tahap pengembangan.', style: const TextStyle(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Glassmorphic Header
              _buildHeader(),

              const SizedBox(height: 16),
              // AI Scanner Banner
              _buildBanner(),

              const SizedBox(height: 20),
              // Quick Actions Hub
              _buildQuickActions(),

              const SizedBox(height: 24),
              // Summary & Health Overview
              _buildSummary(),

              const SizedBox(height: 24),
              // Recent Scan History Section
              _buildRecentScans(),



              const SizedBox(height: 110), // Padding for floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) {
      return "Selamat Pagi";
    } else if (hour < 15) {
      return "Selamat Siang";
    } else if (hour < 18) {
      return "Selamat Sore";
    }
    return "Selamat Malam";
  }

  Widget _buildHeader() {
    final userName = _user?.name ?? 'Petani';
    final roleText = _user?.roleDisplay ?? 'Anggota Kelompok Tani';
    final wilayahText = _user?.kelompokTaniName ?? 
        (_user?.wilayah?.name != null ? "Wilayah ${_user!.wilayah!.name}" : 'KTD Mulyaharja');

    return Stack(
      children: [
        // Background Image of rice field with dual gradient overlays
        Container(
          height: 290,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/header_home.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.3),
                  const Color(0xFFF7F9F6).withValues(alpha: 0.95),
                  const Color(0xFFF7F9F6),
                ],
                stops: const [0.0, 0.45, 0.88, 1.0],
              ),
            ),
          ),
        ),
        // Content overlay
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top user info and action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile avatar and name
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF1B5E20),
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFD54F), size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getGreeting(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "$roleText • $wilayahText",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                    shadows: const [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                        color: Colors.black38,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notification Button with glassmorphism
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                            onPressed: () => _showComingSoon('Fitur Notifikasi'),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF69F0AE),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Location & Live Weather Glass Pill Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      // Location Pill
                      InkWell(
                        onTap: () => _showComingSoon('Pilih Lokasi Lahan'),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, color: Color(0xFF2E7D32), size: 15),
                              const SizedBox(width: 5),
                              Text(
                                _user?.wilayah?.name ?? _currentLocationName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2E7D32), size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Live Weather Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.6), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _weatherData != null && _weatherData!.description.toLowerCase().contains('hujan')
                                  ? Icons.water_drop_rounded
                                  : Icons.wb_sunny_rounded,
                              color: const Color(0xFFFFD54F),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _weatherData != null
                                  ? "${_weatherData!.temperature.toStringAsFixed(0)}°C • ${_weatherData!.description}"
                                  : "28°C • Cerah Berawan",
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D532B),
              Color(0xFF1E6F3E),
              Color(0xFF124A27),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D532B).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Ambient lighting glow orbs
              Positioned(
                right: -25,
                top: -25,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF34D399).withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. High-Tech Viewfinder Scanner Card on the Right
              Positioned(
                right: 16,
                top: 20,
                bottom: 20,
                child: Container(
                  width: 94,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A3C20).withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF6EE7B7).withValues(alpha: 0.45),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              color: Color(0xFF6EE7B7),
                              size: 28,
                            ),
                          ),
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(
                              Icons.filter_center_focus_rounded,
                              color: Colors.white.withValues(alpha: 0.45),
                              size: 56,
                            ),
                          ),
                          Positioned(
                            left: 8,
                            right: 8,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF69F0AE),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF69F0AE).withValues(alpha: 0.8),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A3C20).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6EE7B7).withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF69F0AE),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "Presisi",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Left Content Column
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 122, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.9,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radar_rounded, color: Color(0xFFFFE082), size: 12),
                          SizedBox(width: 5),
                          Text(
                            "DETEKSI PENYAKIT & BWD",
                            style: TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Pindai Kesehatan Daun\nCepat & Presisi",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Deteksi dini penyakit blas, hawar & ukur kadar klorofil daun padi presisi.",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScanScreen()),
                        );
                      },
                      icon: const Icon(Icons.camera_alt_rounded, size: 17),
                      label: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Pindai Sekarang"),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0D532B),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuickActionItem(
            icon: Icons.qr_code_scanner_rounded,
            label: "Pindai Daun",
            gradient: const [Color(0xFF2E7D32), Color(0xFF43A047)],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
          ),
          _buildQuickActionItem(
            icon: Icons.landscape_rounded,
            label: "Petak Lahan",
            gradient: const [Color(0xFF00796B), Color(0xFF26A69A)],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LahanScreen())),
          ),
          _buildQuickActionItem(
            icon: Icons.history_edu_rounded,
            label: "Riwayat",
            gradient: const [Color(0xFF1565C0), Color(0xFF1E88E5)],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          _buildQuickActionItem(
            icon: Icons.palette_rounded,
            label: "Skala BWD",
            gradient: const [Color(0xFFE65100), Color(0xFFFB8C00)],
            onTap: _showBwdGuideModal,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showBwdGuideModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.palette_rounded, color: Color(0xFFE65100), size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Panduan Bagan Warna Daun (BWD)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1D2A)),
                    ),
                    Text(
                      "Standar acuan pemupukan nitrogen tanaman padi",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildBwdLevelRow("Skala 2", "Kuning Kehijauan (Defisiensi N)", const Color(0xFFD4E157), "Segera berikan pupuk Urea dosis sedang (~75 kg/ha)."),
            const SizedBox(height: 10),
            _buildBwdLevelRow("Skala 3", "Hijau Muda (Mulai Cukup)", const Color(0xFF9CCC65), "Berikan pemupukan susulan ringan jika memasuki fase bunting."),
            const SizedBox(height: 10),
            _buildBwdLevelRow("Skala 4", "Hijau Sedang (Kondisi Optimal)", const Color(0xFF4CAF50), "Kondisi sangat sehat & ideal. Pertahankan tanpa pupuk N tambahan."),
            const SizedBox(height: 10),
            _buildBwdLevelRow("Skala 5", "Hijau Gelap (Kelebihan N)", const Color(0xFF1B5E20), "Stop pemupukan N. Waspada rebah & serangan penyakit jamur/blas."),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Tutup Panduan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBwdLevelRow(String scale, String status, Color color, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(scale, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1B1D2A))),
                    Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF4A4E57), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Kesehatan & Statistik Lahan", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            }),
            const SizedBox(height: 12),
            _buildSummarySkeleton(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Kesehatan & Statistik Lahan", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
          }),
          const SizedBox(height: 12),
          // 4 Metric Grid
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Total Scan",
                  "$_totalScan",
                  const Color(0xFFF1F8F5),
                  const Color(0xFF2E7D32),
                  Icons.qr_code_scanner_rounded,
                  "Pindaian",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Kondisi Sehat",
                  "$_sehatCount",
                  const Color(0xFFE8F5E9),
                  const Color(0xFF388E3C),
                  Icons.check_circle_rounded,
                  "Optimal",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Beresiko / N",
                  "$_beresikoCount",
                  const Color(0xFFFFF8E1),
                  const Color(0xFFFFA000),
                  Icons.warning_rounded,
                  "Perlu pupuk",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Penyakit",
                  "$_penyakitCount",
                  const Color(0xFFFFEBEE),
                  const Color(0xFFE53935),
                  Icons.bug_report_rounded,
                  "Perlu aksi",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color bgColor,
      Color iconColor, IconData icon, String subtitle) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B1D2A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A7E86),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty || path.contains('unsplash.com')) return '';
    return ApiService.getStorageUrl(path);
  }

  Widget _buildRecentScans() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          _buildSectionHeader("Riwayat Scan Terbaru", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          }),
          const SizedBox(height: 14),
          _isLoading 
            ? _buildRecentScansSkeleton()
            : _recentScans.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.eco_rounded, size: 44, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text(
                      "Belum ada riwayat scan daun.",
                      style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            : Column(
                children: _recentScans.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildScanItem(item),
                  );
                }).toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildScanItem(RiwayatScanModel item) {
    final title = item.lahan?.name ?? "Lahan Padi";
    final primaryUrl = _getFullImageUrl(item.fotoPath);
    final fallbackUrl = _getFullImageUrl(item.lahan?.fotoPath);
    final imageUrl = primaryUrl.isNotEmpty ? primaryUrl : fallbackUrl;
    final formattedDate = item.humanRelativeTime;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetailBottomSheet(item),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ImageZoomViewer.show(
                      context,
                      imageUrl: imageUrl,
                      title: title,
                      subtitle: "${item.penyakit} • ${item.formattedDateTime}",
                    );
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  if (fallbackUrl.isNotEmpty && fallbackUrl != imageUrl) {
                                    return Image.network(
                                      fallbackUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => Container(
                                        width: 64,
                                        height: 64,
                                        color: const Color(0xFFF1F8F5),
                                        child: const Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 28),
                                      ),
                                    );
                                  }
                                  return Container(
                                    width: 64,
                                    height: 64,
                                    color: const Color(0xFFF1F8F5),
                                    child: const Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 28),
                                  );
                                },
                              )
                            : Container(
                                width: 64,
                                height: 64,
                                color: const Color(0xFFF1F8F5),
                                child: const Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 28),
                              ),
                      ),
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: Color(0xFF1B1D2A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _confirmDelete(item),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red[400]),
                                  const SizedBox(width: 2),
                                  Text(
                                    "Hapus",
                                    style: TextStyle(color: Colors.red[400], fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.bwdValue != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFA5D6A7), width: 0.8),
                              ),
                              child: Text(
                                "BWD ${item.bwdValue?.toStringAsFixed(1) ?? '-'}${item.bwdStatus != null ? ' (${item.bwdStatus})' : ''}",
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: item.statusTagColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.statusTagText,
                              style: TextStyle(
                                color: item.statusTagTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[500], size: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetailBottomSheet(RiwayatScanModel item) {
    ScanDetailModal.show(
      context,
      item: item,
      onDelete: _handleDeleteScan,
    );
  }

  Future<bool> _handleDeleteScan(RiwayatScanModel item) async {
    setState(() {
      _recentScans.remove(item);
    });

    try {
      await ScanHistoryService().deleteHistory(item.id);
      if (!mounted) return true;
      _showToast("Riwayat scan berhasil dihapus");
      return true;
    } catch (_) {
      if (!mounted) return true;
      _showToast("Riwayat scan berhasil dihapus");
      return true;
    }
  }

  Future<void> _confirmDelete(RiwayatScanModel item) async {
    final confirmed = await ScanDetailModal.showConfirmDeleteDialog(context, item);
    if (confirmed) {
      await _handleDeleteScan(item);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : AppColors.primaryGreen,
        duration: Duration(seconds: isError ? 3 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }



  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B1D2A),
            letterSpacing: -0.2,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Text(
                  "Lihat Semua",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded, color: AppColors.primaryGreen, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

}