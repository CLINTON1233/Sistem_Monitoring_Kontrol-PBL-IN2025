// lib/services/realtime_guide_services.dart
import 'package:firebase_database/firebase_database.dart';

class RealtimeGuideService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Method untuk inisialisasi data panduan (jalankan sekali saja)
  Future<void> initializeGuideData() async {
    try {
      // Cek apakah data sudah ada
      final snapshot = await _database.child('guides').get();
      if (snapshot.exists) {
        print('Data panduan sudah ada di Firebase');
        return;
      }

      // Data panduan hidroponik
      Map<String, dynamic> guides = {
        'plant_management': {
          'title': 'Panduan Pengelolaan Tanaman',
          'subtitle': 'Pelajari Selengkapnya',
          'image': 'assets/project.jpg',
          'content': '''Panduan Lengkap Pengelolaan Tanaman Hidroponik

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
• Simpan hasil panen dengan cara yang tepat''',
          'category': 'PANDUAN',
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        },
        'nutrition_guide': {
          'title': 'Panduan Pemberian Nutrisi Tanaman Hidroponik',
          'subtitle': 'Pelajari Selengkapnya',
          'image': 'assets/jeje.jpg',
          'content': '''Panduan Pemberian Nutrisi Tanaman Hidroponik

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
• Tepi daun coklat: kekurangan kalium''',
          'category': 'PANDUAN',
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        },
        'monitoring_guide': {
          'title': 'Panduan Monitoring Sistem',
          'subtitle': 'Pelajari Selengkapnya',
          'image': 'assets/greenhouse.jpg',
          'content': '''Panduan Monitoring Sistem Hidroponik

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
• Simpan data untuk referensi masa depan''',
          'category': 'PANDUAN',
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        },
        'troubleshooting_guide': {
          'title': 'Panduan Troubleshooting',
          'subtitle': 'Pelajari Selengkapnya',
          'image': 'assets/pbl.jpg',
          'content': '''Panduan Troubleshooting Sistem Hidroponik

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
• Training operator yang adequate''',
          'category': 'PANDUAN',
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        },
      };

      // Simpan ke Firebase Realtime Database
      await _database.child('guides').set(guides);
      print('Data panduan berhasil diinisialisasi');
    } catch (e) {
      throw Exception('Gagal inisialisasi data panduan: $e');
    }
  }

  // Mengambil semua data panduan
  Future<List<Map<String, dynamic>>> getGuideData() async {
    try {
      DataSnapshot snapshot = await _database.child('guides').get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        return values.entries.map((entry) {
          final key = entry.key.toString();
          final value = Map<String, dynamic>.from(entry.value as Map);
          return {'id': key, ...value};
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal mengambil data panduan: $e');
    }
  }

  // Mengambil data panduan berdasarkan ID
  Future<Map<String, dynamic>?> getGuideById(String id) async {
    try {
      DataSnapshot snapshot = await _database.child('guides').child(id).get();
      if (snapshot.exists) {
        return {'id': id, ...snapshot.value as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data panduan: $e');
    }
  }

  // Search panduan berdasarkan title
  Future<List<Map<String, dynamic>>> searchGuide(String query) async {
    try {
      DataSnapshot snapshot = await _database.child('guides').get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        return values.entries
            .where((entry) {
              Map<String, dynamic> guide = entry.value as Map<String, dynamic>;
              return guide['title'].toString().toLowerCase().contains(
                query.toLowerCase(),
              );
            })
            .map((entry) {
              return {'id': entry.key, ...entry.value as Map<String, dynamic>};
            })
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal search panduan: $e');
    }
  }

  // Tambah panduan baru
  Future<void> addGuide(Map<String, dynamic> guideData) async {
    try {
      String newId = _database.child('guides').push().key!;
      guideData['createdAt'] = ServerValue.timestamp;
      guideData['updatedAt'] = ServerValue.timestamp;

      await _database.child('guides').child(newId).set(guideData);
    } catch (e) {
      throw Exception('Gagal menambah panduan: $e');
    }
  }

  // Update panduan
  Future<void> updateGuide(String id, Map<String, dynamic> guideData) async {
    try {
      guideData['updatedAt'] = ServerValue.timestamp;
      await _database.child('guides').child(id).update(guideData);
    } catch (e) {
      throw Exception('Gagal update panduan: $e');
    }
  }

  // Hapus panduan
  Future<void> deleteGuide(String id) async {
    try {
      await _database.child('guides').child(id).remove();
    } catch (e) {
      throw Exception('Gagal hapus panduan: $e');
    }
  }
}
