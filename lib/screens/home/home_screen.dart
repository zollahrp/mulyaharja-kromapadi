import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../scan/scan_screen.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/riwayat_scan_model.dart';
import '../../services/auth_service.dart';
import '../../services/scan_history_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  List<RiwayatScanModel> _recentScans = [];
  int _totalScan = 0;
  int _sehatCount = 0;
  int _beresikoCount = 0;
  int _penyakitCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
        String penyakit = item.penyakit?.toLowerCase() ?? '';
        if (penyakit.contains('sehat') || penyakit.contains('normal')) {
          tSehat++;
        } else if (penyakit.contains('bercak') || penyakit.contains('hawar') || penyakit.contains('tungro') || penyakit.contains('penyakit')) {
          tPenyakit++;
        } else {
          tBeresiko++;
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
      print("Error loading home data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    // Set status bar icons to black
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.bgOffWhite,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with full image and overlay content
                _buildHeader(),

                const SizedBox(height: 16),
                // Banner Section
                _buildBanner(),

                const SizedBox(height: 24),
                // Summary Section
                _buildSummary(),

                const SizedBox(height: 24),
                // Recent Scan History Section
                _buildRecentScans(),

                const SizedBox(height: 24),
                // Insight Section
                _buildInsight(),

                const SizedBox(height: 100), // Padding for the bottom nav bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) {
      return "Selamat Pagi,";
    } else if (hour < 15) {
      return "Selamat Siang,";
    } else if (hour < 18) {
      return "Selamat Sore,";
    }
    return "Selamat Malam,";
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Background Image of rice field and mountains
        Container(
          height: 260,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/header_home.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Content overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 40.0, bottom: 16.0),
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
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7A7E86),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${_user?.name ?? 'Petani'} \uD83C\uDF3F",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B1D2A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _user?.role == 'ketua_kelompok' ? "Ketua Kelompok Tani" : "Anggota Kelompok Tani",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7A7E86),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _user?.kelompokTaniName ?? 'KTD Karet Tengsin',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.notifications_none,
                              size: 28, color: AppColors.textBlack),
                          onPressed: () => _showComingSoon('Fitur Notifikasi'),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Location chip
                InkWell(
                  onTap: () => _showComingSoon('Pilih Lokasi Lahan'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primaryGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _user?.wilayah?.name ?? "Lokasi belum diatur",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down,
                          color: AppColors.primaryGreen.withOpacity(0.8),
                          size: 18),
                    ],
                  ),
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
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        SizedBox(
          width: double.infinity,
          child: Image.asset(
            'assets/images/cta_home.png',
            fit: BoxFit.fitWidth,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 60.0, right: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Scan Daun Padi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: const Text(
                  "Deteksi kondisi daun padi\ndengan cepat dan akurat",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanScreen()),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner,
                      color: AppColors.primaryGreen, size: 20),
                  label: const Text(
                    "Mulai Scan",
                    style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          _buildSectionHeader("Ringkasan", () => _showComingSoon('Laporan Penuh')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Total Scan",
                  "$_totalScan",
                  const Color(0xFFE8F5E9),
                  AppColors.primaryGreen,
                  Icons.document_scanner_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Sehat",
                  "$_sehatCount",
                  const Color(0xFFE8F5E9),
                  const Color(0xFF4CAF50),
                  Icons.verified_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Beresiko",
                  "$_beresikoCount",
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFFA000),
                  Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Penyakit",
                  "$_penyakitCount",
                  const Color(0xFFFFEBEE),
                  const Color(0xFFE53935),
                  Icons.coronavirus_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color bgColor,
      Color iconColor, IconData icon) {
    return InkWell(
      onTap: () => _showComingSoon('Data Statistik: $title'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRecentScans() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          _buildSectionHeader("Riwayat Scan Terbaru", () => _showComingSoon('Semua Riwayat Scan')),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _isLoading 
                ? [
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: AppColors.primaryGreen),
                    )
                  ]
                : _recentScans.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text("Belum ada riwayat scan.", style: TextStyle(color: Colors.grey)),
                    )
                  ]
                : _recentScans.asMap().entries.map((entry) {
                    int idx = entry.key;
                    RiwayatScanModel item = entry.value;

                    // Determine formatting based on status
                    bool isNormal = (item.penyakit?.toLowerCase() == 'normal' || item.penyakit?.toLowerCase() == 'sehat');
                    Color tagColor = isNormal ? AppColors.healthyGreenTag : AppColors.alertRedTag;
                    Color tagTextColor = isNormal ? AppColors.healthyGreenText : AppColors.alertRedText;
                    
                    String formattedDate = "-";
                    if (item.createdAt != null) {
                       try {
                          final dt = DateTime.parse(item.createdAt ?? '').toLocal();
                          formattedDate = DateFormat('dd MMM yyyy • HH:mm').format(dt);
                       } catch (e) {}
                    }

                    return Column(
                      children: [
                        _buildScanItem(
                          item.lahan?.name ?? "Lahan",
                          formattedDate,
                          item.penyakit ?? "-",
                          tagColor,
                          tagTextColor,
                          item.fotoPath ?? '',
                        ),
                        if (idx < _recentScans.length - 1) _buildDivider(),
                      ],
                    );
                  }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(color: Color(0xFFEEEEEE), height: 1),
    );
  }

  Widget _buildScanItem(String title, String date, String status, Color tagColor,
      Color textColor, String imageUrl) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 55,
                    height: 55,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textBlack)),
                  const SizedBox(height: 4),
                  Text(date,
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInsight() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: InkWell(
        onTap: () => _showComingSoon('Baca Selengkapnya Insight'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.insightCardBg,
            borderRadius: BorderRadius.circular(16),
          ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb_outline,
                  color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Insight Hari Ini",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textBlack)),
                  SizedBox(height: 4),
                  Text(
                    "Lakukan pemantauan rutin dan jaga kesehatan tanaman untuk hasil panen yang optimal.",
                    style: TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[500]),
          ],
        ),
        ),
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
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        InkWell(
          onTap: onTap,
          child: const Row(
            children: [
              Text(
                "Lihat Semua",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right,
                  color: AppColors.primaryGreen, size: 16),
            ],
          ),
        ),
      ],
    );
  }

}