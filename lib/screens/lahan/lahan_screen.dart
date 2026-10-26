import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../models/lahan_model.dart';
import '../../services/lahan_service.dart';
import '../../services/api_service.dart';
import '../../widgets/image_zoom_viewer.dart';
import '../scan/scan_screen.dart';

class LahanScreen extends StatefulWidget {
  const LahanScreen({super.key});

  @override
  State<LahanScreen> createState() => _LahanScreenState();
}

class _LahanScreenState extends State<LahanScreen> with SingleTickerProviderStateMixin {
  late Future<List<LahanModel>> _lahanFuture;
  late AnimationController _shimmerController;
  
  String _searchQuery = "";
  String _selectedFilter = "Semua"; // "Semua", "Vegetatif", "Reproduktif", "Pematangan", "Siap Panen", "Non-Aktif"
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    "Semua",
    "Vegetatif (0-30 HST)",
    "Reproduktif (31-65 HST)",
    "Pematangan (66-90 HST)",
    "Siap Panen (>90 HST)",
    "Non-Aktif",
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _lahanFuture = LahanService().getLahan();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _lahanFuture = LahanService().getLahan();
    });
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return ApiService.getStorageUrl(path);
  }

  List<LahanModel> _filterLahan(List<LahanModel> list) {
    return list.where((lahan) {
      final matchesSearch = _searchQuery.isEmpty ||
          lahan.name.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      final hst = lahan.hst ?? 0;
      final isAktif = lahan.isAktif;

      switch (_selectedFilter) {
        case "Vegetatif (0-30 HST)":
          return isAktif && hst <= 30;
        case "Reproduktif (31-65 HST)":
          return isAktif && hst > 30 && hst <= 65;
        case "Pematangan (66-90 HST)":
          return isAktif && hst > 65 && hst <= 90;
        case "Siap Panen (>90 HST)":
          return isAktif && hst > 90;
        case "Non-Aktif":
          return !isAktif;
        case "Semua":
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.primaryGreen,
          backgroundColor: Colors.white,
          child: FutureBuilder<List<LahanModel>>(
            future: _lahanFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingSkeleton();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final allLahan = snapshot.data ?? [];
              final filteredLahan = _filterLahan(allLahan);

              final totalLahan = allLahan.length;
              final double totalLuasM2 = allLahan.fold(0.0, (sum, item) => sum + (item.luas ?? 0));
              final double totalLuasHa = totalLuasM2 / 10000;
              final totalSiapPanen = allLahan.where((l) => l.isAktif && (l.hst ?? 0) > 90).length;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // 1. Hero Header
                  SliverToBoxAdapter(
                    child: _buildHeader(),
                  ),

                  // 2. Summary Dashboard Cards
                  SliverToBoxAdapter(
                    child: _buildSummaryWidgets(
                      totalLahan: totalLahan,
                      totalLuasHa: totalLuasHa,
                      totalLuasM2: totalLuasM2,
                      totalSiapPanen: totalSiapPanen,
                    ),
                  ),

                  // 3. Search and Category Filter
                  SliverToBoxAdapter(
                    child: _buildSearchAndFilters(allLahan.length, filteredLahan.length),
                  ),

                  // 4. Lahan Cards List or Empty Search
                  if (filteredLahan.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyState(isSearchResult: allLahan.isNotEmpty),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _buildLahanCard(filteredLahan[index]),
                            );
                          },
                          childCount: filteredLahan.length,
                        ),
                      ),
                    ),

                  // Extra bottom padding for floating navigation bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 110),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grass_rounded, size: 13, color: AppColors.primaryGreen),
                          SizedBox(width: 5),
                          Text(
                            "Kelompok Tani Mulyaharja",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Lahan Pertanian",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF142B1A),
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Pantau pertumbuhan tanaman padi & jadwal perawatan",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Brand Emblem Pill
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFE8F5E9), width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFF1F8E9),
              child: Image.asset(
                'assets/images/logo-mark.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.eco,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATS SUMMARY DASHBOARD ---
  Widget _buildSummaryWidgets({
    required int totalLahan,
    required double totalLuasHa,
    required double totalLuasM2,
    required int totalSiapPanen,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
      child: Row(
        children: [
          // Total Petak
          Expanded(
            child: _buildMetricCard(
              title: "Total Lahan",
              value: "$totalLahan",
              unit: "Petak",
              icon: Icons.landscape_rounded,
              startColor: const Color(0xFF1B5E20),
              endColor: const Color(0xFF2E7D32),
              textColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          // Total Luas
          Expanded(
            child: _buildMetricCard(
              title: "Total Luas",
              value: totalLuasHa >= 1.0 ? totalLuasHa.toStringAsFixed(2) : totalLuasM2.toInt().toString(),
              unit: totalLuasHa >= 1.0 ? "Hektar" : "m²",
              icon: Icons.straighten_rounded,
              startColor: const Color(0xFF0F766E),
              endColor: const Color(0xFF14B8A6),
              textColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          // Siap Panen
          Expanded(
            child: _buildMetricCard(
              title: "Siap Panen",
              value: "$totalSiapPanen",
              unit: "Petak",
              icon: Icons.military_tech_rounded,
              startColor: const Color(0xFFB45309),
              endColor: const Color(0xFFF59E0B),
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color startColor,
    required Color endColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: startColor.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.88),
                ),
              ),
              Icon(icon, color: textColor.withValues(alpha: 0.9), size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SEARCH AND FILTER PILLS ---
  Widget _buildSearchAndFilters(int totalOriginal, int totalFiltered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF142B1A)),
              decoration: InputDecoration(
                hintText: "Cari nama petak sawah...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGreen, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Filter Chips Horizontal Scroll
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1B5E20) : Colors.black.withValues(alpha: 0.07),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // --- LAHAN CARD DESIGN ---
  Widget _buildLahanCard(LahanModel lahan) {
    final double luasM2 = (lahan.luas ?? 0).toDouble();
    final double luasHa = luasM2 / 10000;
    final int hst = lahan.hst ?? 0;
    final bool isAktif = lahan.isAktif;
    final imageUrl = _getFullImageUrl(lahan.fotoPath);

    // Hitung fase pertumbuhan padi berdasarkan HST standar
    String faseTitle;
    String faseDesc;
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;

    if (!isAktif) {
      faseTitle = "Tidak Aktif";
      faseDesc = "Petak belum masuk musim tanam";
      statusBgColor = Colors.grey[200]!;
      statusTextColor = Colors.grey[700]!;
      statusIcon = Icons.pause_circle_outline_rounded;
    } else if (hst > 90) {
      faseTitle = "Siap Panen";
      faseDesc = "Fase Pematangan Akhir (>90 HST)";
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFF92400E);
      statusIcon = Icons.military_tech_rounded;
    } else if (hst > 65) {
      faseTitle = "Pengisian Bulir";
      faseDesc = "Fase Pematangan (66-90 HST)";
      statusBgColor = const Color(0xFFE0F2FE);
      statusTextColor = const Color(0xFF0369A1);
      statusIcon = Icons.grain_rounded;
    } else if (hst > 30) {
      faseTitle = "Pembentukan Malai";
      faseDesc = "Fase Reproduktif (31-65 HST)";
      statusBgColor = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF166534);
      statusIcon = Icons.spa_rounded;
    } else {
      faseTitle = "Pertumbuhan Awal";
      faseDesc = "Fase Vegetatif (0-30 HST)";
      statusBgColor = const Color(0xFFF0FDF4);
      statusTextColor = const Color(0xFF15803D);
      statusIcon = Icons.eco_rounded;
    }

    double cycleProgress = isAktif ? (hst / 110.0).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142B1A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Photo Hero Container with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: AspectRatio(
                  aspectRatio: 16 / 8.5,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildLahanPlaceholder(),
                        )
                      : _buildLahanPlaceholder(),
                ),
              ),

              // Gradient Overlay for badge contrast
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Left: Status Chip
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBgColor.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusTextColor),
                      const SizedBox(width: 4),
                      Text(
                        faseTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Right: Luas Badge (Glassmorphic)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.square_foot_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        luasHa >= 1.0 ? "${luasHa.toStringAsFixed(2)} Ha" : "${luasM2.toInt()} m²",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Right: Zoom Photo Preview Action (if image available)
              if (imageUrl.isNotEmpty)
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: InkWell(
                    onTap: () {
                      ImageZoomViewer.show(
                        context,
                        imageUrl: imageUrl,
                        title: lahan.name,
                        subtitle: "Luas: ${luasHa.toStringAsFixed(2)} Ha • $faseTitle",
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text("Lihat Foto", style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // 2. Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lahan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF142B1A),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      "Mulyaharja, Bogor Selatan",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Quick Spec Pills
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                  ),
                  child: Row(
                    children: [
                      // Usia HST
                      Expanded(
                        child: _buildSpecItem(
                          label: "Usia Padi",
                          value: isAktif ? "$hst HST" : "-",
                          icon: Icons.calendar_today_rounded,
                          accentColor: AppColors.primaryGreen,
                        ),
                      ),
                      Container(width: 1, height: 28, color: Colors.grey[200]),
                      // Tanggal Tanam
                      Expanded(
                        child: _buildSpecItem(
                          label: "Mulai Tanam",
                          value: _formatTanggalTanam(lahan.tanggalTanam),
                          icon: Icons.event_available_rounded,
                          accentColor: const Color(0xFF0F766E),
                        ),
                      ),
                      Container(width: 1, height: 28, color: Colors.grey[200]),
                      // Status Lahan
                      Expanded(
                        child: _buildSpecItem(
                          label: "Kondisi",
                          value: isAktif ? "Budidaya" : "Rehat",
                          icon: Icons.spa_rounded,
                          accentColor: isAktif ? const Color(0xFF15803D) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Growth Cycle Progress Bar
                if (isAktif) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        faseDesc,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        "${(cycleProgress * 100).toInt()}% Masa Tanam",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 7,
                      child: LinearProgressIndicator(
                        value: cycleProgress,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          hst > 90 ? const Color(0xFFF59E0B) : AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 12),

                // Action Buttons Row: Detail Lahan & Pindai AI
                Row(
                  children: [
                    // Detail Petak Button
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLahanDetailModal(lahan),
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text("Rincian Petak"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFFC8E6C9), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pindai Daun Button
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ScanScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                        label: const Text("Pindai Daun"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: accentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF142B1A),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatTanggalTanam(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  // --- DETAIL MODAL BOTTOM SHEET ---
  void _showLahanDetailModal(LahanModel lahan) {
    final double luasM2 = (lahan.luas ?? 0).toDouble();
    final double luasHa = luasM2 / 10000;
    final int hst = lahan.hst ?? 0;
    final imageUrl = _getFullImageUrl(lahan.fotoPath);

    // Rekomendasi agrikultur spesifik berdasarkan HST
    String rekomendasiJudul;
    String rekomendasiIsi;
    IconData rekomendasiIcon;
    Color rekomendasiColor;

    if (!lahan.isAktif) {
      rekomendasiJudul = "Persiapan Olah Tanah";
      rekomendasiIsi = "Lakukan pembajakan, perataan tanah, dan pemupukan kandang/kompos dasar sebelum bibit disemai.";
      rekomendasiIcon = Icons.agriculture_rounded;
      rekomendasiColor = Colors.grey[700]!;
    } else if (hst > 90) {
      rekomendasiJudul = "Persiapan Panen Padi";
      rekomendasiIsi = "Keringkan parit lahan sawah 7–10 hari sebelum panen. Pastikan 90-95% bulir padi telah menguning sempurna.";
      rekomendasiIcon = Icons.military_tech_rounded;
      rekomendasiColor = const Color(0xFFD97706);
    } else if (hst > 65) {
      rekomendasiJudul = "Fase Pengisian Bulir";
      rekomendasiIsi = "Jaga ketersediaan air macak-macak. Awasi serangan hama walang sangit dan penyakit blas leher malai.";
      rekomendasiIcon = Icons.grain_rounded;
      rekomendasiColor = const Color(0xFF0284C7);
    } else if (hst > 30) {
      rekomendasiJudul = "Pemupukan Susulan & Pengairan";
      rekomendasiIsi = "Berikan pupuk susulan kedua (Urea & NPK). Rutin periksa warna daun menggunakan fitur AI Bagan Warna Daun (BWD).";
      rekomendasiIcon = Icons.water_drop_rounded;
      rekomendasiColor = AppColors.primaryGreen;
    } else {
      rekomendasiJudul = "Penyiangan Gulma & Pemupukan Dasar";
      rekomendasiIsi = "Bersihkan gulma pengganggu di sekitar anakan padi. Pantau keong mas dan gunakan pemupukan nitrogen terukur.";
      rekomendasiIcon = Icons.eco_rounded;
      rekomendasiColor = const Color(0xFF16A34A);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Photo (if exists) or Badge
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildLahanPlaceholder(),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 12,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ImageZoomViewer.show(
                                context,
                                imageUrl: imageUrl,
                                title: lahan.name,
                              );
                            },
                            icon: const Icon(Icons.fullscreen_rounded, size: 16),
                            label: const Text("Perbesar Foto"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.65),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lahan.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF142B1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: lahan.isAktif ? const Color(0xFFE8F5E9) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        lahan.isAktif ? "Kondisi Aktif" : "Non-Aktif",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: lahan.isAktif ? const Color(0xFF1B5E20) : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      "Wilayah Desa Mulyaharja, Bogor Selatan",
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Grid Detail Informasi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.square_foot_rounded,
                        label: "Luas Petak",
                        value: "${luasM2.toInt()} m² (${luasHa.toStringAsFixed(2)} Ha)",
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        icon: Icons.event_available_rounded,
                        label: "Tanggal Tanam",
                        value: _formatTanggalTanam(lahan.tanggalTanam),
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: "Umur Tanaman",
                        value: lahan.isAktif ? "$hst HST (Hari Setelah Tanam)" : "-",
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        icon: Icons.timelapse_rounded,
                        label: "Estimasi Panen",
                        value: lahan.isAktif && lahan.tanggalTanam != null
                            ? _calculateEstimasiPanen(lahan.tanggalTanam)
                            : "-",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Rekomendasi Pertanian Berdasarkan HST
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: rekomendasiColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: rekomendasiColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: rekomendasiColor.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(rekomendasiIcon, color: rekomendasiColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rekomendasiJudul,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: rekomendasiColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rekomendasiIsi,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ScanScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                        label: const Text("Pindai Kesehatan Daun"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF142B1A),
          ),
        ),
      ],
    );
  }

  String _calculateEstimasiPanen(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      final plantDate = DateTime.parse(dateStr);
      final harvestDate = plantDate.add(const Duration(days: 110));
      return DateFormat('d MMMM yyyy').format(harvestDate);
    } catch (_) {
      return "-";
    }
  }

  // --- EMPTY & ERROR STATES ---
  Widget _buildEmptyState({required bool isSearchResult}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearchResult ? Icons.search_off_rounded : Icons.landscape_rounded,
                  size: 44,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSearchResult ? "Petak Tidak Ditemukan" : "Belum Ada Lahan Terdaftar",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF142B1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSearchResult
                    ? "Coba kata kunci pencarian lain atau pilih filter yang berbeda."
                    : "Lahan pertanian yang didaftarkan oleh kelompok tani akan muncul di sini.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              if (isSearchResult) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                      _selectedFilter = "Semua";
                    });
                  },
                  child: const Text("Reset Pencarian & Filter"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.redAccent),
            const SizedBox(height: 14),
            const Text(
              "Gagal Memuat Data Lahan",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SKELETON SHIMMER LOADER ---
  Widget _buildLoadingSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: 140, height: 20, borderRadius: 6),
              const SizedBox(height: 8),
              _buildShimmerBox(width: 220, height: 28, borderRadius: 8),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(width: double.infinity, height: 75, borderRadius: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShimmerBox(width: double.infinity, height: 75, borderRadius: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShimmerBox(width: double.infinity, height: 75, borderRadius: 16)),
                ],
              ),
              const SizedBox(height: 18),
              _buildShimmerBox(width: double.infinity, height: 46, borderRadius: 16),
              const SizedBox(height: 20),
              _buildShimmerBox(width: double.infinity, height: 260, borderRadius: 22),
              const SizedBox(height: 16),
              _buildShimmerBox(width: double.infinity, height: 260, borderRadius: 22),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({required double width, required double height, required double borderRadius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
          stops: [
            (_shimmerController.value - 0.3).clamp(0.0, 1.0),
            _shimmerController.value,
            (_shimmerController.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLahanPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF43A047),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.landscape_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Petak Sawah PadiNexa",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
