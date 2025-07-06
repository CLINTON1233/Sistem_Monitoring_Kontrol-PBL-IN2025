import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:sistem_monitoring_kontrol/pages/about_us/about_us_page.dart';
import 'package:sistem_monitoring_kontrol/pages/auth/login_page.dart';
import 'package:sistem_monitoring_kontrol/pages/education/education_page.dart';
import 'package:sistem_monitoring_kontrol/pages/guide/guide_page.dart';
import 'package:sistem_monitoring_kontrol/pages/notification/notification_page.dart';
import 'package:sistem_monitoring_kontrol/pages/monitoring/monitoring_page.dart';
import 'package:sistem_monitoring_kontrol/pages/statistic/statistic_page.dart';
import 'package:sistem_monitoring_kontrol/pages/profile/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sistem_monitoring_kontrol/services/firestore_auth_services.dart';
import 'package:sistem_monitoring_kontrol/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sistem_monitoring_kontrol/utils/datetime_extensions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DatabaseReference _databaseRef;
  bool _isFirebaseInitialized = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _currentLocation = 'Batam, Indonesia';
  double _currentTemperature = 28.0;
  String _weatherDescription = 'Cerah';
  bool _isLoadingWeather = true;

  final FirestoreService _firestoreService = FirestoreService();

  bool isSwitched = false;
  int _currentIndex = 0;
  bool _isPumpOn = false;

  Color _getPumpStatusColor() {
    if (_tdsValue < 300) {
      return Colors.red; // Nutrisi sangat rendah
    } else if (_tdsValue < 700) {
      return Colors.orange; // Nutrisi rendah
    } else if (_tdsValue < 900) {
      return Colors.green; // Nutrisi optimal
    } else {
      return Colors.blue; // Nutrisi tinggi
    }
  }

  // Chart data
  List<FlSpot> _tempSpots = [];
  List<String> _timeLabels = [];

  // Variabel untuk data sensor
  double _phValue = 0.0;
  double _tdsValue = 0.0;
  double _waterHeight = 0.0;
  double _temperature = 0.0;
  double _humidity = 0.0;

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

  // Variabel untuk data user session
  String _username = 'Loading...';
  String _email = 'Loading...';
  String _currentDate = '';
  String _currentDay = '';

  // MQTT Client
  late MqttServerClient _mqttClient;
  bool _isMqttConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadUserData();
    _setCurrentDate();
    _loadLocationAndWeather();
    _connectToMqtt();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _databaseRef = FirebaseDatabase.instance.ref('sensor_readings');
      setState(() {
        _isFirebaseInitialized = true;
      });
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  Future<void> _connectToMqtt() async {
    _mqttClient = MqttServerClient(
      'broker.hivemq.com',
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
    );
    _mqttClient.port = 1883;
    _mqttClient.keepAlivePeriod = 60;
    _mqttClient.onDisconnected = _onMqttDisconnected;
    _mqttClient.logging(on: false);

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .keepAliveFor(60);

    _mqttClient.connectionMessage = connMess;

    try {
      await _mqttClient.connect();
      setState(() {
        _isMqttConnected = true;
      });

      _mqttClient.subscribe('hidroponik/data', MqttQos.atMostOnce);
      _mqttClient.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        _handleSensorData(payload);
      });
    } catch (e) {
      print('MQTT Connection Exception: $e');
      _mqttClient.disconnect();
      setState(() {
        _isMqttConnected = false;
      });
    }
  }

  void _onMqttDisconnected() {
    print('MQTT Disconnected');
    setState(() {
      _isMqttConnected = false;
    });
    // Reconnect after 5 seconds
    Future.delayed(Duration(seconds: 5), _connectToMqtt);
  }

  void _handleSensorData(String message) {
    try {
      final data = json.decode(message);

      double parseValue(dynamic value) {
        final parsed = double.tryParse(value.toString()) ?? 0.0;
        if (parsed < 0 || parsed > 1000) return 0.0;
        return parsed;
      }

      setState(() {
        _phValue = parseValue(data['pH']);
        _tdsValue = parseValue(data['tds']);
        _waterHeight = parseValue(data['tinggi_air']);
        _temperature = parseValue(data['suhu']);
        _humidity = parseValue(data['kelembaban']);
        _updateChartData(); // Tambahkan ini
      });

      // Kirim ke Firebase jika sudah terinisialisasi
      if (_isFirebaseInitialized) {
        _sendToFirebase(data);
      } else {
        print('Firebase not initialized, skipping Firebase upload');
      }

      print(
        'Data sensor diterima: pH=$_phValue, TDS=$_tdsValue, Tinggi Air=$_waterHeight, Suhu=$_temperature, Kelembaban=$_humidity',
      );
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  void _updateChartData() {
    if (_tempSpots.length >= 10) {
      _tempSpots.removeAt(0);
      _timeLabels.removeAt(0);

      // Update indeks untuk spot yang tersisa
      for (int i = 0; i < _tempSpots.length; i++) {
        _tempSpots[i] = FlSpot(i.toDouble(), _tempSpots[i].y);
      }
    }

    double newX = _tempSpots.length.toDouble();
    _tempSpots.add(FlSpot(newX, _temperature));

    DateTime now = DateTime.now();
    _timeLabels.add('${now.hour}:${now.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _sendToFirebase(Map<String, dynamic> sensorData) async {
    try {
      // Current date information
      final now = DateTime.now();
      final dayOfWeek = now.weekday; // 1=Monday, 7=Sunday
      final weekKey =
          '${now.year}-${now.weekOfYear}'; // Unique key for each week

      // Main sensor data
      final dataToSend = {
        'pH': _phValue,
        'tds': _tdsValue,
        'water_level': _waterHeight,
        'temperature': _temperature,
        'humidity': _humidity,
        'timestamp': ServerValue.timestamp,
        'device': 'home_app',
      };

      // Send to main sensor readings
      await _databaseRef.push().set(dataToSend);

      // Send to weekly statistics
      final weeklyStatsRef = FirebaseDatabase.instance.ref(
        'statistics/$weekKey/days/$dayOfWeek',
      );

      // Update or create the day's statistics
      await weeklyStatsRef.update({
        'day_name':
            ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][dayOfWeek - 1],
        'temperature': _temperature,
        'humidity': _humidity,
        'ph': _phValue,
        'tds': _tdsValue,
        'water_level': _waterHeight,
        'last_updated': ServerValue.timestamp,
      });

      print('Data berhasil dikirim ke Firebase (readings & statistics)');
    } catch (e) {
      print('Gagal mengirim ke Firebase: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Coba ambil dari Firestore dulu
        Map<String, dynamic>? userData = await _firestoreService.getUserData(
          currentUser.uid,
        );

        if (userData != null) {
          setState(() {
            _username = userData['username'] ?? 'User';
            _email = userData['email'] ?? currentUser.email ?? 'No Email';
          });
        } else {
          // Jika tidak ada di Firestore, coba ambil dari Firebase Auth
          setState(() {
            _username =
                currentUser.displayName ??
                currentUser.email?.split('@').first ??
                'User';
            _email = currentUser.email ?? 'No Email';
          });

          // Simpan ke Firestore untuk next time
          if (currentUser.email != null) {
            await _firestoreService.saveUserData(
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
          '${_currentDay}, ${now.day} ${months[now.month]} ${now.year}';
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
    ScaffoldMessenger.of(context).showSnackBar(
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
    _mqttClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.notifications, size: 20),
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
              // Header with greeting and switch
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
                        // Location and Weather Info
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
                            // MQTT Connection Indicator
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color:
                                    _isMqttConnected
                                        ? Colors.green
                                        : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isMqttConnected ? 'Online' : 'Offline',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color:
                                    _isMqttConnected
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

              // Main Nutrient Level Card
              // Replace the "Main Nutrient Level Card" section with this code:
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
                    // Icon and Value Row
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

                    // Label and Percentage Row
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

                    // Progress Bar
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

                    // Simple Pump Status Text
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

              // Keep this helper method in your _HomePageState class:
              const SizedBox(height: 24),

              // Sensor Cards
              Column(
                children: [
                  // First row - 2 cards
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

                  // Second row - 2 cards
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

                  // Third row - 1 card (centered)
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

              // Chart Card
              // Chart Card
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
                                _isMqttConnected
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
                                      _isMqttConnected
                                          ? Colors.green
                                          : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isMqttConnected ? 'Live' : 'Offline',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color:
                                      _isMqttConnected
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
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
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
                                  maxY:
                                      50, // Sesuaikan dengan range suhu yang diharapkan
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
                                          if (index == _tempSpots.length - 1) {
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

      // Bottom Navigation Bar
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

  // Helper Methods
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
                  ScaffoldMessenger.of(context).showSnackBar(
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
                  ScaffoldMessenger.of(context).showSnackBar(
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
