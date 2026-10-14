import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/lahan_model.dart';
import '../../services/lahan_service.dart';
import '../../services/api_service.dart';

class LahanScreen extends StatefulWidget {
  const LahanScreen({super.key});

  @override
  State<LahanScreen> createState() => _LahanScreenState();
}

class _LahanScreenState extends State<LahanScreen> {
  late Future<List<LahanModel>> _lahanFuture;

  @override
  void initState() {
    super.initState();
    _lahanFuture = LahanService().getLahan();
  }

  Future<void> _refreshData() async {
    setState(() {
      _lahanFuture = LahanService().getLahan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOffWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.primaryGreen,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: FutureBuilder<List<LahanModel>>(
                  future: _lahanFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryGreen),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Gagal memuat lahan:\n${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        children: [
                          _buildSummaryWidgets(0, 0),
                          const SizedBox(height: 100),
                          const Center(
                            child: Text(
                              "Belum ada data lahan.",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ],
                      );
                    }

                    final lahanList = snapshot.data!;
                    int totalLahan = lahanList.length;
                    double totalLuas = lahanList.fold(0, (sum, item) => sum + (item.luas ?? 0));
                    double totalLuasHa = totalLuas / 10000;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Column(
                        children: [
                          _buildSummaryWidgets(totalLahan, totalLuasHa),
                          const SizedBox(height: 24),
                          _buildLahanList(lahanList),
                          const SizedBox(height: 100), // Padding for bottom nav
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
                "Lahan Saya",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Kelola lahan pertanian Anda di sini.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryWidgets(int totalLahan, double totalLuasHa) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: "Total Lahan",
              value: "$totalLahan",
              subtitle: "Petak Sawah",
              icon: Icons.landscape,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: "Total Luas",
              value: totalLuasHa.toStringAsFixed(2),
              subtitle: "Hektar",
              icon: Icons.square_foot,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textBlack),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiService.baseUrl}/storage/$path';
  }

  Widget _buildLahanList(List<LahanModel> lahanList) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: lahanList.map((lahan) {
          double luasHa = (lahan.luas ?? 0) / 10000;
          
          String statusText = lahan.isAktif ? "Kondisi Prima" : "Tidak Aktif";
          Color tagColor = lahan.isAktif ? AppColors.healthyGreenTag : Colors.grey[200]!;
          Color tagTextColor = lahan.isAktif ? AppColors.healthyGreenText : Colors.grey[700]!;
          
          if (lahan.isAktif && (lahan.hst ?? 0) > 90) {
            statusText = "Masa Panen";
            tagColor = Colors.blue[50]!;
            tagTextColor = Colors.blue[700]!;
          }
          
          double progress = 0.0;
          if (lahan.hst != null) {
            progress = lahan.hst! / 110; // Assuming 110 days is full cycle
            if (progress > 1.0) progress = 1.0;
          }

          return Column(
            children: [
              _buildLahanCard(
                name: lahan.name,
                location: "Mulyaharja, Bogor Selatan",
                area: "${luasHa.toStringAsFixed(2)} Ha",
                variety: "-", // Variety not available in model
                age: lahan.hst != null ? "${lahan.hst} HST" : "-",
                status: statusText,
                statusColor: tagColor,
                statusTextColor: tagTextColor,
                imageUrl: _getFullImageUrl(lahan.fotoPath),
                progress: progress,
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLahanCard({
    required String name,
    required String location,
    required String area,
    required String variety,
    required String age,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required String imageUrl,
    required double progress,
  }) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
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
                    name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.square_foot, color: Colors.grey[500]),
                          const SizedBox(height: 4),
                          Text(area, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Luas", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.eco, color: Colors.grey[500]),
                          const SizedBox(height: 4),
                          Text(variety, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Varietas", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.grey[500]),
                          const SizedBox(height: 4),
                          Text(age, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Umur", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Status: $status",
                      style: TextStyle(color: statusTextColor, fontSize: 14, fontWeight: FontWeight.bold),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildLahanPlaceholder(),
                      )
                    : _buildLahanPlaceholder(),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Properties
                Row(
                  children: [
                    _buildPropertyItem(Icons.square_foot, "Luas", area),
                    _buildPropertyDivider(),
                    _buildPropertyItem(Icons.eco, "Varietas", variety),
                    _buildPropertyDivider(),
                    _buildPropertyItem(Icons.calendar_month, "Umur", age),
                  ],
                ),
                
                const SizedBox(height: 16),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Siklus Tanam", style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: const NetworkImage('https://i.pravatar.cc/100?img=11'),
                        ),
                        const SizedBox(width: 8),
                        Text("Dikelola oleh Anda", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ],
                    ),
                    const Row(
                      children: [
                        Text("Lihat Detail", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryGreen),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPropertyItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textBlack)),
        ],
      ),
    );
  }

  Widget _buildPropertyDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildLahanPlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.landscape_rounded, color: AppColors.primaryGreen.withOpacity(0.7), size: 44),
            const SizedBox(height: 6),
            Text(
              "Lahan Padi Terdaftar",
              style: TextStyle(
                color: AppColors.primaryGreen.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

