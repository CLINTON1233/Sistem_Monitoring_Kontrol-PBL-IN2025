import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistem_monitoring_kontrol/pages/monitoring/monitoring_page.dart';
import 'package:sistem_monitoring_kontrol/pages/profile/profile_page.dart';
import 'package:sistem_monitoring_kontrol/pages/home/home_page.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  int _currentIndex = 2;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B715A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            }
          },
        ),
        title: Text(
          'Panduan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Guide Card 1 - Panduan Pengelolaan Tanaman
            _buildGuideCard(
              title: 'Panduan Pengelolaan Tanaman',
              subtitle: 'Pelajari Selengkapnya',
              image: 'assets/project.jpg', // Ganti dengan path gambar Anda
              onTap: () {
                // Navigate to plant management guide
                _showGuideDetail(
                  context,
                  'Panduan Pengelolaan Tanaman',
                  _getPlantManagementContent(),
                );
              },
            ),
            const SizedBox(height: 16),

            // Guide Card 2 - Panduan Pemberian Nutrisi Tanaman Hidroponik
            _buildGuideCard(
              title: 'Panduan Pemberian Nutrisi Tanaman Hidroponik',
              subtitle: 'Pelajari Selengkapnya',
              image: 'assets/jeje.jpg', // Ganti dengan path gambar Anda
              onTap: () {
                // Navigate to nutrition guide
                _showGuideDetail(
                  context,
                  'Panduan Pemberian Nutrisi Tanaman Hidroponik',
                  _getNutritionGuideContent(),
                );
              },
            ),
            const SizedBox(height: 16),

            // Additional Guide Cards
            _buildGuideCard(
              title: 'Panduan Monitoring Sistem',
              subtitle: 'Pelajari Selengkapnya',
              image: 'assets/greenhouse.jpg', // Ganti dengan path gambar Anda
              onTap: () {
                _showGuideDetail(
                  context,
                  'Panduan Monitoring Sistem',
                  _getMonitoringGuideContent(),
                );
              },
            ),
            const SizedBox(height: 16),

            _buildGuideCard(
              title: 'Panduan Troubleshooting',
              subtitle: 'Pelajari Selengkapnya',
              image: 'assets/pbl.jpg', // Ganti dengan path gambar Anda
              onTap: () {
                _showGuideDetail(
                  context,
                  'Panduan Troubleshooting',
                  _getTroubleshootingContent(),
                );
              },
            ),
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
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String subtitle,
    required String image,
    required VoidCallback onTap,
  }) {
    return Container(
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
                    'PANDUAN',
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

          // Image from assets
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
                image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback jika gambar tidak ditemukan
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
                            'Gambar tidak ditemukan',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF4B715A),
                              fontSize: 12,
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

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E2E2E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: onTap,
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
                              'Mulai',
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

  void _showGuideDetail(BuildContext context, String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuideDetailPage(title: title, content: content),
      ),
    );
  }

  String _getPlantManagementContent() {
    return '''
Panduan Lengkap Pengelolaan Tanaman Hidroponik

1. Persiapan Sistem
• Pastikan sistem hidroponik bersih dan steril
• Periksa semua komponen sistem (pompa, selang, dll)
• Siapkan larutan nutrisi dengan konsentrasi yang tepat

2. Penanaman
• Pilih bibit yang sehat dan berkualitas
• Gunakan media tanam yang sesuai (rockwool, perlite, dll)
• Tempatkan bibit dengan hati-hati pada sistem

3. Perawatan Harian
• Monitor pH dan EC larutan nutrisi
• Periksa kondisi tanaman secara visual
• Pastikan sistem sirkulasi berjalan dengan baik

4. Pemeliharaan Berkala
• Ganti larutan nutrisi setiap 1-2 minggu
• Bersihkan sistem secara berkala
• Pangkas daun yang layu atau rusak

5. Pemanenan
• Panen saat tanaman mencapai ukuran optimal
• Gunakan alat yang bersih untuk memotong
• Simpan hasil panen dengan cara yang tepat
    ''';
  }

  String _getNutritionGuideContent() {
    return '''
Panduan Pemberian Nutrisi Tanaman Hidroponik

1. Jenis Nutrisi
• Nutrisi makro: NPK (Nitrogen, Fosfor, Kalium)
• Nutrisi mikro: Fe, Mn, Zn, Cu, B, Mo
• Nutrisi tambahan sesuai jenis tanaman

2. Konsentrasi Nutrisi
• EC (Electrical Conductivity): 1.2-2.0 mS/cm
• pH: 5.5-6.5 untuk sebagian besar tanaman
• Sesuaikan dengan fase pertumbuhan tanaman

3. Pengaturan pH
• Gunakan pH meter untuk pengukuran akurat
• pH turun: tambahkan KOH atau Ca(OH)2
• pH naik: tambahkan asam sitrat atau H3PO4

4. Jadwal Pemberian
• Nutrisi diberikan secara kontinyu melalui sistem
• Ganti larutan nutrisi setiap 7-14 hari
• Monitor dan adjust konsentrasi setiap hari

5. Tanda Kekurangan Nutrisi
• Daun menguning: kekurangan nitrogen
• Pertumbuhan lambat: kekurangan fosfor
• Tepi daun coklat: kekurangan kalium
    ''';
  }

  String _getMonitoringGuideContent() {
    return '''
Panduan Monitoring Sistem Hidroponik

1. Parameter yang Dipantau
• Suhu air dan lingkungan
• pH dan EC larutan nutrisi
• Tingkat air dalam reservoir
• Kondisi pompa dan sistem sirkulasi

2. Frekuensi Monitoring
• Harian: pH, EC, suhu, kondisi visual tanaman
• Mingguan: pembersihan sistem, ganti larutan
• Bulanan: kalibrasi sensor, perawatan peralatan

3. Tools Monitoring
• pH meter dan EC meter
• Termometer digital
• Sensor otomatis (jika tersedia)
• Log book untuk pencatatan

4. Troubleshooting
• pH tidak stabil: periksa buffer dan kalibrasi
• EC terlalu tinggi/rendah: adjust konsentrasi nutrisi
• Suhu tidak optimal: gunakan heater/chiller

5. Pencatatan Data
• Catat semua parameter harian
• Buat grafik trend untuk analisis
• Simpan data untuk referensi masa depan
    ''';
  }

  String _getTroubleshootingContent() {
    return '''
Panduan Troubleshooting Sistem Hidroponik

1. Masalah Pompa
• Pompa tidak menyala: periksa power dan fuse
• Aliran lemah: bersihkan filter dan impeller
• Suara berisik: periksa bearing dan mounting

2. Masalah Nutrisi
• pH tidak stabil: ganti probe, kalibrasi ulang
• EC berfluktuasi: periksa kebersihan probe
• Endapan pada reservoir: bersihkan dan ganti larutan

3. Masalah Tanaman
• Daun layu: periksa akar dan sistem air
• Pertumbuhan lambat: cek nutrisi dan pencahayaan
• Hama dan penyakit: isolasi dan treatment

4. Masalah Listrik
• Sensor error: restart sistem, cek koneksi
• Display tidak normal: periksa power supply
• Alarm berbunyi: identifikasi penyebab dari kode error

5. Pencegahan
• Maintenance rutin sesuai jadwal
• Gunakan komponen berkualitas
• Backup power untuk sistem kritikal
• Training operator yang adequate
    ''';
  }
}

// Halaman detail panduan
class GuideDetailPage extends StatelessWidget {
  final String title;
  final String content;

  const GuideDetailPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B715A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: const Color(0xFF2E2E2E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
