import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import package baru
import 'utils/app_colors.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KromaPadiApp());
}

class KromaPadiApp extends StatelessWidget {
  const KromaPadiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mulyaharja-KromaPadi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
        useMaterial3: true,
        // Terapkan font Poppins ke seluruh teks di aplikasi
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const OnboardingScreen(), 
    );
  }
}