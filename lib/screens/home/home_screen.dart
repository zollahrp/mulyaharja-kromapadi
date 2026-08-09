import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Index untuk kategori yang sedang aktif (All, Indoor, dll)
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ["Semua", "Riwayat", "Pupuk", "Penyakit", "Cuaca"];

  // Warna khusus untuk tema Clean Green ini
  final Color headerGreen = const Color(0xFF518967); // Hijau kalem ala referensi
  final Color bgWhite = const Color(0xFFF8F9FA); // Putih sedikit abu biar mata nggak sakit

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgWhite,
      body: Column(
        children: [
          // 1. HEADER HIJAU EKSKLUSIF
          Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
            decoration: BoxDecoration(
              color: headerGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lokasi & Notifikasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lokasi Lahan",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: Color(0xFFFFC107), size: 16), // Ikon kuning
                            SizedBox(width: 4),
                            Text(
                              "Mulyaharja, Bogor",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        const SizedBox(width: 16),
                        Stack(
                          children: [
                            const Icon(Icons.notifications_outlined, color: Colors.white),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Cari riwayat scan...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      ),
                      const Icon(Icons.document_scanner_outlined, color: Colors.grey),
                      const SizedBox(width: 12),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.tune, color: Colors.grey), // Ikon filter
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. BODY KONTEN UTAMA
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "#InfoPertanian",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      Text(
                        "Lihat Semua",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card Banner Hitam ala Referensi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D2024), // Warna hitam pekat elegan
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(
                        image: const NetworkImage('https://images.unsplash.com/photo-1599940824399-b87987ceb72a?q=80&w=1000&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Waktu Terbatas!",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Deteksi Dini\nPenyakit Padi",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Akurasi AI hingga 98%",
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107), // Tombol kuning
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                minimumSize: Size.zero,
                              ),
                              child: const Text("Scan Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Kategori Chip Horizontal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Menu Pilihan",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      Text(
                        "Lihat Semua",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedCategoryIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? headerGreen : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? headerGreen : Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Text(
                                _categories[index],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[600],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grid Kartu Fitur/Tanaman
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75, // Proporsi tinggi card biar mirip referensi
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      // Data dummy untuk grid
                      List<Map<String, dynamic>> items = [
                        {"title": "Cek Nutrisi (N)", "img": "https://images.unsplash.com/photo-1523741543316-beb7fc7023d8?q=80&w=300&auto=format&fit=crop", "rating": "Optimal"},
                        {"title": "Kalkulator Urea", "img": "https://images.unsplash.com/photo-1629737966373-fb94e1e127de?q=80&w=300&auto=format&fit=crop", "rating": "Hitung"},
                        {"title": "Hama Wereng", "img": "https://images.unsplash.com/photo-1599940824399-b87987ceb72a?q=80&w=300&auto=format&fit=crop", "rating": "Bahaya"},
                        {"title": "Cuaca Esok", "img": "https://images.unsplash.com/photo-1586771107445-d3af9e15fa57?q=80&w=300&auto=format&fit=crop", "rating": "Hujan"},
                      ];
                      return _buildGridCard(items[index]);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Bagian Atas
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  child: Image.network(
                    item["img"],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Icon Love (Like)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 14,
                    child: const Icon(Icons.favorite, color: Colors.red, size: 16),
                  ),
                )
              ],
            ),
          ),
          // Info Teks Bagian Bawah
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Status:",
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFC107), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          item["rating"],
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}