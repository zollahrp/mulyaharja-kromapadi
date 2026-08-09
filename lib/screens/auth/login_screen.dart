import 'package:flutter/material.dart';
import 'package:mulyaharja_kromapadi/screens/auth/register_screen.dart';
import 'package:mulyaharja_kromapadi/screens/main_navigation.dart';
import '../../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Scrollnya bakal mati secara otomatis kalau layarnya cukup (mentok 1 layar)
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight, // Maksa minimal tinggi sama dengan tinggi HP
              ),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    // Konten Utama
                    Column(
                      children: [
                        // 1. Header Gambar Daun dengan Potongan Bergelombang
                        Stack(
                          children: [
                            ClipPath(
                              clipper: WaveClipper(),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?q=80&w=1000&auto=format&fit=crop',
                                height: 280,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircleAvatar(
                                  backgroundColor: Colors.white.withOpacity(0.9),
                                  radius: 20,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // 2. Teks Selamat Datang (Tengah)
                        const SizedBox(height: 8),
                        const Text(
                          "Selamat Datang",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkGreen,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Masuk ke akun Anda",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        
                        // Spacer() bakal ngedorong elemen di bawahnya secara otomatis biar pas 1 layar
                        const Spacer(),

                        // 3. Form Input
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            children: [
                              _buildTextField(
                                hint: "Email Anda",
                                icon: Icons.person_outline,
                                isPassword: false,
                              ),
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                hint: "Kata Sandi",
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 12),

                              // 4. Remember Me & Forgot Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (val) {
                                            setState(() {
                                              _rememberMe = val ?? false;
                                            });
                                          },
                                          activeColor: AppColors.darkGreen,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          side: BorderSide(color: Colors.grey[400]!),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Ingat Saya",
                                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      "Lupa Kata Sandi?",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // 5. Tombol Masuk
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigasi ke Beranda dan hapus layar login dari riwayat (biar gak bisa di-back)
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MainNavigation()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Masuk",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const Spacer(),

                        // 6. Garis "Atau lanjutkan dengan"
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  "Atau lanjutkan dengan",
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 7. Tombol Social Login (Google & Apple)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              imageUrl: 'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
                              onTap: () {
                                print("Login with Google Ditekan");
                              },
                            ),
                            const SizedBox(width: 24),
                            _buildSocialButton(
                              imageUrl: 'https://cdn-icons-png.flaticon.com/512/731/731985.png',
                              onTap: () {
                                print("Login with Apple Ditekan");
                              },
                            ),
                          ],
                        ),
                        
                        const Spacer(),

                        // 8. Teks Daftar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Belum punya akun? ",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Navigasi ke halaman Register
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                );
                              },
                              child: const Text(
                                "Daftar",
                                style: TextStyle(
                                  color: AppColors.darkGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32), // Jarak aman bawah HP
                      ],
                    ),
                    
                    // ELEMEN DEKORASI BWD (Daun melayang di kanan pakai Asset Local)
                    Positioned(
                      right: -30,
                      top: 250, 
                      child: Opacity(
                        opacity: 0.85,
                        // MENGGUNAKAN IMAGE ASSET LOKAL
                        child: Image.asset(
                          'assets/images/tangkai-daun.png', 
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, required bool isPassword}) {
    return TextField(
      obscureText: isPassword ? !_isPasswordVisible : false,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 8.0),
          child: Icon(icon, color: AppColors.darkGreen, size: 20),
        ),
        suffixIcon: isPassword 
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ) 
            : null,
        filled: true,
        fillColor: const Color(0xFFE8F0E9),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Widget custom untuk tombol Social Login
  Widget _buildSocialButton({required String imageUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.network(
          imageUrl,
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 4, size.height, 
      size.width / 2, size.height - 30
    );
    path.quadraticBezierTo(
      size.width * 3 / 4, size.height - 60, 
      size.width, size.height - 20
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}