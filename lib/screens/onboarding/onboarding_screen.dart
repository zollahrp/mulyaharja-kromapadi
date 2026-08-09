import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Copywriting Premium: Bahasa lebih elegan, kuat, dan tanpa emoji
  final List<Map<String, String>> onboardingData = [
    {
      "title": "Era Baru Agrikultur",
      "description": "Hadirkan teknologi cerdas pemantauan daun padi langsung di genggaman Anda.",
      "image": "https://images.unsplash.com/photo-1586771107445-d3af9e15fa57?q=80&w=1000&auto=format&fit=crop"
    },
    {
      "title": "Analisis Nutrisi Akurat",
      "description": "Ketahui tingkat kebutuhan Nitrogen, Fosfor, dan Kalium secara real-time untuk pertumbuhan optimal.",
      "image": "https://images.unsplash.com/photo-1629737966373-fb94e1e127de?q=80&w=1000&auto=format&fit=crop"
    },
    {
      "title": "Deteksi Ancaman Dini",
      "description": "Cegah penyebaran sebelum terlambat. Identifikasi penyakit dan hama pada daun dalam tahap paling awal.",
      "image": "https://images.unsplash.com/photo-1599940824399-b87987ceb72a?q=80&w=1000&auto=format&fit=crop"
    },
    {
      "title": "Satu Pindaian Pintar",
      "description": "Arahkan kamera perangkat Anda, dan biarkan kecerdasan buatan kami bekerja dalam hitungan detik.",
      "image": "https://images.unsplash.com/photo-1523741543316-beb7fc7023d8?q=80&w=1000&auto=format&fit=crop"
    },
    {
      "title": "Masa Depan Panen Anda",
      "description": "Ambil keputusan berbasis data hari ini, dan nikmati hasil panen yang jauh lebih berlimpah esok hari.",
      "image": "https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=1000&auto=format&fit=crop"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Konten Utama yang bisa di-swipe
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(), // Efek pantulan premium saat di-scroll
            onPageChanged: (value) {
              setState(() {
                _currentPage = value;
              });
            },
            itemCount: onboardingData.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  // Gambar Full Width dengan efek Seamless Fade ke Bawah
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          onboardingData[index]["image"]!,
                          fit: BoxFit.cover,
                        ),
                        // Gradient Overlay untuk memudarkan gambar ke putih secara mulus
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Colors.white.withOpacity(0.5),
                                Colors.white,
                              ],
                              stops: const [0.0, 0.6, 0.85, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Teks Animasi yang lebih rapi
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            onboardingData[index]["title"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            onboardingData[index]["description"]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              height: 1.6,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // 2. Tombol Skip yang Elegan
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                // Tombol skip hilang saat di halaman terakhir dengan halus
                opacity: _currentPage == onboardingData.length - 1 ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: InkWell(
                    onTap: () {
                      _pageController.animateToPage(
                        onboardingData.length - 1,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8), // Kaca transparan (Glassmorphism)
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Text(
                        "Lewati",
                        style: TextStyle(
                          color: AppColors.textDark, 
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Navigation (Dots & Tombol Utama)
          Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                    (index) => buildDot(index),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56, // Sedikit lebih tinggi biar terkesan Premium
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen, // Gunakan warna hijau gelap
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4, // Sedikit bayangan untuk kedalaman
                      shadowColor: AppColors.darkGreen.withOpacity(0.4),
                    ),
                    // AnimatedSwitcher untuk efek transisi teks pada tombol
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _currentPage == onboardingData.length - 1 
                            ? "Mulai Jelajahi" 
                            : "Selanjutnya",
                        key: ValueKey<int>(_currentPage), // Kunci penting untuk animasi
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dots dengan animasi yang lebih smooth
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: _currentPage == index ? 28 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.darkGreen : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}