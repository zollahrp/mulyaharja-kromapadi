import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../utils/app_colors.dart';
import '../../services/gemini_service.dart';
import '../../services/scan_history_service.dart';

class ScanResultScreen extends StatefulWidget {
  final XFile imageFile;
  final int lahanId;

  const ScanResultScreen({super.key, required this.imageFile, required this.lahanId});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final GeminiService _geminiService = GeminiService();
  final ScanHistoryService _scanHistoryService = ScanHistoryService();
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final result = await _geminiService.analyzeLeaf(widget.imageFile);
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Hasil Scan Daun Padi",
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
      body: _isLoading
          ? _ScannerAnimation(imageFile: widget.imageFile)
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text("Gagal Menganalisis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _analyzeImage();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                          child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                )
              : _buildResultContent(),
    );
  }

  Widget _buildResultContent() {
    final bwdValue = _analysisResult?['bwd_value']?.toString() ?? 'N/A';
    final bwdStatus = _analysisResult?['bwd_status'] ?? '-';
    final bwdInterpretation = _analysisResult?['bwd_interpretation'] ?? '-';
    final nitrogenStatus = _analysisResult?['nitrogen_status'] ?? '-';
    final pestSymptoms = _analysisResult?['pest_symptoms'] ?? '-';
    final diseaseSymptoms = _analysisResult?['disease_symptoms'] ?? '-';
    final conclusion = _analysisResult?['conclusion'] ?? '-';
    final recommendation = _analysisResult?['recommendation'] ?? '-';
    final colorIndex = _analysisResult?['color_index']?.toString() ?? '-';
    final imageQuality = _analysisResult?['image_quality'] ?? '-';
    final lightIntensity = _analysisResult?['light_intensity'] ?? '-';
    final confidence = _analysisResult?['confidence']?.toString() ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(),
              const SizedBox(width: 16),
              Expanded(child: _buildBWDCard(bwdValue, bwdStatus, bwdInterpretation)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "RINGKASAN KESEHATAN DAUN",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          _buildHealthSummaryItem(Icons.energy_savings_leaf, "Status N (Nitrogen)", nitrogenStatus, Colors.orange),
          const SizedBox(height: 8),
          _buildHealthSummaryItem(Icons.bug_report, "Gejala Serangan Hama", pestSymptoms, Colors.green),
          const SizedBox(height: 8),
          _buildHealthSummaryItem(Icons.coronavirus, "Gejala Penyakit / Patogen", diseaseSymptoms, Colors.green),
          const SizedBox(height: 16),
          _buildConclusionCard(conclusion),
          const SizedBox(height: 16),
          _buildRecommendationCard(recommendation),
          const SizedBox(height: 16),
          _buildDetailAnalysis(colorIndex, imageQuality, lightIntensity, confidence),
          const SizedBox(height: 24),
          _buildHistoryAction(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh, color: Colors.black87),
                  label: const Text("Scan Ulang", style: TextStyle(color: Colors.black87)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () async {
                    setState(() {
                      _isSaving = true;
                    });
                    try {
                      await _scanHistoryService.submitScan(
                        lahanId: widget.lahanId,
                        penyakit: _analysisResult?['disease_symptoms'] ?? 'Normal',
                        akurasi: double.tryParse(_analysisResult?['confidence']?.toString() ?? '0'),
                        tindakan: _analysisResult?['recommendation'],
                        fotoPath: widget.imageFile.path,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hasil scan berhasil disimpan!')),
                      );
                      // Navigate to History or go back
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menyimpan: $e')),
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSaving = false;
                        });
                      }
                    }
                  },
                  icon: _isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(_isSaving ? "Menyimpan..." : "Simpan Hasil", style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem("Ambil Gambar", 1, true),
          _buildStepDivider(),
          _buildStepItem("Analisis", 2, true),
          _buildStepDivider(),
          _buildStepItem("Hasil", 3, true),
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
        color: AppColors.primaryGreen,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb
                        ? Image.network(widget.imageFile.path, fit: BoxFit.contain)
                        : Image.file(File(widget.imageFile.path), fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            image: kIsWeb
                ? NetworkImage(widget.imageFile.path) as ImageProvider
                : FileImage(File(widget.imageFile.path)),
            fit: BoxFit.cover,
          ),
        ),
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.zoom_in, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text("Lihat Gambar", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBWDCard(String value, String status, String interpretation) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("NILAI BWD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.replaceAll('.', ','),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.orange, height: 1),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(status, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          // Simple gradient bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                colors: [Colors.yellow, Colors.lightGreen, Colors.green, Color(0xFF1B5E20)],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("1", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("2", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("3", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("4", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("5", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.energy_savings_leaf, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Interpretasi BWD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        interpretation,
                        style: const TextStyle(fontSize: 10, color: Colors.black87),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHealthSummaryItem(IconData icon, String title, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1B1D2A))),
                const SizedBox(height: 2),
                Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("Detail", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
          )
        ],
      ),
    );
  }

  Widget _buildConclusionCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SIMPULAN", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 12, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("REKOMENDASI", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 12, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailAnalysis(String colorIndex, String imageQuality, String lightIntensity, String confidence) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("DETAIL ANALISIS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDetailBox("Indeks Warna", colorIndex, "Relatif Rendah", Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildDetailBox("Kualitas Gambar", imageQuality, "Skor 86/100", AppColors.primaryGreen)),
              const SizedBox(width: 8),
              Expanded(child: _buildDetailBox("Intensitas Cahaya", lightIntensity, "Normal", AppColors.primaryGreen)),
              const SizedBox(width: 8),
              Expanded(child: _buildDetailBox("Confidence", "$confidence%", "Tinggi", AppColors.primaryGreen)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDetailBox(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 8, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHistoryAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("RIWAYAT SCAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Text("Simpan hasil scan ini untuk pemantauan.", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save, size: 16, color: Colors.white),
            label: const Text("Simpan", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        ],
      ),
    );
  }
}

class _ScannerAnimation extends StatefulWidget {
  final XFile imageFile;
  const _ScannerAnimation({required this.imageFile});

  @override
  State<_ScannerAnimation> createState() => _ScannerAnimationState();
}

class _ScannerAnimationState extends State<_ScannerAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 250,
            height: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  kIsWeb
                      ? Image.network(widget.imageFile.path, fit: BoxFit.cover)
                      : Image.file(File(widget.imageFile.path), fit: BoxFit.cover),
                  
                  // Scanning Laser Animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Positioned(
                        top: _controller.value * 350 - 50, // Bergerak dari -50 sampai 300
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryGreen.withOpacity(0.0),
                                AppColors.primaryGreen.withOpacity(0.5),
                                AppColors.primaryGreen.withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              height: 3,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGreen,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGreen,
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Border Frame Target
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryGreen.withOpacity(0.8), width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "MENGANALISIS DAUN",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Color(0xFF1B1D2A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Kromapadi sedang memproses gambar untuk\nmendeteksi penyakit dan nilai nutrisi...",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7A7E86),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
