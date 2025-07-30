import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sistem_monitoring_kontrol/pages/home/home_page.dart';
import 'package:sistem_monitoring_kontrol/pages/guide/guide_page.dart';
import 'package:sistem_monitoring_kontrol/pages/profile/profile_page.dart';
import 'package:sistem_monitoring_kontrol/utils/datetime_extensions.dart';
import 'dart:async';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  int _currentIndex = 1;

  // Data sensor
  double _phValue = 0.0;
  double _tdsValue = 0.0;
  double _temperature = 0.0;
  double _humidity = 0.0;
  double _waterHeight = 0.0;

  // Chart data
  List<FlSpot> _tdsSpots = [];
  List<FlSpot> _phSpots = [];
  List<String> _timeLabels = [];
  Timer? _chartUpdateTimer;
  DateTime _lastUpdateTime = DateTime.now();

  // Firebase
  late DatabaseReference _sensorRef;
  late DatabaseReference _databaseRef;
  bool _isFirebaseInitialized = false;
  bool _isFirebaseConnected = false;
  late StreamSubscription<DatabaseEvent> _sensorSubscription;

  // Debouncing untuk notifikasi
  Map<String, DateTime> _lastNotificationTimes = {};

  // ScaffoldMessenger key
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _chartUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _updateChartData();
    });
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _databaseRef = FirebaseDatabase.instance.ref('RIWAYAT');
      _sensorRef = FirebaseDatabase.instance.ref('HQ/SENSOR');

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

    // Ketinggian Air (optimal: 15-25 cm, sesuaikan dengan sistem)
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
    if (_tdsSpots.length >= 10) {
      _tdsSpots.removeAt(0);
      _phSpots.removeAt(0);
      _timeLabels.removeAt(0);

      for (int i = 0; i < _tdsSpots.length; i++) {
        _tdsSpots[i] = FlSpot(i.toDouble(), _tdsSpots[i].y);
        _phSpots[i] = FlSpot(i.toDouble(), _phSpots[i].y);
      }
    }

    double newX = _tdsSpots.length.toDouble();
    double newTds = _tdsValue;
    double newPh = _phValue;
    _tdsSpots.add(FlSpot(newX, newTds));
    _phSpots.add(FlSpot(newX, newPh));

    if (_timeLabels.isEmpty) {
      _lastUpdateTime = DateTime.now();
    }
    _lastUpdateTime = _lastUpdateTime.add(Duration(seconds: 10));
    _timeLabels.add(
      '${_lastUpdateTime.hour.toString().padLeft(2, '0')}:${_lastUpdateTime.minute.toString().padLeft(2, '0')}:${_lastUpdateTime.second.toString().padLeft(2, '0')}',
    );

    setState(() {});
  }

  @override
  void dispose() {
    _sensorSubscription.cancel();
    _chartUpdateTimer?.cancel();
    super.dispose();
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
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4B715A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Monitoring Real-Time',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isFirebaseConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChart(
                  title: 'Grafik TDS',
                  value: '${_tdsValue.toStringAsFixed(0)} ppm',
                  spots: _tdsSpots,
                  maxY: 1000,
                  colors: [Color(0xff3b82f6), Color(0xff1d4ed8)],
                ),
                const SizedBox(height: 24),
                _buildChart(
                  title: 'Grafik pH',
                  value: _phValue.toStringAsFixed(1),
                  spots: _phSpots,
                  maxY: 14,
                  colors: [Color(0xffa855f7), Color(0xff7c3aed)],
                ),
                const SizedBox(height: 20),
                Text(
                  'Pembacaan Sensor',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
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
                            'DHT11',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            Icons.water_drop_outlined,
                            'Kelembaban',
                            _humidity.toStringAsFixed(0),
                            '%',
                            Colors.blue.shade600,
                            'DHT11',
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
                            _phValue.toStringAsFixed(1),
                            '',
                            Colors.purple.shade600,
                            'pH Sensor',
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
                            'TDS Meter',
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
                        'Ultrasonic',
                      ),
                    ),
                  ],
                ),
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

  Widget _buildChart({
    required String title,
    required String value,
    required List<FlSpot> spots,
    required double maxY,
    required List<Color> colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    '$title dari Waktu ke Waktu',
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
                    value,
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
                    spots.isEmpty
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
                              horizontalInterval: maxY > 10 ? 200 : 2,
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
                                  interval: maxY > 10 ? 200 : 2,
                                  getTitlesWidget: (value, meta) {
                                    const style = TextStyle(
                                      color: Color(0xff68737d),
                                      fontWeight: FontWeight.w400,
                                      fontSize: 10,
                                    );
                                    return Text(
                                      '${value.toInt()}${maxY > 10 ? ' ppm' : ''}',
                                      style: style,
                                    );
                                  },
                                  reservedSize: 42,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: spots.length > 0 ? spots.length - 1 : 0,
                            minY: 0,
                            maxY: maxY,
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
                                      maxY > 10
                                          ? '${barSpot.y.toInt()} ppm'
                                          : 'pH ${barSpot.y.toStringAsFixed(1)}',
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
                                spots: spots,
                                isCurved: true,
                                gradient: LinearGradient(colors: colors),
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
                                    if (index == spots.length - 1) {
                                      return FlDotCirclePainter(
                                        radius: 6,
                                        color: Colors.white,
                                        strokeWidth: 3,
                                        strokeColor: colors.last,
                                      );
                                    }
                                    return FlDotCirclePainter(
                                      radius: 3,
                                      color: colors.last,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      colors.first.withOpacity(0.4),
                                      colors.last.withOpacity(0.1),
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
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    String unit,
    Color iconColor,
    String sensorName,
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
              Icon(
                _isFirebaseConnected
                    ? Icons.trending_up
                    : Icons.signal_wifi_off,
                size: 14,
                color:
                    _isFirebaseConnected
                        ? Colors.green.shade600
                        : Colors.red.shade600,
              ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                sensorName,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
