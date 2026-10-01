import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';

import '../../utils/app_colors.dart';
import '../../services/gemini_service.dart';
import '../../services/scan_history_service.dart';
import '../../services/weather_service.dart';

class ScanResultScreen extends StatefulWidget {
  final XFile imageFile;
  final int lahanId;
  final int? luxValue;
  final int? plantAgeDays;

  const ScanResultScreen({
    super.key,
    required this.imageFile,
    required this.lahanId,
    this.luxValue,
    this.plantAgeDays,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  final GeminiService _geminiService = GeminiService();
  final ScanHistoryService _scanHistoryService = ScanHistoryService();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  String? _weatherDesc;
  double? _temp;
  int? _humidity;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _analyzeImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    String? weatherDesc;
    double? temp;
    int? humidity;

    // Ambil data lokasi & cuaca non-blocking
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 4),
          );

          final weather = await WeatherService().getCurrentWeather(
            position.latitude,
            position.longitude,
          );

          if (weather != null) {
            weatherDesc = weather.description;
            temp = weather.temperature;
            humidity = weather.humidity;
          }
        }
      }
    } catch (e) {
      debugPrint("Telemetry fetch warning: $e");
    }

    if (mounted) {
      setState(() {
        _weatherDesc = weatherDesc;
        _temp = temp;
        _humidity = humidity;
      });
    }

    try {
      final result = await _geminiService.analyzeLeaf(
        widget.imageFile,
        weather: weatherDesc,
        temperature: temp,
        humidity: humidity,
        lux: widget.luxValue,
        plantAgeDays: widget.plantAgeDays,
      );

      if (!mounted) return;
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const surfaceBg = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: surfaceBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _isLoading
            ? _AgriScannerLoader(imageFile: widget.imageFile)
            : _errorMessage != null
                ? _buildErrorView()
                : _buildMainContent(),
      ),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomActionBar(),
    );
  }

  Widget _buildErrorView() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFEE2E2), width: 2),
                ),
                child: const Icon(
                  Icons.sync_problem_rounded,
                  color: Color(0xFFEF4444),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Gagal Menganalisis",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? "Terjadi kendala saat memproses sampel daun.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _analyzeImage();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    "Ulangi Pemindaian",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBWDPrimaryMetricCard(),
                    const SizedBox(height: 32),
                    _buildSectionTitle("Kondisi Lingkungan", Icons.eco_rounded),
                    const SizedBox(height: 16),
                    _buildModernEnvironmentRow(),
                    const SizedBox(height: 32),
                    _buildSectionTitle("Evaluasi Kesehatan", Icons.health_and_safety_rounded),
                    const SizedBox(height: 16),
                    _buildHealthGrid(),
                    const SizedBox(height: 24),
                    _buildDiagnosisBanner(),
                    const SizedBox(height: 16),
                    _buildActionablePrescription(),
                    const SizedBox(height: 32),
                    _buildSectionTitle("Spesifikasi Analisis", Icons.analytics_rounded),
                    const SizedBox(height: 16),
                    _buildTechnicalSpecsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _BlurredCircleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _BlurredCircleButton(
            icon: Icons.fullscreen_rounded,
            onTap: _openImagePreviewDialog,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'leaf-scan-hero',
              child: kIsWeb
                  ? Image.network(widget.imageFile.path, fit: BoxFit.cover)
                  : Image.file(File(widget.imageFile.path), fit: BoxFit.cover),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF34D399),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Analisis Selesai",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${widget.plantAgeDays ?? '-'} HST",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildBWDPrimaryMetricCard() {
    final bwdRaw = _analysisResult?['bwd_value']?.toString() ?? '3.0';
    final bwdStatus = _analysisResult?['bwd_status'] ?? 'Normal';
    final bwdInterpretation = _analysisResult?['bwd_interpretation'] ??
        'Warna daun berada pada batas toleransi pertumbuhan tanaman.';
    final variety = _analysisResult?['variety'] ?? 'Padi Standar';

    final double numericVal =
        double.tryParse(bwdRaw.replaceAll(',', '.')) ?? 3.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SKALA BWD (BAGAN WARNA DAUN)",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        numericVal.toStringAsFixed(1).replaceAll('.', ','),
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "/ 5.0",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildBadgePill(bwdStatus, _getStatusColor(bwdStatus)),
            ],
          ),
          const SizedBox(height: 20),
          _BwdCustomProgressTrack(value: numericVal),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_rounded,
                  size: 20,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Varietas Teridentifikasi: $variety",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bwdInterpretation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.5,
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
    );
  }

  Widget _buildModernEnvironmentRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _EnvironmentMiniItem(
              label: "Suhu",
              value: _temp != null ? "${_temp!.toStringAsFixed(1)}°C" : "--",
              icon: Icons.device_thermostat_rounded,
              badgeColor: const Color(0xFFEA580C),
            ),
          ),
          _buildVerticalDivider(height: 50),
          Expanded(
            child: _EnvironmentMiniItem(
              label: "Kelembapan",
              value: _humidity != null ? "$_humidity%" : "--",
              icon: Icons.water_drop_rounded,
              badgeColor: const Color(0xFF0284C7),
            ),
          ),
          _buildVerticalDivider(height: 50),
          Expanded(
            child: _EnvironmentMiniItem(
              label: "Cahaya",
              value: widget.luxValue != null ? "${widget.luxValue} lx" : "--",
              icon: Icons.light_mode_rounded,
              badgeColor: const Color(0xFFCA8A04),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthGrid() {
    final nitrogenStatus =
        _analysisResult?['nitrogen_status'] ?? 'Cukup / Optimal';
    final pestSymptoms = _analysisResult?['pest_symptoms'] ?? 'Nihil';
    final diseaseSymptoms = _analysisResult?['disease_symptoms'] ?? 'Nihil';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _HealthListItem(
            icon: Icons.grass_rounded,
            title: "Ketersediaan Nitrogen (N)",
            value: nitrogenStatus,
            statusColor: _getNitrogenColor(nitrogenStatus),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 64),
          _HealthListItem(
            icon: Icons.bug_report_rounded,
            title: "Gejala Hama",
            value: pestSymptoms,
            statusColor: _isNegativeStatus(pestSymptoms)
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 64),
          _HealthListItem(
            icon: Icons.healing_rounded,
            title: "Patogen / Penyakit",
            value: diseaseSymptoms,
            statusColor: _isNegativeStatus(diseaseSymptoms)
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  bool _isNegativeStatus(String val) {
    final clean = val.toLowerCase();
    return clean.contains('nihil') ||
        clean.contains('tidak') ||
        clean.contains('aman') ||
        clean.contains('bersih');
  }

  Widget _buildDiagnosisBanner() {
    final conclusion = _analysisResult?['conclusion'] ??
        'Kondisi tanaman secara umum tergolong stabil dalam pemantauan berkala.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_rounded, color: Color(0xFF15803D), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                "RINGKASAN DIAGNOSIS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            conclusion,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionablePrescription() {
    final recommendation = _analysisResult?['recommendation'] ??
        'Pertahankan pengairan stabil dan jalankan pemupukan sesuai jadwal.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF1D4ED8), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                "REKOMENDASI AGRONOMIS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSpecsCard() {
    final confidence = _analysisResult?['confidence']?.toString() ?? '92';
    final imageQuality = _analysisResult?['image_quality'] ?? 'Baik';
    final lightIntensity = _analysisResult?['light_intensity'] ?? 'Optimal';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildSpecItem("Akurasi Model", "$confidence%", Icons.model_training_rounded)),
          _buildVerticalDivider(height: 40),
          Expanded(child: _buildSpecItem("Kualitas Citra", imageQuality, Icons.high_quality_rounded)),
          _buildVerticalDivider(height: 40),
          Expanded(child: _buildSpecItem("Pencahayaan", lightIntensity, Icons.light_mode_rounded)),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF475569)),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider({required double height}) {
    return Container(
      height: height,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF475569)),
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _handleSaveRecord,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.bookmark_added_rounded, size: 22),
              label: Text(
                _isSaving ? "Menyimpan Data..." : "Simpan Hasil Analisis",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveRecord() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      await _scanHistoryService.submitScan(
        lahanId: widget.lahanId,
        penyakit: _analysisResult?['disease_symptoms'] ?? 'Normal',
        akurasi: double.tryParse(_analysisResult?['confidence']?.toString() ?? '0'),
        tindakan: _analysisResult?['recommendation'],
        imageFile: widget.imageFile,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF0F172A),
          margin: const EdgeInsets.all(16),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 22),
              SizedBox(width: 12),
              Text("Rekam data berhasil disimpan", style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFEF4444),
          margin: const EdgeInsets.all(16),
          content: Text("Gagal menyimpan: $e"),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openImagePreviewDialog() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: kIsWeb
                    ? Image.network(widget.imageFile.path, fit: BoxFit.contain)
                    : Image.file(File(widget.imageFile.path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _BlurredCircleButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'kritis':
      case 'defisiensi':
        return const Color(0xFFEF4444);
      case 'waspada':
      case 'perlu dipupuk':
        return const Color(0xFFF59E0B);
      case 'optimal':
      case 'subur':
      case 'normal':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getNitrogenColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('kurang') || s.contains('defisiensi')) {
      return const Color(0xFFF59E0B);
    }
    if (s.contains('cukup') || s.contains('optimal')) {
      return const Color(0xFF10B981);
    }
    return const Color(0xFF64748B);
  }

  Widget _buildBadgePill(String text, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: baseColor,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SUB-KOMPONEN & WIDGET MODULAR
// -------------------------------------------------------------

class _BlurredCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BlurredCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.black.withOpacity(0.35),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _BwdCustomProgressTrack extends StatelessWidget {
  final double value;

  const _BwdCustomProgressTrack({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double clampedVal = value.clamp(2.0, 5.0);
        final double percent = (clampedVal - 2.0) / 3.0;
        final double trackWidth = constraints.maxWidth;
        const double pointerSize = 24.0;

        return Column(
          children: [
            SizedBox(
              height: 32,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 12,
                    width: trackWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF90C83D), // Level 2
                          Color(0xFF41A43A), // Level 3
                          Color(0xFF236830), // Level 4
                          Color(0xFF194D25), // Level 5
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (percent * (trackWidth - pointerSize))
                        .clamp(0.0, trackWidth - pointerSize),
                    child: Container(
                      width: pointerSize,
                      height: pointerSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0F172A),
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return Text(
                  "Skala ${index + 2}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _EnvironmentMiniItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color badgeColor;

  const _EnvironmentMiniItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor.withOpacity(0.15), width: 1),
          ),
          child: Icon(icon, size: 22, color: badgeColor),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HealthListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color statusColor;

  const _HealthListItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgriScannerLoader extends StatefulWidget {
  final XFile imageFile;
  const _AgriScannerLoader({required this.imageFile});

  @override
  State<_AgriScannerLoader> createState() => _AgriScannerLoaderState();
}

class _AgriScannerLoaderState extends State<_AgriScannerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 260,
              height: 340,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF34D399).withOpacity(0.4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb
                        ? Image.network(widget.imageFile.path, fit: BoxFit.cover)
                        : Image.file(File(widget.imageFile.path), fit: BoxFit.cover),
                    Container(color: const Color(0xFF0F172A).withOpacity(0.4)),
                    AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (context, child) {
                        return Positioned(
                          top: _animCtrl.value * 270,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF34D399).withOpacity(0.0),
                                      const Color(0xFF34D399).withOpacity(0.4),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                height: 3,
                                color: const Color(0xFF34D399),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: CustomPaint(painter: _GridOverlayPainter()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "MEMINDAI SAMPEL DAUN",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: Color(0xFF34D399),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Menghitung klorofil, skala BWD, dan indeks kesehatan...",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final markerPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const len = 16.0;
    canvas.drawPath(Path()..moveTo(0, len)..lineTo(0, 0)..lineTo(len, 0), markerPaint);
    canvas.drawPath(Path()..moveTo(size.width - len, 0)..lineTo(size.width, 0)..lineTo(size.width, len), markerPaint);
    canvas.drawPath(Path()..moveTo(0, size.height - len)..lineTo(0, size.height)..lineTo(len, size.height), markerPaint);
    canvas.drawPath(Path()..moveTo(size.width - len, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - len), markerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}