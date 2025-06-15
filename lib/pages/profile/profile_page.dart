import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistem_monitoring_kontrol/pages/monitoring/monitoring_page.dart';
import 'package:sistem_monitoring_kontrol/pages/guide/guide_page.dart';
import 'package:sistem_monitoring_kontrol/pages/home/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sistem_monitoring_kontrol/services/firestore_auth_services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  bool _isLoading = false;
  int _currentIndex = 3;

  // Controllers untuk form
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State untuk visibility password
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserData(); // Load data dari Firebase
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, dynamic>? userData = await _firestoreService.getUserData(
          _currentUser!.uid,
        );
        if (userData != null) {
          _usernameController.text = userData['username'] ?? '';
          _emailController.text =
              userData['email'] ?? _currentUser!.email ?? '';
        } else {
          _emailController.text = _currentUser!.email ?? '';
        }
      } catch (e) {
        _showSnackBar('Gagal memuat data: $e'); // Error = merah
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = HomePage();
        break;
      case 1:
        page = MonitoringPage();
        break;
      case 2:
        page = GuidePage();
        break;
      case 3:
        page = ProfilePage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) {
      _showSnackBar('User tidak ditemukan'); // Error = merah
      return;
    }

    // Validasi form tidak kosong
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Username dan Email harus diisi'); // Error = merah
      return;
    }

    // Validasi password jika diisi
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar(
          'Password dan konfirmasi password tidak cocok',
        ); // Error = merah
        return;
      }

      if (_passwordController.text.length < 6) {
        _showSnackBar('Password minimal 6 karakter'); // Error = merah
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ... kode lainnya ...

      // Cek username sudah digunakan
      bool usernameExists = await _firestoreService.isUsernameExists(
        _usernameController.text,
      );
      if (usernameExists) {
        Map<String, dynamic>? currentUserData = await _firestoreService
            .getUserData(_currentUser!.uid);
        if (currentUserData == null ||
            currentUserData['username'] != _usernameController.text) {
          _showSnackBar('Username sudah digunakan'); // Error = merah
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Update email di Firebase Auth jika berubah
      if (_emailController.text != _currentUser!.email) {
        await _currentUser!.updateEmail(_emailController.text);
      }

      // Update password jika diisi
      if (_passwordController.text.isNotEmpty) {
        await _currentUser!.updatePassword(_passwordController.text);
      }

      // Update data di Firestore
      await _firestoreService.updateUserData(
        userId: _currentUser!.uid,
        data: {
          'username': _usernameController.text,
          'email': _emailController.text,
        },
      );

      // Clear password fields setelah berhasil
      _passwordController.clear();
      _confirmPasswordController.clear();

      _showSnackBar(
        'Profil berhasil disimpan',
        isSuccess: true,
      ); // Success = hijau
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'requires-recent-login':
          errorMessage = 'Silakan login ulang untuk mengubah email/password';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email sudah digunakan akun lain';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid';
          break;
        case 'weak-password':
          errorMessage = 'Password terlalu lemah';
          break;
        default:
          errorMessage = 'Terjadi kesalahan: ${e.message}';
      }

      _showSnackBar(errorMessage); // Error = merah
    } catch (e) {
      _showSnackBar('Gagal menyimpan profil: $e'); // Error = merah
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF2D3748),
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan $label Baru',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFA0AEC0),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon:
                  isPassword
                      ? IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black,
                        ),
                        onPressed: onTogglePassword,
                      )
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B715A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4B715A)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    // Profile Picture Section tetap sama
                    const SizedBox(height: 5),
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                          ),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey[600],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4B715A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Form Fields tetap sama
                    _buildTextField(
                      label: 'Username',
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 15),

                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),

                    _buildTextField(
                      label: 'Kata Sandi',
                      controller: _passwordController,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onTogglePassword: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildTextField(
                      label: 'Konfirmasi Kata Sandi',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      isPasswordVisible: _isConfirmPasswordVisible,
                      onTogglePassword: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Save Button dengan loading state
                    SizedBox(
                      width: 145,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B715A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Simpan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onBottomNavTap,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Monitoring',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Panduan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
