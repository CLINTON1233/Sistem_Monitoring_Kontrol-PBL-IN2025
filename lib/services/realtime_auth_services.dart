import 'package:firebase_database/firebase_database.dart';

class RealtimeAuthService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      print('Mengambil data user dari path: users/$userId');
      DataSnapshot snapshot =
          await _databaseRef.child('users').child(userId).get();

      if (snapshot.exists) {
        print('Data ditemukan: ${snapshot.value}');
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
        return data?.map((key, value) => MapEntry(key.toString(), value));
      } else {
        print('Data tidak ditemukan untuk user: $userId');
        return null;
      }
    } catch (e) {
      print('Error dalam getUserData: $e');
      throw Exception("Error getting user data: $e");
    }
  }

  // Cek apakah username sudah ada
  Future<bool> isUsernameExists(String username) async {
    try {
      final snapshot =
          await _databaseRef
              .child('users')
              .orderByChild('username')
              .equalTo(username)
              .once();
      return snapshot.snapshot.value != null;
    } catch (e) {
      throw Exception("Error checking username: $e");
    }
  }

  // Simpan data user ke Realtime Database
  Future<void> saveUserData({
    required String userId,
    required String username,
    required String email,
  }) async {
    try {
      await _databaseRef.child('users').child(userId).set({
        'userId': userId,
        'username': username,
        'email': email,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception("Failed to save user data: $e");
    }
  }
}
