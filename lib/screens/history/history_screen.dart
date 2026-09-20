import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/scan_history_service.dart';
import '../../models/riwayat_scan_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["Semua", "Hari Ini", "7 Hari", "30 Hari", "Kustom"];

  final ScanHistoryService _historyService = ScanHistoryService();
  List<RiwayatScanModel> _riwayatList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await _historyService.getHistory();
      if (!mounted) return;
      setState(() {
        _riwayatList = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: AppColors.bgOffWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildSummarySection(),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                        : _errorMessage != null
                            ? Center(child: Text('Gagal memuat: $_errorMessage'))
                            : _buildHistoryList(),
                    const SizedBox(height: 16),
                    _buildInsightCard(),
                    const SizedBox(height: 24),
                    _buildPagination(),
                    const SizedBox(height: 100), // padding for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Riwayat Scan",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Lihat riwayat hasil scan daun padi Anda.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _showComingSoon('Ekspor Data'),
            child: const Row(
              children: [
                Icon(Icons.download, color: AppColors.primaryGreen, size: 18),
                SizedBox(width: 4),
                Text(
                  "Ekspor",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Cari varietas, tanggal, atau lokasi...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _showComingSoon('Filter Lanjutan'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreen),
              ),
              alignment: Alignment.center,
              child: const Row(
                children: [
                  Icon(Icons.filter_list, color: AppColors.primaryGreen, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Filter",
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            bool isSelected = index == _selectedFilterIndex;
            bool hasIcon = index == 0 || index == 1 || index == 4;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGreen : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    if (hasIcon)
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    if (hasIcon) const SizedBox(width: 6),
                    Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ringkasan Riwayat",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.eco,
                  iconColor: AppColors.primaryGreen,
                  title: "Total Scan",
                  value: "28",
                  subtitle: "Kali",
                  subtitleColor: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.energy_savings_leaf,
                  iconColor: AppColors.warningOrangeText,
                  title: "Rata-rata BWD",
                  value: "2,8",
                  subtitle: "Relatif Rendah",
                  subtitleColor: AppColors.warningOrangeText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.shield,
                  iconColor: AppColors.primaryGreen,
                  title: "Scan Normal",
                  value: "12",
                  subtitle: "43%",
                  subtitleColor: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.shield,
                  iconColor: AppColors.alertRedText,
                  title: "Scan Abnormal",
                  value: "16",
                  subtitle: "57%",
                  subtitleColor: AppColors.alertRedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Daftar Riwayat",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              Row(
                children: [
                  Text("Urutkan: Terbaru", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _riwayatList.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text("Belum ada riwayat scan")),
                )
              : Column(
                  children: _riwayatList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    
                    bool isNormal = item.penyakit.toLowerCase() == 'normal' || item.penyakit.isEmpty;
                    Color tagColor = isNormal ? AppColors.healthyGreenTag : AppColors.alertRedTag;
                    Color tagTextColor = isNormal ? AppColors.healthyGreenText : AppColors.alertRedText;
                    
                    final widget = _buildHistoryItem(
                      variety: (item.lahan?.hst != null) ? "${item.lahan?.hst} HST" : "-",
                      bwd: "Akurasi: ${item.akurasi ?? '-'}",
                      date: item.createdAt,
                      time: "",
                      location: item.lahan?.name ?? "-",
                      phase: item.penyakit,
                      weather: "",
                      tagText: isNormal ? "Sehat" : "Penyakit",
                      tagColor: tagColor,
                      tagTextColor: tagTextColor,
                      statusText: "Tindakan: ${item.tindakan ?? '-'}",
                      imageUrl: item.fotoPath ?? '', // If empty, errorBuilder will show placeholder
                    );

                    if (index == _riwayatList.length - 1) {
                      return widget;
                    }
                    return Column(
                      children: [
                        widget,
                        _buildDivider(),
                      ],
                    );
                  }).toList(),
                ),
          ),
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

  Widget _buildHistoryItem({
    required String variety,
    required String bwd,
    required String date,
    required String time,
    required String location,
    required String phase,
    required String weather,
    required String tagText,
    required Color tagColor,
    required Color tagTextColor,
    required String statusText,
    required String imageUrl,
  }) {
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
                    "Daun Padi • $variety",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$date • $time\n$location • $phase • $weather",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tagText,
                          style: TextStyle(color: tagTextColor, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daun Padi • $variety",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textBlack),
                ),
                const SizedBox(height: 6),
                Text(
                  "$bwd • $date • $time",
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(location, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_view_day, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(phase, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Icons.wb_sunny_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(weather, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tagText,
                          style: TextStyle(color: tagTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInsightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.insightCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.show_chart, color: AppColors.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Pantau riwayat secara rutin untuk menjaga kesehatan tanaman padi Anda.",
                style: TextStyle(fontSize: 11, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showComingSoon('Lihat Detail Analisis'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryGreen),
                ),
                child: const Row(
                  children: [
                    Text("Lihat Analisis", style: TextStyle(color: AppColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: AppColors.primaryGreen, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Menampilkan ${_riwayatList.isEmpty ? 0 : 1}-${_riwayatList.length > 5 ? 5 : _riwayatList.length} dari ${_riwayatList.length} data",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          InkWell(
            onTap: () => _showComingSoon('Pindah Halaman'),
            child: Row(
              children: [
                const Icon(Icons.chevron_left, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGreen),
                  ),
                  child: const Text("1", style: TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                const Text("2", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                const Text("3", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                const Text("...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                const Text("6", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
