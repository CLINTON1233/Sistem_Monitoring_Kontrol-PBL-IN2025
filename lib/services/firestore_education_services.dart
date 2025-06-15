// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method untuk inisialisasi data edukasi (jalankan sekali saja)
  Future<void> initializeEducationData() async {
    try {
      // Cek apakah data sudah ada
      QuerySnapshot existingData =
          await _firestore.collection('education').get();
      if (existingData.docs.isNotEmpty) {
        print('Data edukasi sudah ada di Firebase');
        return;
      }

      // Data tanaman hidroponik
      List<Map<String, dynamic>> plants = [
        {
          'id': 'selada',
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },

        {
          'id': 'pakcoy',
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Sawi Hijau (Bok Choy)',
          'image': 'assets/sawi.jpg',
          'description':
              'Sawi hijau tumbuh dengan baik dalam sistem hidroponik',
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Simpan ke Firebase
      WriteBatch batch = _firestore.batch();
      for (var plant in plants) {
        DocumentReference docRef = _firestore
            .collection('education')
            .doc(plant['id']);
        batch.set(docRef, plant);
      }
      await batch.commit();

      print('Data edukasi berhasil diinisialisasi');
    } catch (e) {
      throw Exception('Gagal inisialisasi data edukasi: $e');
    }
  }

  // Mengambil semua data edukasi
  Future<List<Map<String, dynamic>>> getEducationData() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('education')
              .orderBy('createdAt', descending: false)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data edukasi: $e');
    }
  }

  // Mengambil data edukasi berdasarkan ID
  Future<Map<String, dynamic>?> getEducationById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('education').doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data edukasi: $e');
    }
  }

  // Search edukasi berdasarkan nama
  Future<List<Map<String, dynamic>>> searchEducation(String query) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('education')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThanOrEqualTo: query + '\uf8ff')
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception('Gagal search edukasi: $e');
    }
  }
}
