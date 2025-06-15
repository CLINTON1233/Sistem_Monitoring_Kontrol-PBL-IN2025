import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistem_monitoring_kontrol/pages/auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sistem_monitoring_kontrol/services/firestore_auth_services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  bool isObscuredPassword = true;
  bool isObscuredConfirm = true;
  bool isLoading = false;

  // SnackBar serbaguna
  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Validasi form
  bool _validateForm() {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar("Semua field wajib diisi");
      return false;
    }

    if (username.length < 3) {
      _showSnackBar("Username minimal 3 karakter");
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Format email tidak valid");
      return false;
    }

    if (password.length < 6) {
      _showSnackBar("Password minimal 6 karakter");
      return false;
    }

    if (password != confirmPassword) {
      _showSnackBar("Password tidak cocok");
      return false;
    }

    return true;
  }

  Future<void> _registerUser() async {
    if (!_validateForm()) return;

    setState(() {
      isLoading = true;
    });

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      bool usernameExists = await _firestoreService.isUsernameExists(username);
      if (usernameExists) {
        _showSnackBar("Username sudah digunakan");
        setState(() {
          isLoading = false;
        });
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestoreService.saveUserData(
        userId: userCredential.user!.uid,
        username: username,
        email: email,
      );

      await userCredential.user!.updateDisplayName(username);

      _showSnackBar("Registrasi berhasil!", isSuccess: true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan";

      switch (e.code) {
        case 'email-already-in-use':
          message = "Email sudah digunakan";
          break;
        case 'invalid-email':
          message = "Email tidak valid";
          break;
        case 'weak-password':
          message = "Password terlalu lemah";
          break;
        case 'operation-not-allowed':
          message = "Operasi tidak diizinkan";
          break;
        default:
          message = "Terjadi kesalahan: ${e.message}";
      }

      _showSnackBar(message);
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
      backgroundColor: const Color(0xFFF6F9F8),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset(
                    'assets/project.jpg',
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar',
                          style: GoogleFonts.poppins(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: usernameController,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            hintText: 'Username (minimal 3 karakter)',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: emailController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            hintText: 'Email',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          enabled: !isLoading,
                          obscureText: isObscuredPassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            hintText: 'Kata Sandi (minimal 6 karakter)',
                            border: const UnderlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isObscuredPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  isObscuredPassword = !isObscuredPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: confirmPasswordController,
                          enabled: !isLoading,
                          obscureText: isObscuredConfirm,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            hintText: 'Konfirmasi Kata Sandi',
                            border: const UnderlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isObscuredConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  isObscuredConfirm = !isObscuredConfirm;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

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
                            onPressed: isLoading ? null : _registerUser,
                            child:
                                isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      "Daftar",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            GestureDetector(
                              onTap:
                                  isLoading
                                      ? null
                                      : () {
                                        Navigator.pop(context);
                                      },
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isLoading
                                          ? Colors.grey
                                          : Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
