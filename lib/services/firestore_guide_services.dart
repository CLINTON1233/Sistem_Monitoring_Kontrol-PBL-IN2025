// lib/services/firestore_guide_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreGuideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method untuk inisialisasi data panduan (jalankan sekali saja)
  Future<void> initializeGuideData() async {
    try {
      // Cek apakah data sudah ada
      QuerySnapshot existingData = await _firestore.collection('guides').get();
      if (existingData.docs.isNotEmpty) {
        print('Data panduan sudah ada di Firebase');
        return;
      }

      // Data panduan hidroponik
      List<Map<String, dynamic>> guides = [
        {
          'id': 'plant_management',
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'nutrition_guide',
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'monitoring_guide',
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'troubleshooting_guide',
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Simpan ke Firebase
      WriteBatch batch = _firestore.batch();
      for (var guide in guides) {
        DocumentReference docRef = _firestore
            .collection('guides')
            .doc(guide['id']);
        batch.set(docRef, guide);
      }
      await batch.commit();

      print('Data panduan berhasil diinisialisasi');
    } catch (e) {
      throw Exception('Gagal inisialisasi data panduan: $e');
    }
  }

  // Mengambil semua data panduan
  Future<List<Map<String, dynamic>>> getGuideData() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('guides')
              .orderBy('createdAt', descending: false)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data panduan: $e');
    }
  }

  // Mengambil data panduan berdasarkan ID
  Future<Map<String, dynamic>?> getGuideById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('guides').doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data panduan: $e');
    }
  }

  // Search panduan berdasarkan title
  Future<List<Map<String, dynamic>>> searchGuide(String query) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('guides')
              .where('title', isGreaterThanOrEqualTo: query)
              .where('title', isLessThanOrEqualTo: query + '\uf8ff')
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Gagal search panduan: $e');
    }
  }

  // Tambah panduan baru
  Future<void> addGuide(Map<String, dynamic> guideData) async {
    try {
      guideData['createdAt'] = FieldValue.serverTimestamp();
      guideData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('guides').add(guideData);
    } catch (e) {
      throw Exception('Gagal menambah panduan: $e');
    }
  }

  // Update panduan
  Future<void> updateGuide(String id, Map<String, dynamic> guideData) async {
    try {
      guideData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('guides').doc(id).update(guideData);
    } catch (e) {
      throw Exception('Gagal update panduan: $e');
    }
  }

  // Hapus panduan
  Future<void> deleteGuide(String id) async {
    try {
      await _firestore.collection('guides').doc(id).delete();
    } catch (e) {
      throw Exception('Gagal hapus panduan: $e');
    }
  }
}
