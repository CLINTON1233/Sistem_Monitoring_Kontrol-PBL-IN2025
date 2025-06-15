// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Menyimpan data user setelah registrasi
  Future<void> saveUserData({
    required String userId,
    required String username,
    required String email,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menyimpan data user: $e');
    }
  }

  // Mengambil data user berdasarkan userId
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data user: $e');
    }
  }

  // Update data user
  Future<void> updateUserData({
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (data != null) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(userId).update(data);
      }
    } catch (e) {
      throw Exception('Gagal update data user: $e');
    }
  }

  // Cek apakah username sudah digunakan
  Future<bool> isUsernameExists(String username) async {
    try {
      QuerySnapshot query =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Gagal cek username: $e');
    }
  }
}
