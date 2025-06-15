import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistem_monitoring_kontrol/pages/about_us/about_us_page.dart';
import 'package:sistem_monitoring_kontrol/pages/auth/login_page.dart';
import 'package:sistem_monitoring_kontrol/pages/monitoring/monitoring_page.dart';
import 'package:sistem_monitoring_kontrol/pages/guide/guide_page.dart';
import 'package:sistem_monitoring_kontrol/pages/profile/profile_page.dart';
import 'package:sistem_monitoring_kontrol/pages/home/home_page.dart';
import 'package:sistem_monitoring_kontrol/pages/statistic/statistic_page.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  // Data tanaman hidroponik
  final List<Map<String, dynamic>> _hydroponicPlants = [
    {
      'name': 'Pakcoy (Pak Choi)',
      'image': 'assets/pakcoy.jpg',
      'description':
          'Pakcoy memiliki nilai ekonomis tinggi dan mudah dibudidayakan',
      'details': '''Pakcoy adalah pilihan menguntungkan untuk hidroponik:

• Harga jual yang stabil dan tinggi di pasaran lokal maupun supermarket
• Pertumbuhan seragam, kompak, dan cocok untuk sistem hidroponik skala kecil maupun besar
• Relatif tahan terhadap serangan hama seperti ulat dan kutu daun
• pH larutan nutrisi optimal berada pada kisaran 6.0-6.8
• Cocok ditanam pada sistem rakit apung (floating raft), NFT, maupun sistem sumbu

Tips Implementasi:
- Pilih varietas yang sesuai dengan kondisi iklim lokal agar hasil maksimal
- Gunakan media tanam seperti rockwool dan siapkan tray semai
- Berikan jarak tanam ideal 15x15 cm agar daun tidak saling menutup
- Nutrisi EC yang dibutuhkan berkisar 1.0-1.5, cocok untuk pemula
- Panen dilakukan saat tinggi tanaman mencapai 15-20 cm, biasanya dalam 28-40 hari
- Pastikan sirkulasi udara di area penanaman baik untuk mencegah kelembapan berlebih''',
      'difficulty': 'Mudah',
      'harvestTime': '28-40 hari',
    },
    {
      'name': 'Selada (Lettuce)',
      'image': 'assets/selada2.jpg',
      'description':
          'Selada adalah tanaman yang sangat cocok untuk hidroponik pemula',
      'details':
          '''Selada merupakan salah satu tanaman terbaik untuk memulai hidroponik karena:

• Pertumbuhan cepat dengan waktu panen sekitar 30-45 hari
• Tidak membutuhkan nutrisi yang kompleks dan dapat tumbuh dengan baik hanya dengan NPK dasar
• Tahan terhadap fluktuasi pH di kisaran 6.0-7.0
• Cocok ditanam pada berbagai sistem hidroponik seperti NFT, DWC, dan wick system
• Sangat jarang terserang hama jika kebersihan sistem terjaga

Tips Implementasi:
- Gunakan rockwool atau cocopeat sebagai media tanam awal
- Pindahkan bibit ke sistem utama saat usia sekitar 7-10 hari
- Berikan pencahayaan alami atau lampu grow light selama 12-14 jam per hari
- Jaga suhu larutan nutrisi antara 18-22°C untuk hasil terbaik
- Panen dilakukan sebelum selada berbunga agar rasa tetap renyah dan tidak pahit
- Cocok untuk sistem hidroponik rumah tangga atau komersial kecil''',
      'difficulty': 'Mudah',
      'harvestTime': '30-45 hari',
    },
    {
      'name': 'Sawi Hijau (Bok Choy)',
      'image': 'assets/sawi.jpg',
      'description': 'Sawi hijau tumbuh dengan baik dalam sistem hidroponik',
      'details': '''Sawi hijau sangat populer dalam hidroponik karena:

• Mudah beradaptasi dengan berbagai sistem hidroponik seperti NFT, Kratky, dan DFT
• Kebutuhan nutrisi tidak terlalu tinggi sehingga ekonomis untuk dibudidayakan
• Tahan terhadap suhu panas dan sinar matahari langsung
• pH optimal untuk pertumbuhan 6.0-6.5
• Cocok untuk konsumsi harian keluarga atau dijual di pasar lokal

Tips Implementasi:
- Semai benih di media rockwool atau cocopeat selama 7-10 hari
- Pindahkan ke sistem hidroponik setelah memiliki 3-4 daun sejati
- Nutrisi EC berkisar antara 1.2-1.8 tergantung fase pertumbuhan
- Panen dapat dilakukan bertahap mulai dari daun bagian luar
- Hindari genangan air di area akar untuk mencegah pembusukan
- Lakukan rotasi tanam secara rutin agar suplai hasil tetap stabil''',
      'difficulty': 'Mudah',
      'harvestTime': '25-35 hari',
    },
    {
      'name': 'Bayam (Spinach)',
      'image': 'assets/bayam.jpg',
      'description': 'Bayam kaya nutrisi dan mudah tumbuh dalam hidroponik',
      'details':
          '''Bayam merupakan sayuran bergizi tinggi yang ideal untuk hidroponik:

• Mengandung zat besi, magnesium, dan vitamin A, C, dan K yang tinggi
• Cocok untuk konsumsi keluarga atau dijual dalam bentuk segar
• Dapat dipanen berkali-kali menggunakan metode cut and come again
• pH larutan optimal antara 6.0-7.0
• Toleran terhadap pencahayaan rendah dan suhu yang bervariasi

Tips Implementasi:
- Benih dapat disemai langsung pada media tanam akhir
- Jaga kelembaban tetap stabil terutama pada masa awal pertumbuhan
- Berikan nutrisi seimbang yang mengandung NPK dan mikronutrien
- Panen daun muda secara berkala untuk menjaga pertumbuhan optimal
- Hindari stres air atau kekeringan yang dapat menurunkan kualitas daun
- Cocok untuk sistem vertikal maupun horizontal skala rumah tangga''',
      'difficulty': 'Sedang',
      'harvestTime': '21-30 hari',
    },
    {
      'name': 'Seledri (Celery)',
      'image': 'assets/seledri.jpg',
      'description':
          'Seledri cocok untuk hidroponik meski memerlukan waktu lebih lama untuk tumbuh',
      'details':
          '''Seledri merupakan tanaman daun aromatik yang banyak digunakan sebagai bumbu dapur:

• Memiliki nilai jual yang tinggi di pasar lokal dan restoran
• Tahan terhadap penyakit tertentu jika lingkungan bersih
• Membutuhkan waktu tanam yang panjang dan konsisten dalam perawatan
• pH optimal antara 5.8-6.5 untuk penyerapan nutrisi maksimal
• Cocok untuk sistem NFT, rakit apung, dan drip irrigation

Tips Implementasi:
- Gunakan rockwool untuk semai benih dan pindahkan ke sistem hidroponik setelah 3 minggu
- Cahaya matahari atau grow light selama 14-16 jam per hari dibutuhkan untuk pertumbuhan maksimal
- Nutrisi EC ideal sekitar 1.2-1.8, tergantung usia tanaman
- Jaga kelembaban udara tetap tinggi untuk mencegah pengeringan daun
- Panen dilakukan setelah 90-120 hari, biasanya saat batang mengeras dan daun tumbuh rimbun
- Seledri cocok ditanam bersamaan dengan tanaman pelindung untuk meminimalkan stress lingkungan''',
      'difficulty': 'Sulit',
      'harvestTime': '90-120 hari',
    },
    {
      'name': 'Tomat (Tomato)',
      'image': 'assets/tomat.jpg',
      'description':
          'Tomat membutuhkan perawatan khusus namun hasilnya sangat menjanjikan',
      'details':
          '''Tomat merupakan salah satu komoditas hortikultura dengan permintaan tinggi:

• Potensi hasil panen tinggi jika penyerbukan dan nutrisi dikontrol dengan baik
• Rentan terhadap serangan hama seperti kutu daun dan jamur, sehingga butuh pengawasan ketat
• Butuh penyangga atau ajir karena batang dan buah bisa tumbuh besar dan berat
• pH optimal antara 5.5-6.5 untuk mendukung pertumbuhan akar dan pembungaan
• Sangat cocok untuk sistem DWC besar atau drip irrigation otomatis

Tips Implementasi:
- Gunakan varietas tomat cherry atau jenis yang tumbuh pendek (determinate)
- Tanam pada netpot ukuran besar dengan media tanam seperti hydroton atau perlit
- Sediakan pencahayaan minimal 12 jam per hari, lebih baik jika ditambah cahaya tambahan
- Nutrisi EC bervariasi: 2.0 pada awal pertumbuhan, hingga 3.5 saat berbuah
- Pangkas daun bawah dan batang yang tidak produktif untuk memperbaiki sirkulasi udara
- Panen dilakukan saat buah berwarna merah merata dan keras, biasanya setelah 75-90 hari
- Pastikan sistem penyangga kuat untuk menopang beban buah yang lebat''',
      'difficulty': 'Menengah',
      'harvestTime': '75-90 hari',
    },
  ];

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
        return; // Sudah di halaman ini
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B715A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 24),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          'Edukasi Hidroponik',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:
              _hydroponicPlants.map((plant) => _buildPlantCard(plant)).toList(),
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

  Widget _buildPlantCard(Map<String, dynamic> plant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            margin: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'EDUKASI',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Plant Image - PERBAIKAN DI SINI
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                plant['image'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                // Tambahkan error handling yang lebih baik
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: ${plant['image']} - $error');
                  return Container(
                    height: 200,
                    color: const Color(0xFFF0F4F0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 48,
                            color: const Color(0xFF4B715A),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plant['name'],
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF4B715A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Gambar tidak ditemukan',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Plant Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E2E2E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plant['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Tags
                Row(
                  children: [
                    _buildTag(plant['difficulty'], Colors.blue),
                    const SizedBox(width: 8),
                    _buildTag(plant['harvestTime'], Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),

                // Baca Selengkapnya Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pelajari Selengkapnya',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _showPlantDetail(plant);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Baca Selengkapnya',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showPlantDetail(Map<String, dynamic> plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plant['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),

                          // Plant Image
                          Container(
                            width: double.infinity,
                            height: 200,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                plant['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.green[100],
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.eco,
                                          color: Colors.green[600],
                                          size: 80,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          plant['name'],
                                          style: GoogleFonts.poppins(
                                            color: Colors.green[800],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Details
                          Text(
                            plant['details'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4B715A), Color(0xFF4B715A)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Text(
                        'JA',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B715A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Jelita Agnesia',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'jelitaagnesia@email.com',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home_outlined,
                  title: 'Beranda',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  },
                  isActive: false,
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'Tentang Kami',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AboutUsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.show_chart,
                  title: 'Statistik',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => StatisticPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assignment_outlined,
                  title: 'Edukasi',
                  onTap: () {
                    Navigator.pop(context);
                  },
                  isActive: true,
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                  isLogout: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(30),
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isLogout
                  ? Colors.red
                  : isActive
                  ? Colors.green
                  : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color:
                isLogout
                    ? Colors.red
                    : isActive
                    ? Colors.green
                    : Colors.black87,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Apakah Kamu Yakin ingin Melakukan Logout?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              child: Text(
                'Tidak, Batalkan!',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Ya',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar('Logout Berhasil');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
