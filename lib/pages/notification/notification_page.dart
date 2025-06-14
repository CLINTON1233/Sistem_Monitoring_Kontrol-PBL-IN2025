import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistem_monitoring_kontrol/pages/monitoring/monitoring_page.dart';
import 'package:sistem_monitoring_kontrol/pages/guide/guide_page.dart';
import 'package:sistem_monitoring_kontrol/pages/profile/profile_page.dart';
import 'package:sistem_monitoring_kontrol/pages/home/home_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _currentIndex = 0;

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
            // Perbaikan: Check apakah bisa pop, jika tidak navigate ke HomePage
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
          'Notifikasi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Hari Ini
          Text(
            'Hari Ini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Notifikasi TDS Tinggi
          _buildNotificationCard(
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue.withOpacity(0.1),
            title: 'TDS Level Tinggi',
            subtitle:
                'Nilai TDS mencapai 1250 ppm\nDisarankan untuk mengurangi nutrisi',
            time: '5 menit lalu',
            isRead: false,
          ),

          const SizedBox(height: 12),

          // Notifikasi pH Rendah
          _buildNotificationCard(
            icon: Icons.science,
            iconColor: Colors.orange,
            iconBgColor: Colors.orange.withOpacity(0.1),
            title: 'pH Level Rendah',
            subtitle: 'Nilai pH turun ke 5.2\nTambahkan larutan pH up',
            time: '12 menit lalu',
            isRead: true,
          ),

          const SizedBox(height: 12),

          // Notifikasi Suhu & Kelembaban
          _buildNotificationCard(
            icon: Icons.thermostat,
            iconColor: Colors.red,
            iconBgColor: Colors.red.withOpacity(0.1),
            title: 'Suhu Tinggi',
            subtitle: 'Suhu mencapai 32°C\nAktifkan ventilasi otomatis',
            time: '18 menit lalu',
            isRead: false,
          ),

          const SizedBox(height: 20),

          // Section Kemarin
          Text(
            'Kemarin',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Notifikasi Water Level
          _buildNotificationCard(
            icon: Icons.water,
            iconColor: Colors.cyan,
            iconBgColor: Colors.cyan.withOpacity(0.1),
            title: 'Level Air Rendah',
            subtitle:
                'Ketinggian air reservoir 15cm\nSegera isi ulang tandon air',
            time: '2 jam lalu',
            isRead: true,
          ),

          const SizedBox(height: 12),

          // Notifikasi pH Normal
          _buildNotificationCard(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            iconBgColor: Colors.green.withOpacity(0.1),
            title: 'pH Level Normal',
            subtitle:
                'Nilai pH kembali stabil di 6.2\nSistem hidroponik optimal',
            time: '4 jam lalu',
            isRead: true,
          ),

          const SizedBox(height: 12),

          // Notifikasi TDS Stabil
          _buildNotificationCard(
            icon: Icons.waves,
            iconColor: Colors.indigo,
            iconBgColor: Colors.indigo.withOpacity(0.1),
            title: 'TDS Level Stabil',
            subtitle:
                'Nilai TDS dalam rentang ideal 800-1000 ppm\nNutrisi tanaman tercukupi',
            time: '6 jam lalu',
            isRead: true,
          ),
          const SizedBox(height: 15),
        ],
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

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isRead,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Read indicator
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
