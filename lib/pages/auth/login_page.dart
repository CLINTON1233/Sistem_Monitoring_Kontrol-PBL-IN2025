import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:sistem_monitoring_kontrol/pages/auth/register_page.dart';
import 'package:sistem_monitoring_kontrol/pages/home/home_page.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isObscured = true;

  void _showCustomSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: Image.asset('assets/project.jpg', fit: BoxFit.cover),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email),
                            hintText: 'Alamat Email',
                            border: const UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: isObscured,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            hintText: 'Kata Sandi',
                            border: const UnderlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isObscured
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  isObscured = !isObscured;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tombol Login
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4B715A),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();

                              if (email.isEmpty || password.isEmpty) {
                                _showCustomSnackBar(
                                  "Email dan Password wajib diisi",
                                );
                                return;
                              }

                              try {
                                // UserCredential userCredential =
                                //     await FirebaseAuth.instance
                                //         .signInWithEmailAndPassword(
                                //           email: email,
                                //           password: password,
                                //         );

                                _showCustomSnackBar(
                                  "Login berhasil!",
                                  isSuccess: true,
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomePage(),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                String message = "Terjadi kesalahan";

                                if (e.code == 'user-not-found') {
                                  message = "Akun tidak ditemukan";
                                } else if (e.code == 'wrong-password') {
                                  message = "Password salah";
                                } else if (e.code == 'invalid-email') {
                                  message = "Email tidak valid";
                                }

                                _showCustomSnackBar(message);
                              }
                            },
                            child: Text(
                              "Login",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Ajak Daftar
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "Belum punya akun? ",
                              style: GoogleFonts.poppins(color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: 'Daftar Sekarang',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const RegisterPage(),
                                            ),
                                          );
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
