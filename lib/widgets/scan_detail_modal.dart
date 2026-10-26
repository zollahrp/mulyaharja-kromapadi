import 'package:flutter/material.dart';
import '../models/riwayat_scan_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'image_zoom_viewer.dart';

class ScanDetailModal {
  /// Menampilkan modal bottom sheet detail analisis riwayat scan
  static void show(
    BuildContext context, {
    required RiwayatScanModel item,
    Future<bool> Function(RiwayatScanModel item)? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScanDetailBottomSheetWidget(
        item: item,
        onDelete: onDelete,
      ),
    );
  }

  /// Menampilkan dialog konfirmasi sebelum menghapus riwayat scan
  static Future<bool> showConfirmDeleteDialog(
    BuildContext context,
    RiwayatScanModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Hapus Riwayat Scan?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Apakah Anda yakin ingin menghapus data riwayat scan pada \"${item.lahan?.name ?? 'Lahan Padi'}\"?",
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.45),
            ),
            const SizedBox(height: 6),
            Text(
              "Waktu: ${item.formattedDateTime}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Data yang dihapus tidak dapat dipulihkan kembali.",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Batal",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  icon: const Icon(Icons.delete_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    "Ya, Hapus",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}

class _ScanDetailBottomSheetWidget extends StatelessWidget {
  final RiwayatScanModel item;
  final Future<bool> Function(RiwayatScanModel item)? onDelete;

  const _ScanDetailBottomSheetWidget({
    required this.item,
    this.onDelete,
  });

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return ApiService.getStorageUrl(path);
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await ScanDetailModal.showConfirmDeleteDialog(context, item);
    if (confirmed) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (onDelete != null) {
        await onDelete!(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = item.statusTagColor;
    final statusTextColor = item.statusTagTextColor;
    final primaryUrl = _getFullImageUrl(item.fotoPath);
    final fallbackUrl = _getFullImageUrl(item.lahan?.fotoPath);
    final activeUrl = primaryUrl.isNotEmpty ? primaryUrl : fallbackUrl;

    final bool hasDisease = item.hasDisease;
    final bool hasPest = item.hasPest;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // 2. Leaf Image / Photo Card with Zoom Support
              GestureDetector(
                onTap: activeUrl.isNotEmpty ? () => _openImageZoomDialog(context, activeUrl) : null,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: activeUrl.isNotEmpty
                          ? Image.network(
                              activeUrl,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                if (fallbackUrl.isNotEmpty && fallbackUrl != activeUrl) {
                                  return Image.network(
                                    fallbackUrl,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => _buildPlaceholderImage(height: 220),
                                  );
                                }
                                return _buildPlaceholderImage(height: 220);
                              },
                            )
                          : _buildPlaceholderImage(height: 220),
                    ),
                    if (activeUrl.isNotEmpty)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                "Ketuk untuk Zoom",
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Header: Lahan & Status Badge & Tombol Hapus Cepat
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
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "Waktu Scan: ${item.formattedDateTime}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasDisease
                              ? Icons.warning_amber_rounded
                              : (hasPest ? Icons.bug_report_rounded : Icons.check_circle_rounded),
                          size: 14,
                          color: statusTextColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.statusTagText,
                          style: TextStyle(
                            color: statusTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _handleDelete(context),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Alert / Banner: Gejala dan Hasil Diagnosis Penyakit
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hasDisease ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasDisease ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasDisease ? Icons.healing_rounded : Icons.verified_rounded,
                          size: 16,
                          color: hasDisease ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "GEJALA DAN HASIL DIAGNOSIS PENYAKIT",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: hasDisease ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (hasDisease ? const Color(0xFFDC2626) : const Color(0xFF16A34A)).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${item.akurasi != null ? item.akurasi!.toStringAsFixed(0) : '95'}% Akurat",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasDisease ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.cleanDiseaseDiagnosis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: hasDisease ? const Color(0xFF7F1D1D) : const Color(0xFF14532D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Jika ada gejala hama (serangga/gigitan), tampilkan banner deteksi hama terpisah
              if (hasPest) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bug_report_rounded, size: 16, color: Color(0xFFD97706)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "DETEKSI SERANGAN HAMA (ORGANISME PENGGANGGU)",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.cleanPestDiagnosis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: Color(0xFF78350F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // 5. Primary BWD Metric Card (Bagan Warna Daun)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.eco_rounded, color: Color(0xFF15803D), size: 24),
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
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Skala ${item.bwdValue?.toStringAsFixed(1) ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.bwdStatus ?? "Standar",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        item.bwdInterpretationText,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 6. Section: Kondisi Lingkungan
              _buildDetailSectionTitle("Kondisi Lingkungan", Icons.thermostat_rounded),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildDetailEnvItem(
                        label: "Suhu",
                        value: "${item.temperatureValue.toStringAsFixed(1)}°C",
                        icon: Icons.device_thermostat_rounded,
                        badgeColor: const Color(0xFFEA580C),
                      ),
                    ),
                    Container(width: 1, height: 38, color: const Color(0xFFE2E8F0)),
                    Expanded(
                      child: _buildDetailEnvItem(
                        label: "Kelembapan",
                        value: "${item.humidityValue}%",
                        icon: Icons.water_drop_rounded,
                        badgeColor: const Color(0xFF0284C7),
                      ),
                    ),
                    Container(width: 1, height: 38, color: const Color(0xFFE2E8F0)),
                    Expanded(
                      child: _buildDetailEnvItem(
                        label: "Cahaya",
                        value: "${item.luxValue} lx",
                        icon: Icons.light_mode_rounded,
                        badgeColor: const Color(0xFFCA8A04),
                      ),
                    ),
                    Container(width: 1, height: 38, color: const Color(0xFFE2E8F0)),
                    Expanded(
                      child: _buildDetailEnvItem(
                        label: "Cuaca",
                        value: item.microclimateText,
                        icon: Icons.cloud_outlined,
                        badgeColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 7. Section: Evaluasi Kesehatan
              _buildDetailSectionTitle("Evaluasi Kesehatan", Icons.health_and_safety_rounded),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDetailHealthItem(
                      icon: Icons.grass_rounded,
                      title: "Ketersediaan Nitrogen (N)",
                      value: item.nitrogenStatus,
                      statusColor: const Color(0xFF15803D),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 56),
                    _buildDetailHealthItem(
                      icon: Icons.bug_report_rounded,
                      title: "Gejala Serangan Hama (Serangga)",
                      value: item.cleanPestDiagnosis,
                      statusColor: hasPest ? const Color(0xFFEA580C) : const Color(0xFF10B981),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 56),
                    _buildDetailHealthItem(
                      icon: Icons.healing_rounded,
                      title: "Gejala & Hasil Diagnosis Penyakit (Patogen)",
                      value: item.cleanDiseaseDiagnosis,
                      statusColor: hasDisease ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 8. Section: Simpulan Analisis (Diagnosis Banner)
              _buildDetailSectionTitle("Ringkasan Diagnosis", Icons.insights_rounded),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF15803D), size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.conclusionText,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 9. Section: Rekomendasi Tindakan Agronomis
              _buildDetailSectionTitle("Rekomendasi Tindakan Agronomis", Icons.assignment_turned_in_rounded),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1D4ED8), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.recommendationText,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 13, color: Color(0xFF1E40AF)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Dasar Rekomendasi: ${item.recommendationBasisText}",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 10. Section: Spesifikasi Analisis
              _buildDetailSectionTitle("Spesifikasi Analisis", Icons.analytics_rounded),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildDetailSpecItem(
                        title: "Skala BWD",
                        value: item.bwdValue != null ? "Level ${item.bwdValue!.toStringAsFixed(1)}" : "-",
                        icon: Icons.palette_rounded,
                      ),
                    ),
                    Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                    Expanded(
                      child: _buildDetailSpecItem(
                        title: "Fase HST",
                        value: item.hstCalculated != null ? "${item.hstCalculated} HST" : "-",
                        icon: Icons.calendar_month_rounded,
                      ),
                    ),
                    Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                    Expanded(
                      child: _buildDetailSpecItem(
                        title: "Akurasi",
                        value: item.akurasi != null ? "${item.akurasi!.toStringAsFixed(0)}%" : "92%",
                        icon: Icons.model_training_rounded,
                      ),
                    ),
                    Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                    Expanded(
                      child: _buildDetailSpecItem(
                        title: "Kondisi",
                        value: item.statusTagText,
                        icon: Icons.health_and_safety_rounded,
                        valueColor: item.statusTagTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // 10. Actions: Delete & Close
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleDelete(context),
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                  label: const Text(
                    'Hapus Riwayat Ini',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                    backgroundColor: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Tutup Detail Analisis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  Widget _buildDetailSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailEnvItem({
    required String label,
    required String value,
    required IconData icon,
    required Color badgeColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: badgeColor, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDetailHealthItem({
    required IconData icon,
    required String title,
    required String value,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSpecItem({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage({required double height, double? width}) {
    final isLarge = height > 100;
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: isLarge ? 48 : 28,
              color: const Color(0xFF94A3B8),
            ),
            if (isLarge) ...[
              const SizedBox(height: 8),
              const Text(
                "Foto Tanaman Padi",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openImageZoomDialog(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;
    ImageZoomViewer.show(
      context,
      imageUrl: imageUrl,
      title: item.lahan?.name ?? "Sampel Daun Padi",
      subtitle: "${item.penyakit} • ${item.formattedDateTime}",
    );
  }
}
