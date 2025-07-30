import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistem_monitoring_kontrol/pages/about_us/about_us_page.dart';
import 'package:sistem_monitoring_kontrol/pages/auth/login_page.dart';
import 'package:sistem_monitoring_kontrol/pages/education/education_page.dart';
import 'package:sistem_monitoring_kontrol/pages/guide/guide_page.dart';
import 'package:sistem_monitoring_kontrol/pages/notification/notification_page.dart';
import 'package:sistem_monitoring_kontrol/pages/monitoring/monitoring_page.dart';
import 'package:sistem_monitoring_kontrol/pages/statistic/statistic_page.dart';
import 'package:sistem_monitoring_kontrol/pages/profile/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sistem_monitoring_kontrol/services/realtime_auth_services.dart';
import 'package:sistem_monitoring_kontrol/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:sistem_monitoring_kontrol/utils/datetime_extensions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DatabaseReference _databaseRef;
  bool _isFirebaseInitialized = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _currentLocation = 'Batam, Indonesia';
  double _currentTemperature = 28.0;
  String _weatherDescription = 'Cerah';
  bool _isLoadingWeather = true;

  final RealtimeAuthService _realtimeAuthService = RealtimeAuthService();

  bool isSwitched = false;
  int _currentIndex = 0;
  bool _isPumpOn = false;
  bool _isFirebaseConnected = false;

  // Variabel untuk data sensor
  double _phValue = 0.0;
  double _tdsValue = 0.0;
  double _waterHeight = 0.0;
  double _temperature = 0.0;
  double _humidity = 0.0;

  // Chart data
  List<FlSpot> _tempSpots = [];
  List<String> _timeLabels = [];
  Timer? _chartUpdateTimer;
  DateTime _lastUpdateTime = DateTime.now();

  // Variabel untuk data user session
  String _username = 'Loading...';
  String _email = 'Loading...';
  String _currentDate = '';
  String _currentDay = '';

  // Jumlah notifikasi belum dibaca
  int _unreadNotificationCount = 0;
  late DatabaseReference _notificationsRef;

  // Database reference for sensor data
  late DatabaseReference _sensorRef;
  late DatabaseReference _controlRef;
  late StreamSubscription<DatabaseEvent> _sensorSubscription;
  late StreamSubscription<DatabaseEvent> _controlSubscription;
  late StreamSubscription<DatabaseEvent> _notificationSubscription;

  // Debouncing untuk notifikasi
  Map<String, DateTime> _lastNotificationTimes = {};

  Color _getPumpStatusColor() {
    if (_tdsValue < 300) {
      return Colors.red;
    } else if (_tdsValue < 700) {
      return Colors.orange;
    } else if (_tdsValue < 900) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  String _getPumpStatusText() {
    if (_tdsValue < 300) {
      return 'Pompa sedang menyalurkan nutrisi dengan cepat';
    } else if (_tdsValue < 700) {
      return 'Pompa sedang menyalurkan nutrisi';
    } else if (_tdsValue < 900) {
      return 'Pompa bekerja dengan lambat';
    } else {
      return 'Pompa dalam keadaan standby';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadUserData();
    _setCurrentDate();
    _loadLocationAndWeather();
    _chartUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _updateChartData();
    });
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _databaseRef = FirebaseDatabase.instance.ref('RIWAYAT');
      _sensorRef = FirebaseDatabase.instance.ref('HQ/SENSOR');
      _controlRef = FirebaseDatabase.instance.ref('HQ/CONTROL');
      _notificationsRef = FirebaseDatabase.instance.ref('notifications');

      _setupFirebaseListeners();

      setState(() {
        _isFirebaseInitialized = true;
        _isFirebaseConnected = true;
      });
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      setState(() {
        _isFirebaseConnected = false;
      });
    }
  }

  void _setupFirebaseListeners() {
    _sensorSubscription = _sensorRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          _handleSensorData(data);
        }
      },
      onError: (error) {
        print('Error listening to sensor data: $error');
        setState(() {
          _isFirebaseConnected = false;
        });
        Future.delayed(Duration(seconds: 5), _initializeFirebase);
      },
    );

    _controlSubscription = _controlRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Handle control data if needed
        }
      },
      onError: (error) {
        print('Error listening to control data: $error');
      },
    );

    _notificationSubscription = _notificationsRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        int unreadCount = 0;
        if (data != null) {
          data.forEach((key, value) {
            if (!(value['isRead'] ?? false)) {
              unreadCount++;
            }
          });
        }
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      },
      onError: (error) {
        print('Error listening to notifications: $error');
      },
    );
  }

  void _handleSensorData(Map<dynamic, dynamic> data) {
    try {
      double parseValue(dynamic value) {
        final parsed = double.tryParse(value.toString()) ?? 0.0;
        if (parsed < 0) return 0.0;
        return parsed;
      }

      setState(() {
        _phValue = parseValue(data['ph']);
        _tdsValue = parseValue(data['ppm'] ?? data['tds']);
        _waterHeight = parseValue(data['tinggi_air'] ?? data['tinggi'] ?? 0.0);
        _temperature = parseValue(data['suhu']);
        _humidity = parseValue(data['kelembaban']);
        _updateChartData();
        _isFirebaseConnected = true;
      });

      _sendWeeklyStatsToFirebase();
      _checkAndSendNotifications();
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  Future<void> _sendWeeklyStatsToFirebase() async {
    try {
      final now = DateTime.now();
      final weekKey = '${now.year}-${now.weekOfYear}';
      final dayOfWeek = now.weekday - 1;
      final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

      final statsRef = FirebaseDatabase.instance.ref(
        'statistics/$weekKey/days/$dayOfWeek',
      );

      final snapshot = await statsRef.get();
      Map<String, dynamic> currentData = {};

      if (snapshot.exists) {
        currentData = Map<String, dynamic>.from(snapshot.value as Map);
      }

      await statsRef.update({
        'day_name': dayNames[dayOfWeek],
        'temperature': _temperature,
        'humidity': _humidity,
        'ph': _phValue,
        'tds': _tdsValue,
        'water_level': _waterHeight,
        'last_updated': ServerValue.timestamp,
        ...currentData,
      });

      print('Data statistik mingguan berhasil dikirim ke Firebase');
    } catch (e) {
      print('Gagal mengirim statistik mingguan ke Firebase: $e');
    }
  }

  void _checkAndSendNotifications() async {
    final now = DateTime.now();
    final notificationsRef = FirebaseDatabase.instance.ref('notifications');

    void showSnackBar(String message, Color bgColor) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            top: 10,
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).size.height - 100,
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }

    void sendNotification(
      String type,
      String status,
      String message,
      Color bgColor,
    ) async {
      // Debouncing: Pastikan notifikasi untuk tipe yang sama tidak dikirim terlalu sering
      if (_lastNotificationTimes.containsKey(type) &&
          now.difference(_lastNotificationTimes[type]!).inMinutes < 10) {
        return;
      }

      await notificationsRef.push().set({
        'timestamp': ServerValue.timestamp,
        'type': type,
        'status': status,
        'message': message,
        'isRead': false,
      });

      _lastNotificationTimes[type] = now;
      showSnackBar(message, bgColor);
    }

    // pH (optimal untuk hidroponik: 5.5-6.5)
    if (_phValue < 5.5) {
      sendNotification(
        'pH',
        'Low',
        'Nilai pH turun ke ${_phValue.toStringAsFixed(1)}. Tambahkan larutan pH up.',
        Colors.orange,
      );
    } else if (_phValue > 6.5) {
      sendNotification(
        'pH',
        'High',
        'Nilai pH mencapai ${_phValue.toStringAsFixed(1)}. Tambahkan larutan pH down.',
        Colors.red,
      );
    }

    // TDS (optimal untuk hidroponik: 500-1000 ppm)
    if (_tdsValue < 500) {
      sendNotification(
        'TDS',
        'Low',
        'Nilai TDS turun ke ${_tdsValue.toStringAsFixed(0)} ppm. Tambahkan nutrisi.',
        Colors.orange,
      );
    } else if (_tdsValue > 1000) {
      sendNotification(
        'TDS',
        'High',
        'Nilai TDS mencapai ${_tdsValue.toStringAsFixed(0)} ppm. Kurangi nutrisi.',
        Colors.red,
      );
    }

    // Suhu (optimal untuk hidroponik: 20-28°C)
    if (_temperature < 20) {
      sendNotification(
        'Temperature',
        'Low',
        'Suhu turun ke ${_temperature.toStringAsFixed(1)}°C. Tingkatkan suhu lingkungan.',
        Colors.blue,
      );
    } else if (_temperature > 28) {
      sendNotification(
        'Temperature',
        'High',
        'Suhu mencapai ${_temperature.toStringAsFixed(1)}°C. Aktifkan ventilasi.',
        Colors.red,
      );
    }

    // Kelembaban (optimal untuk hidroponik: 50-70%)
    if (_humidity < 50) {
      sendNotification(
        'Humidity',
        'Low',
        'Kelembaban turun ke ${_humidity.toStringAsFixed(0)}%. Tingkatkan kelembaban.',
        Colors.blue,
      );
    } else if (_humidity > 70) {
      sendNotification(
        'Humidity',
        'High',
        'Kelembaban mencapai ${_humidity.toStringAsFixed(0)}%. Kurangi kelembaban.',
        Colors.red,
      );
    }

    // Ketinggian Air (sesuaikan dengan kebutuhan sistem, misal 15-25 cm)
    if (_waterHeight < 15) {
      sendNotification(
        'WaterLevel',
        'Low',
        'Ketinggian air turun ke ${_waterHeight.toStringAsFixed(1)} cm. Isi ulang tandon air.',
        Colors.cyan,
      );
    } else if (_waterHeight > 25) {
      sendNotification(
        'WaterLevel',
        'High',
        'Ketinggian air mencapai ${_waterHeight.toStringAsFixed(1)} cm. Kurangi volume air.',
        Colors.red,
      );
    }
  }

  void _updateChartData() {
    if (_tempSpots.length >= 10) {
      _tempSpots.removeAt(0);
      _timeLabels.removeAt(0);

      for (int i = 0; i < _tempSpots.length; i++) {
        _tempSpots[i] = FlSpot(i.toDouble(), _tempSpots[i].y);
      }
    }

    double newX = _tempSpots.length.toDouble();
    _tempSpots.add(FlSpot(newX, _temperature));

    if (_timeLabels.isEmpty) {
      _lastUpdateTime = DateTime.now();
    }
    _lastUpdateTime = _lastUpdateTime.add(Duration(seconds: 10));
    _timeLabels.add(
      '${_lastUpdateTime.hour.toString().padLeft(2, '0')}:${_lastUpdateTime.minute.toString().padLeft(2, '0')}:${_lastUpdateTime.second.toString().padLeft(2, '0')}',
    );

    setState(() {});
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Map<String, dynamic>? userData = await _realtimeAuthService.getUserData(
          currentUser.uid,
        );

        if (userData != null) {
          setState(() {
            _username = userData['username'] ?? 'User';
            _email = userData['email'] ?? currentUser.email ?? 'No Email';
          });
        } else {
          setState(() {
            _username =
                currentUser.displayName ??
                currentUser.email?.split('@').first ??
                'User';
            _email = currentUser.email ?? 'No Email';
          });

          if (currentUser.email != null) {
            await _realtimeAuthService.saveUserData(
              userId: currentUser.uid,
              username: _username,
              email: _email,
            );
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _username = 'User';
        _email = 'No Email';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  void _setCurrentDate() {
    DateTime now = DateTime.now();
    List<String> days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    List<String> months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    setState(() {
      _currentDay = days[now.weekday % 7];
      _currentDate =
          '$_currentDay, ${now.day} ${months[now.month]} ${now.year}';
    });
  }

  Future<void> _loadLocationAndWeather() async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      Position? position = await WeatherService.getCurrentPosition();

      if (position != null) {
        String cityName = await WeatherService.getCityName(
          position.latitude,
          position.longitude,
        );
        Map<String, dynamic> weatherData =
            await WeatherService.getWeatherByCoordinates(
              position.latitude,
              position.longitude,
            );

        setState(() {
          _currentLocation = '$cityName, ${weatherData['country']}';
          _currentTemperature = weatherData['temperature'];
          _weatherDescription = weatherData['description'];
          _isLoadingWeather = false;
        });
      } else {
        Map<String, dynamic> weatherData =
            await WeatherService.getWeatherByCity('Batam');

        setState(() {
          _currentLocation = 'Batam, Indonesia';
          _currentTemperature = weatherData['temperature'];
          _weatherDescription = weatherData['description'];
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      print('Error loading weather: $e');
      setState(() {
        _currentLocation = 'Batam, Indonesia';
        _currentTemperature = 28.0;
        _weatherDescription = 'Cerah';
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _refreshWeather() async {
    await _loadLocationAndWeather();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Cuaca berhasil diperbarui'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getWeatherIcon(String description) {
    switch (description.toLowerCase()) {
      case 'cerah':
        return Icons.wb_sunny;
      case 'berawan':
        return Icons.wb_cloudy;
      case 'hujan':
      case 'gerimis':
        return Icons.umbrella;
      case 'badai':
        return Icons.flash_on;
      case 'kabut':
        return Icons.foggy;
      default:
        return Icons.wb_sunny;
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        return;
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
  void dispose() {
    _sensorSubscription.cancel();
    _controlSubscription.cancel();
    _notificationSubscription.cancel();
    _chartUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        drawer: _buildDrawer(),
        appBar: AppBar(
          backgroundColor: Color(0xFF4B715A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Text(
            'Beranda',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.notifications, size: 20),
                    ),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '$_unreadNotificationCount',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $_username',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _currentDate,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentLocation,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                _getWeatherIcon(_weatherDescription),
                                size: 14,
                                color: Colors.orange[400],
                              ),
                              const SizedBox(width: 4),
                              _isLoadingWeather
                                  ? SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[400]!,
                                      ),
                                    ),
                                  )
                                  : GestureDetector(
                                    onTap: _refreshWeather,
                                    child: Text(
                                      '${_currentTemperature.round()}°C • $_weatherDescription',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                              const SizedBox(width: 12),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      _isFirebaseConnected
                                          ? Colors.green
                                          : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isFirebaseConnected ? 'Online' : 'Offline',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color:
                                      _isFirebaseConnected
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.water_drop,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${_tdsValue.toStringAsFixed(0)} ppm',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Level Nutrisi',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(_tdsValue / 1000 * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 5,
                            width:
                                MediaQuery.of(context).size.width *
                                (_tdsValue / 1000) *
                                0.8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _getPumpStatusText(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            Icons.thermostat,
                            'Suhu',
                            _temperature.toStringAsFixed(1),
                            '°C',
                            Colors.orange.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            Icons.water_drop_outlined,
                            'Kelembaban',
                            _humidity.toStringAsFixed(1),
                            '%',
                            Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            Icons.blur_circular,
                            'pH',
                            _phValue.toStringAsFixed(2),
                            '',
                            Colors.purple.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            Icons.scatter_plot_outlined,
                            'TDS',
                            _tdsValue.toStringAsFixed(0),
                            'ppm',
                            Colors.teal.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: _buildStatCard(
                        Icons.waves,
                        'Ketinggian Air',
                        _waterHeight.toStringAsFixed(1),
                        'cm',
                        Colors.indigo.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Suhu dari Waktu ke Waktu',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${_temperature.toStringAsFixed(1)}°C',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _isFirebaseConnected
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        _isFirebaseConnected
                                            ? Colors.green
                                            : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isFirebaseConnected ? 'Live' : 'Offline',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color:
                                        _isFirebaseConnected
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 180,
                        child:
                            _tempSpots.isEmpty
                                ? Center(
                                  child: Text(
                                    'Menunggu data sensor...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                                : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      drawHorizontalLine: true,
                                      horizontalInterval: 10,
                                      verticalInterval: 1,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey[200]!,
                                          strokeWidth: 1,
                                          dashArray: [3, 3],
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey[200]!,
                                          strokeWidth: 1,
                                          dashArray: [3, 3],
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            int index = value.toInt();
                                            if (index < _timeLabels.length) {
                                              return Text(
                                                _timeLabels[index],
                                                style: const TextStyle(
                                                  color: Color(0xff68737d),
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 12,
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 10,
                                          getTitlesWidget: (value, meta) {
                                            const style = TextStyle(
                                              color: Color(0xff68737d),
                                              fontWeight: FontWeight.w400,
                                              fontSize: 10,
                                            );
                                            return Text(
                                              '${value.toInt()}°C',
                                              style: style,
                                            );
                                          },
                                          reservedSize: 42,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX:
                                        _tempSpots.length > 0
                                            ? _tempSpots.length - 1
                                            : 0,
                                    minY: 0,
                                    maxY: 50,
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipColor:
                                            (touchedSpot) => Colors.black87,
                                        tooltipRoundedRadius: 8,
                                        tooltipPadding: const EdgeInsets.all(8),
                                        getTooltipItems: (
                                          List<LineBarSpot> touchedBarSpots,
                                        ) {
                                          return touchedBarSpots.map((barSpot) {
                                            return LineTooltipItem(
                                              '${_timeLabels[barSpot.x.toInt()]}\n${barSpot.y.toStringAsFixed(1)}°C',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _tempSpots,
                                        isCurved: true,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xff4ade80),
                                            Color(0xff22c55e),
                                          ],
                                        ),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (
                                            spot,
                                            percent,
                                            barData,
                                            index,
                                          ) {
                                            if (index ==
                                                _tempSpots.length - 1) {
                                              return FlDotCirclePainter(
                                                radius: 6,
                                                color: Colors.white,
                                                strokeWidth: 3,
                                                strokeColor: const Color(
                                                  0xff22c55e,
                                                ),
                                              );
                                            }
                                            return FlDotCirclePainter(
                                              radius: 3,
                                              color: const Color(0xff22c55e),
                                            );
                                          },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color(
                                                0xff4ade80,
                                              ).withOpacity(0.4),
                                              const Color(
                                                0xff22c55e,
                                              ).withOpacity(0.1),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    String unit,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              Icon(Icons.trending_up, size: 16, color: Colors.green.shade600),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              text: value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.0,
              ),
              children: [
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
            decoration: BoxDecoration(
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
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Text(
                        _getInitials(_username),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B715A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _username,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _email,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
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
                  isActive: true,
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'Tentang Kami',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
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
                    Navigator.push(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EducationPage()),
                    );
                  },
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> names = name.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    } else {
      return (names[0].substring(0, 1) + names[1].substring(0, 1))
          .toUpperCase();
    }
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
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text('Logout Berhasil'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                } catch (e) {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text('Error saat logout: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
