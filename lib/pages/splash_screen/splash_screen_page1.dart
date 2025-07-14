import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistem_monitoring_kontrol/pages/splash_screen/splash_screen_page2.dart';

class SplashScreenPage1 extends StatefulWidget {
  const SplashScreenPage1({super.key});

  @override
  State<SplashScreenPage1> createState() => _SplashScreenPage1State();
}

class _SplashScreenPage1State extends State<SplashScreenPage1> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gambar sebagai latar belakang
          Positioned.fill(
            child: Image.asset(
              'assets/splashscreen.jpg', // Ganti sesuai nama file Anda
              fit: BoxFit.cover,
            ),
          ),

          // Lapisan gelap tipis agar teks lebih terbaca
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),

          // Konten utama
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    'Selamat Datang',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dari Sensor ke Panen — Semua dalam Genggaman.\n \nPantau Tanaman\nSekarang, kapanpun dan dimanapun.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B715A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SplashScreenPage2(),
                          ),
                        );
                      },
                      child: Text(
                        "Mulai Sekarang",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDot(isActive: true),
                        const SizedBox(width: 8),
                        _buildDot(isActive: false),
                        const SizedBox(width: 8),
                        _buildDot(isActive: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 28 : 10,
      height: 5,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
