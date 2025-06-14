import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:sistem_monitoring_kontrol/pages/splash_screen/splash_screen_page1.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  final String fullText = 'HYDROGREEN';
  String displayedText = '';
  int currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (currentIndex < fullText.length) {
        setState(() {
          displayedText += fullText[currentIndex];
          currentIndex++;
        });
      } else {
        _timer.cancel();
        // Navigasi ke halaman lain setelah animasi selesai (opsional)
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SplashScreenPage1()),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B715A), // Warna hijau dari gambar
      body: Center(
        child: RichText(
          text: TextSpan(
            children:
                displayedText.split('').map((char) {
                  bool isGreen = 'GREEN'.contains(char.toUpperCase());
                  return TextSpan(
                    text: char,
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                      color: isGreen ? const Color(0xFFA7DAB5) : Colors.white,
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
