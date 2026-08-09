import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. HEADER (ILUSTRASI SAWAH & SEARCH BAR)
            // ==========================================
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Animasi Header (Fade & Scale In)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 1.2, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=1000&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Halo,\nPetani Cerdas",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              // Tombol Notif Interaktif
                              Material(
                                color: Colors.white.withOpacity(0.25),
                                shape: const CircleBorder(),
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                  onTap: () {
                                    // TODO: Buka Notifikasi
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Icon(Icons.notifications_none, color: Colors.white, size: 24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Search Bar Mengambang (Pop Up Animation)
                Positioned(
                  bottom: -28,
                  left: 24,
                  right: 24,
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.grey, size: 22),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Cari data daun padi...",
                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ),
                                Container(height: 24, width: 1, color: Colors.grey[200]),
                                const SizedBox(width: 12),
                                Icon(Icons.filter_list, color: Colors.grey[600], size: 22),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 56),

            // ==========================================
            // 2. BANNER CARD (Slide-up Animasi)
            // ==========================================
            _SlideFadeIn(
              delay: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppColors.background, 
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.lightGreen.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightGreen.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Deteksi BWD AI",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.w900, 
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Cek penyakit & nutrisi NPK daun",
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            // Tombol dengan efek sentuhan mulus
                            Material(
                              color: AppColors.darkGreen,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  // TODO: Buka Kamera BWD
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.document_scanner, size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        "Buka Kamera",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ilustrasi Bulat
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(seconds: 1),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 6.28, 
                            child: child,
                          );
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.energy_savings_leaf, color: AppColors.primaryGreen, size: 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ==========================================
            // 3. MENU LINGKARAN (Staggered Animasi)
            // ==========================================
            _SlideFadeIn(
              delay: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInteractiveCircleMenu(Icons.science, "Nutrisi\nNPK", AppColors.warningYellow),
                    _buildInteractiveCircleMenu(Icons.coronavirus, "Hama &\nPenyakit", Colors.redAccent),
                    _buildInteractiveCircleMenu(Icons.history, "Riwayat\nScan", AppColors.primaryGreen),
                    _buildInteractiveCircleMenu(Icons.book, "Panduan\nBWD", Colors.blueAccent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // ==========================================
            // 4. REKOMENDASI ARTIKEL
            // ==========================================
            _SlideFadeIn(
              delay: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "Rekomendasi Panduan",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w900, 
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: [
                        _buildRecommendationCard(
                          "Ciri Kekurangan\nNitrogen (N)", 
                          "https://images.unsplash.com/photo-1629737966373-fb94e1e127de?q=80&w=300&auto=format&fit=crop"
                        ),
                        const SizedBox(width: 16),
                        _buildRecommendationCard(
                          "Bedakan Penyakit\ndan Defisiensi", 
                          "https://images.unsplash.com/photo-1599940824399-b87987ceb72a?q=80&w=300&auto=format&fit=crop"
                        ),
                        const SizedBox(width: 16),
                        _buildRecommendationCard(
                          "Standar Warna\nDaun Normal", 
                          "https://images.unsplash.com/photo-1586771107445-d3af9e15fa57?q=80&w=300&auto=format&fit=crop"
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCircleMenu(IconData icon, String title, Color iconColor) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 4, 
          shadowColor: Colors.black.withOpacity(0.2),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () {},
            child: Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[100]!, width: 1),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w700, 
            color: AppColors.textDark,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(String title, String imageUrl) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w800, 
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// KELAS HELPER UNTUK ANIMASI SLIDE & FADE
// ==========================================
class _SlideFadeIn extends StatelessWidget {
  final Widget child;
  final int delay;

  const _SlideFadeIn({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)), 
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}