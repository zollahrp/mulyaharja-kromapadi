import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/scan_history_service.dart';
import '../../services/export_service.dart';
import '../../models/riwayat_scan_model.dart';
import '../../services/api_service.dart';

enum ScanFilterDate { all, today, sevenDays, thirtyDays, custom }
enum ScanFilterStatus { all, normalOnly, diseaseOnly }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScanHistoryService _historyService = ScanHistoryService();
  final TextEditingController _searchController = TextEditingController();

  List<RiwayatScanModel> _rawList = [];
  List<RiwayatScanModel> _filteredList = [];
  bool _isLoading = true;
  String? _errorMessage;

  ScanFilterDate _selectedDateFilter = ScanFilterDate.all;
  ScanFilterStatus _selectedStatusFilter = ScanFilterStatus.all;
  DateTimeRange? _customDateRange;
  String _searchQuery = '';
  String _sortBy = 'terbaru'; // 'terbaru', 'terlama', 'akurasi_tinggi'

  int _currentPage = 1;
  final int _pageSize = 6;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _historyService.getHistory();
      if (!mounted) return;
      setState(() {
        _rawList = data;
        _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    final now = DateTime.now();

    List<RiwayatScanModel> result = _rawList.where((item) {
      // 1. Text Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final lahanMatch = item.lahan?.name.toLowerCase().contains(query) ?? false;
        final diseaseMatch = item.penyakit.toLowerCase().contains(query);
        final actionMatch = item.tindakan?.toLowerCase().contains(query) ?? false;
        final hstMatch = item.lahan?.hst?.toString().contains(query) ?? false;
        if (!lahanMatch && !diseaseMatch && !actionMatch && !hstMatch) return false;
      }

      // 2. Health Status Filter
      final isNormal = item.penyakit.toLowerCase() == 'normal' || item.penyakit.isEmpty;
      if (_selectedStatusFilter == ScanFilterStatus.normalOnly && !isNormal) return false;
      if (_selectedStatusFilter == ScanFilterStatus.diseaseOnly && isNormal) return false;

      // 3. Date Range Filter
      final parsedDate = DateTime.tryParse(item.createdAt);
      if (parsedDate != null) {
        switch (_selectedDateFilter) {
          case ScanFilterDate.today:
            if (parsedDate.year != now.year ||
                parsedDate.month != now.month ||
                parsedDate.day != now.day) {
              return false;
            }
            break;
          case ScanFilterDate.sevenDays:
            if (now.difference(parsedDate).inDays > 7) return false;
            break;
          case ScanFilterDate.thirtyDays:
            if (now.difference(parsedDate).inDays > 30) return false;
            break;
          case ScanFilterDate.custom:
            if (_customDateRange != null) {
              final start = DateTime(
                _customDateRange!.start.year,
                _customDateRange!.start.month,
                _customDateRange!.start.day,
              );
              final end = DateTime(
                _customDateRange!.end.year,
                _customDateRange!.end.month,
                _customDateRange!.end.day,
                23,
                59,
                59,
              );
              if (parsedDate.isBefore(start) || parsedDate.isAfter(end)) return false;
            }
            break;
          case ScanFilterDate.all:
            break;
        }
      }
      return true;
    }).toList();

    // Sorting
    result.sort((a, b) {
      if (_sortBy == 'akurasi_tinggi') {
        final accA = a.akurasi ?? 0.0;
        final accB = b.akurasi ?? 0.0;
        return accB.compareTo(accA);
      }

      final dateA = DateTime.tryParse(a.createdAt) ?? DateTime(2000);
      final dateB = DateTime.tryParse(b.createdAt) ?? DateTime(2000);
      return _sortBy == 'terlama' ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    _filteredList = result;
    _currentPage = 1;
  }



  int get _totalPages => (_filteredList.length / _pageSize).ceil().clamp(1, 9999);

  List<RiwayatScanModel> get _currentPageItems {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= _filteredList.length) return [];
    final end = (start + _pageSize).clamp(0, _filteredList.length);
    return _filteredList.sublist(start, end);
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty || path.contains('unsplash.com')) return '';
    if (path.startsWith('http')) return path;
    return '${ApiService.baseUrl}/storage/$path';
  }

  void _showExportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Format Ekspor Data",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
            ),
            const SizedBox(height: 4),
            Text(
              "Pilih format arsip laporan untuk keperluan dokumentasi atau analisis.",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey[50],
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
              ),
              title: const Text("Ekspor Laporan Ringkas (PDF)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text("Siap cetak, dilengkapi ringkasan statistik dan diagnosa", style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ExportService.exportToPdf(_filteredList);
                  _showSuccessToast("Data berhasil diekspor ke PDF");
                } catch (e) {
                  _showErrorToast("Gagal mengekspor PDF: $e");
                }
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey[50],
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.table_view_rounded, color: AppColors.primaryGreen, size: 20),
              ),
              title: const Text("Ekspor Lembar Kerja (CSV/Excel)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text("Format tabel mentah untuk pengolahan data statistik lanjutan", style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ExportService.exportToCsv(_filteredList);
                  _showSuccessToast("Data riwayat berhasil diekspor ke format CSV");
                } catch (e) {
                  _showErrorToast("Gagal mengekspor CSV: $e");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Urutkan Data", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              RadioListTile<String>(
                title: const Text("Terbaru Masuk", style: TextStyle(fontSize: 13)),
                value: 'terbaru',
                groupValue: _sortBy,
                activeColor: AppColors.primaryGreen,
                onChanged: (val) {
                  setState(() {
                    _sortBy = val!;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text("Terlama Masuk", style: TextStyle(fontSize: 13)),
                value: 'terlama',
                groupValue: _sortBy,
                activeColor: AppColors.primaryGreen,
                onChanged: (val) {
                  setState(() {
                    _sortBy = val!;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text("Tingkat Akurasi Tertinggi", style: TextStyle(fontSize: 13)),
                value: 'akurasi_tinggi',
                groupValue: _sortBy,
                activeColor: AppColors.primaryGreen,
                onChanged: (val) {
                  setState(() {
                    _sortBy = val!;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateFilter = ScanFilterDate.custom;
        _customDateRange = picked;
        _applyFiltersAndSort();
      });
    }
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openDetailBottomSheet(RiwayatScanModel item, bool isNormal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final statusColor = isNormal ? AppColors.healthyGreenTag : AppColors.alertRedTag;
        final statusTextColor = isNormal ? AppColors.healthyGreenText : AppColors.alertRedText;
        final imageUrl = _getFullImageUrl(item.fotoPath);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 210,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(height: 210),
                          )
                        : _buildPlaceholderImage(height: 210),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.lahan?.name ?? "Lahan Padi Utama",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "Waktu Scan: ${item.formattedDateTime}",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNormal ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                              size: 13,
                              color: statusTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isNormal ? "Normal / Sehat" : "Penyakit",
                              style: TextStyle(
                                color: statusTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isNormal && item.penyakit.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.healing_rounded, size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  "DIAGNOSA & GEJALA PENYAKIT",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                              if (item.akurasi != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${item.akurasi}% Akurat",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.penyakit,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF991B1B),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Dedicated BWD Leaf Color Chart Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "BAGAN WARNA DAUN (BWD)",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Skala ${item.bwdValue?.toStringAsFixed(1) ?? '-'}${item.bwdStatus != null ? ' — Status: ${item.bwdStatus}' : ''}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildQuickMeta(
                            title: "Skala BWD",
                            value: item.bwdValue != null ? "Level ${item.bwdValue}" : "-",
                          ),
                        ),
                        Container(width: 1, height: 26, color: Colors.grey[300]),
                        Expanded(
                          child: _buildQuickMeta(
                            title: "Fase HST",
                            value: item.hstCalculated != null ? "${item.hstCalculated} Hari" : "-",
                          ),
                        ),
                        Container(width: 1, height: 26, color: Colors.grey[300]),
                        Expanded(
                          child: _buildQuickMeta(
                            title: "Akurasi",
                            value: item.akurasi != null ? "${item.akurasi}%" : "-",
                          ),
                        ),
                        Container(width: 1, height: 26, color: Colors.grey[300]),
                        Expanded(
                          child: _buildQuickMeta(
                            title: "Kondisi",
                            value: isNormal ? "Sehat" : "Penyakit",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Rekomendasi Tindakan Teknis",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      item.tindakan?.isNotEmpty == true
                          ? item.tindakan!
                          : "Tidak ada tindakan khusus. Lanjutkan pemantauan rutin dan pemupukan presisi.",
                      style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickMeta({required String title, required String value}) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textBlack),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage({required double height, double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      color: const Color(0xFFF1F3F5),
      child: Center(
        child: Icon(Icons.eco_outlined, color: Colors.grey[400], size: height > 100 ? 44 : 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOffWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _fetchHistory,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildFilterChips()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14.0, bottom: 18.0),
                  child: _buildComputedSummary(),
                ),
              ),
              _buildHistoryListSection(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                  child: Column(
                    children: [
                      _buildInsightCard(),
                      const SizedBox(height: 20),
                      _buildPaginationControl(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (canPop) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textBlack),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Riwayat Scan",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Pantau catatan hasil diagnosa daun padi lapangan Anda.",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _showExportModal,
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text("Ekspor"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen, width: 1.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                    _applyFiltersAndSort();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Cari riwayat, lahan, atau penyakit...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _applyFiltersAndSort();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showSortModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreen),
              ),
              child: const Row(
                children: [
                  Icon(Icons.swap_vert_rounded, color: AppColors.primaryGreen, size: 18),
                  SizedBox(width: 4),
                  Text(
                    "Urutkan",
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildChip(
            label: "Semua",
            isSelected: _selectedDateFilter == ScanFilterDate.all && _selectedStatusFilter == ScanFilterStatus.all,
            onTap: () {
              setState(() {
                _selectedDateFilter = ScanFilterDate.all;
                _selectedStatusFilter = ScanFilterStatus.all;
                _applyFiltersAndSort();
              });
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: "Hari Ini",
            isSelected: _selectedDateFilter == ScanFilterDate.today,
            onTap: () {
              setState(() {
                _selectedDateFilter = ScanFilterDate.today;
                _applyFiltersAndSort();
              });
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: "7 Hari",
            isSelected: _selectedDateFilter == ScanFilterDate.sevenDays,
            onTap: () {
              setState(() {
                _selectedDateFilter = ScanFilterDate.sevenDays;
                _applyFiltersAndSort();
              });
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: "30 Hari",
            isSelected: _selectedDateFilter == ScanFilterDate.thirtyDays,
            onTap: () {
              setState(() {
                _selectedDateFilter = ScanFilterDate.thirtyDays;
                _applyFiltersAndSort();
              });
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: _customDateRange == null
                ? "Kustom Tanggal"
                : "${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}",
            isSelected: _selectedDateFilter == ScanFilterDate.custom,
            icon: Icons.calendar_month_outlined,
            onTap: _pickCustomDateRange,
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: "Hanya Sehat",
            isSelected: _selectedStatusFilter == ScanFilterStatus.normalOnly,
            onTap: () {
              setState(() {
                _selectedStatusFilter = _selectedStatusFilter == ScanFilterStatus.normalOnly
                    ? ScanFilterStatus.all
                    : ScanFilterStatus.normalOnly;
                _applyFiltersAndSort();
              });
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: "Terindikasi Penyakit",
            isSelected: _selectedStatusFilter == ScanFilterStatus.diseaseOnly,
            onTap: () {
              setState(() {
                _selectedStatusFilter = _selectedStatusFilter == ScanFilterStatus.diseaseOnly
                    ? ScanFilterStatus.all
                    : ScanFilterStatus.diseaseOnly;
                _applyFiltersAndSort();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: isSelected ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComputedSummary() {
    int total = _filteredList.length;
    int healthy = 0;
    double sumAccuracy = 0;
    int accuracyCount = 0;

    for (var item in _filteredList) {
      if (item.penyakit.toLowerCase() == 'normal' || item.penyakit.isEmpty) {
        healthy++;
      }
      final acc = item.akurasi ?? 0.0;
      if (acc > 0) {
        sumAccuracy += acc;
        accuracyCount++;
      }
    }

    int disease = total - healthy;
    double avgAccuracy = accuracyCount > 0 ? (sumAccuracy / accuracyCount) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ringkasan Data Terpilih",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textBlack),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.qr_code_scanner_rounded,
                  iconColor: AppColors.primaryGreen,
                  title: "Total Scan",
                  value: total.toString(),
                  subtitle: "Data Riwayat",
                  subtitleColor: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.track_changes_rounded,
                  iconColor: AppColors.warningOrangeText,
                  title: "Rata Akurasi",
                  value: avgAccuracy > 0 ? "${avgAccuracy.toStringAsFixed(1)}%" : "-",
                  subtitle: "Kualitas Model",
                  subtitleColor: AppColors.warningOrangeText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.verified_outlined,
                  iconColor: AppColors.primaryGreen,
                  title: "Tanaman Sehat",
                  value: healthy.toString(),
                  subtitle: total > 0 ? "${((healthy / total) * 100).toStringAsFixed(0)}%" : "0%",
                  subtitleColor: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.coronavirus_outlined,
                  iconColor: AppColors.alertRedText,
                  title: "Terinfeksi",
                  value: disease.toString(),
                  subtitle: total > 0 ? "${((disease / total) * 100).toStringAsFixed(0)}%" : "0%",
                  subtitleColor: AppColors.alertRedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 12),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textBlack),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
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
                    Container(height: 14, width: 100, color: Colors.grey[300]),
                    Container(height: 18, width: 50, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6))),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 12, width: 140, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(height: 10, width: 10, color: Colors.grey[300]),
                    const SizedBox(width: 4),
                    Container(height: 10, width: 60, color: Colors.grey[300]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListSection() {
    if (_isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildSkeletonItem();
          },
          childCount: 4,
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                'Gagal memuat data: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchHistory,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('Muat Ulang', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    final pagedItems = _currentPageItems;

    if (pagedItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.find_in_page_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? "Tidak ada data riwayat yang cocok dengan kata kunci."
                      : "Belum ada riwayat hasil scan daun padi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = pagedItems[index];
            final isNormal = item.penyakit.toLowerCase() == 'normal' || item.penyakit.isEmpty;
            return _buildScanTile(item, isNormal);
          },
          childCount: pagedItems.length,
        ),
      ),
    );
  }

  Widget _buildScanTile(RiwayatScanModel item, bool isNormal) {
    final statusColor = isNormal ? AppColors.healthyGreenTag : AppColors.alertRedTag;
    final statusTextColor = isNormal ? AppColors.healthyGreenText : AppColors.alertRedText;
    final fullUrl = _getFullImageUrl(item.fotoPath);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetailBottomSheet(item, isNormal),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: fullUrl.isNotEmpty
                      ? Image.network(
                          fullUrl,
                          width: 74,
                          height: 74,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(height: 74, width: 74),
                        )
                      : _buildPlaceholderImage(height: 74, width: 74),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.lahan?.name ?? "Lahan Padi Utama",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isNormal ? "Sehat" : (item.penyakit.length > 18 ? "Penyakit" : item.penyakit),
                                style: TextStyle(
                                  color: statusTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // BWD Badge indicator
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.eco_rounded, size: 11, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      "BWD ${item.bwdValue?.toStringAsFixed(1) ?? '-'}${item.bwdStatus != null ? ' (${item.bwdStatus})' : ''}",
                                      style: const TextStyle(
                                        color: Color(0xFF15803D),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${item.lahan?.hst != null ? '${item.lahan?.hst} HST • ' : ''}Akurasi: ${item.akurasi != null ? '${item.akurasi}%' : '-'}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.humanRelativeTime,
                              style: TextStyle(color: Colors.grey[500], fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.insightCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_outlined, color: AppColors.primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Deteksi dini penyakit daun padi menjaga potensi hasil panen hingga 30% lebih optimal.",
              style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showSuccessToast("Fitur analisis tren agronomi sedang disiapkan"),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Analisis", style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right, color: AppColors.primaryGreen, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControl() {
    final total = _filteredList.length;
    final startIdx = total == 0 ? 0 : (_currentPage - 1) * _pageSize + 1;
    final endIdx = (_currentPage * _pageSize).clamp(0, total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "Menampilkan $startIdx-$endIdx dari $total riwayat",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "$_currentPage / $_totalPages",
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _currentPage < _totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
