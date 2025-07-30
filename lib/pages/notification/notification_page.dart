import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sistem_monitoring_kontrol/pages/home/home_page.dart';
import 'package:sistem_monitoring_kontrol/pages/monitoring/monitoring_page.dart';
import 'package:sistem_monitoring_kontrol/pages/guide/guide_page.dart';
import 'package:sistem_monitoring_kontrol/pages/profile/profile_page.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _notifications = [];
  late DatabaseReference _notificationsRef;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notificationsRef = FirebaseDatabase.instance.ref('notifications');
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _notificationsRef.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        List<Map<String, dynamic>> notifications = [];

        if (data != null) {
          data.forEach((key, value) {
            notifications.add({
              'id': key,
              'timestamp': value['timestamp'],
              'type': value['type'],
              'status': value['status'],
              'message': value['message'],
              'isRead': value['isRead'] ?? false,
            });
          });

          // Sort by timestamp (newest first)
          notifications.sort(
            (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
          );
        }

        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationsRef.child(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.child(notificationId).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notifikasi berhasil dihapus',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus notifikasi: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    try {
      await _notificationsRef.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Semua notifikasi berhasil dihapus',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error deleting all notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus semua notifikasi: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteAllConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Hapus Semua Notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus semua notifikasi?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              child: Text(
                'Batal',
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
                'Hapus',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAllNotifications();
              },
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    // Group notifications by date
    Map<String, List<Map<String, dynamic>>> groupedNotifications = {};
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(Duration(days: 1)));

    for (var notification in _notifications) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        notification['timestamp'],
      );
      final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
      String group;

      if (dateKey == today) {
        group = 'Hari Ini';
      } else if (dateKey == yesterday) {
        group = 'Kemarin';
      } else {
        group = DateFormat('dd MMMM yyyy').format(timestamp);
      }

      if (!groupedNotifications.containsKey(group)) {
        groupedNotifications[group] = [];
      }
      groupedNotifications[group]!.add(notification);
    }

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
          'Notifikasi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _showDeleteAllConfirmationDialog,
              tooltip: 'Hapus Semua Notifikasi',
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : groupedNotifications.isEmpty
              ? Center(
                child: Text(
                  'Tidak ada notifikasi',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children:
                    groupedNotifications.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...entry.value.map((notification) {
                            return Column(
                              children: [
                                _buildNotificationCard(
                                  icon: _getIconForType(notification['type']),
                                  iconColor: _getIconColorForType(
                                    notification['type'],
                                  ),
                                  iconBgColor: _getIconColorForType(
                                    notification['type'],
                                  ).withOpacity(0.1),
                                  title:
                                      '${notification['type']} ${notification['status']}',
                                  subtitle: notification['message'],
                                  time: _formatTime(notification['timestamp']),
                                  isRead: notification['isRead'],
                                  notificationId: notification['id'],
                                  onTap: () {
                                    if (!notification['isRead']) {
                                      _markAsRead(notification['id']);
                                    }
                                  },
                                  onDelete: () {
                                    _deleteNotification(notification['id']);
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          }).toList(),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
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

  IconData _getIconForType(String type) {
    switch (type) {
      case 'pH':
        return Icons.blur_circular;
      case 'TDS':
        return Icons.scatter_plot_outlined;
      case 'Temperature':
        return Icons.thermostat;
      case 'Humidity':
        return Icons.water_drop_outlined;
      case 'WaterLevel':
        return Icons.waves;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'pH':
        return Colors.purple.shade600;
      case 'TDS':
        return Colors.teal.shade600;
      case 'Temperature':
        return Colors.orange.shade600;
      case 'Humidity':
        return Colors.blue.shade600;
      case 'WaterLevel':
        return Colors.indigo.shade600;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isRead,
    required String notificationId,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
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
            Row(
              children: [
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
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Hapus Notifikasi',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
