import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sistem_monitoring_kontrol/pages/about_us/about_us_page.dart';
import 'package:sistem_monitoring_kontrol/pages/auth/login_page.dart';
import 'package:sistem_monitoring_kontrol/pages/education/education_page.dart';
import 'package:sistem_monitoring_kontrol/pages/monitoring/monitoring_page.dart';
import 'package:sistem_monitoring_kontrol/pages/guide/guide_page.dart';
import 'package:sistem_monitoring_kontrol/pages/profile/profile_page.dart';
import 'package:sistem_monitoring_kontrol/pages/home/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sistem_monitoring_kontrol/services/realtime_auth_services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sistem_monitoring_kontrol/utils/datetime_extensions.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  String _selectedTab = 'Week';

  String _username = 'Loading...';
  String _email = 'Loading...';

  final RealtimeAuthService _realtimeAuthService = RealtimeAuthService();

  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;
  bool _isFirebaseConnected = false;

  // Firebase Database References
  late DatabaseReference _statsRef;
  late DatabaseReference _sensorRef;
  late StreamSubscription<DatabaseEvent> _statsSubscription;
  late StreamSubscription<DatabaseEvent> _sensorSubscription;

  // Current Sensor Values
  double _currentTemp = 0.0;
  double _currentHumidity = 0.0;
  double _currentPh = 0.0;
  double _currentTds = 0.0;
  double _currentWaterLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadUserData();
  }

  @override
  void dispose() {
    _statsSubscription.cancel();
    _sensorSubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _setupDatabaseListeners();
      setState(() {
        _isFirebaseConnected = true;
      });
    } catch (e) {
      print('Error initializing Firebase: $e');
      setState(() {
        _isFirebaseConnected = false;
      });
    }
  }

  void _setupDatabaseListeners() {
    final now = DateTime.now();
    final weekKey = '${now.year}-${now.weekOfYear}';

    // Listen to statistics data
    _statsRef = FirebaseDatabase.instance.ref('statistics/$weekKey/days');
    _statsSubscription = _statsRef.onValue.listen(
      (DatabaseEvent event) {
        _handleStatsUpdate(event.snapshot);
      },
      onError: (error) {
        print('Error listening to stats: $error');
        setState(() {
          _isFirebaseConnected = false;
        });
        Future.delayed(Duration(seconds: 5), _initializeFirebase);
      },
    );

    // Listen to real-time sensor data from HQ/SENSOR
    _sensorRef = FirebaseDatabase.instance.ref('HQ/SENSOR');
    _sensorSubscription = _sensorRef.onValue.listen(
      (DatabaseEvent event) {
        _handleSensorUpdate(event.snapshot);
      },
      onError: (error) {
        print('Error listening to sensor data: $error');
      },
    );
  }

  void _handleSensorUpdate(DataSnapshot snapshot) {
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      print('Sensor data: $data'); // Debug

      setState(() {
        _currentTemp = (data['suhu'] ?? 0.0).toDouble();
        _currentHumidity = (data['kelembaban'] ?? 0.0).toDouble();
        _currentPh = (data['ph'] ?? 0.0).toDouble();
        _currentTds = (data['ppm'] ?? data['tds'] ?? 0.0).toDouble();
        _currentWaterLevel =
            (data['tinggi_air'] ?? data['tinggi'] ?? 0.0).toDouble();
      });

      _updateDailyStatistics();
    }
  }

  void _updateDailyStatistics() {
    final now = DateTime.now();
    final weekKey = '${now.year}-${now.weekOfYear}';
    final dayIndex = now.weekday - 1; // 0 for Monday, 6 for Sunday
    final dayName = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][dayIndex];

    final updates = {
      'temperature': _currentTemp,
      'humidity': _currentHumidity,
      'ph': _currentPh,
      'tds': _currentTds,
      'water_level': _currentWaterLevel,
      'day_name': dayName,
      'last_updated': ServerValue.timestamp,
    };

    FirebaseDatabase.instance
        .ref('statistics/$weekKey/days/$dayIndex')
        .update(updates)
        .catchError((error) => print('Error updating stats: $error'));
  }

  void _handleStatsUpdate(DataSnapshot snapshot) {
    print('Weekly data received: ${snapshot.value}'); // Debug
    try {
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _weeklyData =
            data.entries.map((entry) {
              return {
                'day': entry.value['day_name'],
                'temp': (entry.value['temperature'] ?? 0.0).toDouble(),
                'humidity': (entry.value['humidity'] ?? 0.0).toDouble(),
                'ph': (entry.value['ph'] ?? 0.0).toDouble(),
                'tds': (entry.value['tds'] ?? 0.0).toDouble(),
                'water': (entry.value['water_level'] ?? 0.0).toDouble(),
              };
            }).toList();

        print('Processed weekly data: $_weeklyData'); // Debug

        // Sort by day (Monday to Sunday)
        _weeklyData.sort((a, b) {
          final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
          return days.indexOf(a['day']).compareTo(days.indexOf(b['day']));
        });
      } else {
        print('No weekly data available'); // Debug
        _weeklyData = [];
        _initializeEmptyStats();
      }

      setState(() {
        _isLoading = false;
        _isFirebaseConnected = true;
      });
    } catch (e) {
      print('Error processing stats: $e');
      setState(() {
        _isLoading = false;
        _weeklyData = [];
      });
    }
  }

  void _initializeEmptyStats() {
    final now = DateTime.now();
    final weekKey = '${now.year}-${now.weekOfYear}';
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final updates = <String, dynamic>{};

    for (int i = 0; i < days.length; i++) {
      updates['$i'] = {
        'day_name': days[i],
        'temperature': _currentTemp,
        'humidity': _currentHumidity,
        'ph': _currentPh,
        'tds': _currentTds,
        'water_level': _currentWaterLevel,
        'last_updated': ServerValue.timestamp,
      };
    }

    FirebaseDatabase.instance
        .ref('statistics/$weekKey/days')
        .update(updates)
        .then((_) => print('Initialized stats for week $weekKey'))
        .catchError((error) => print('Error initializing stats: $error'));
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
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(),
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
              'Statistik',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 10),
            _buildGrowthProgressCard(),
            const SizedBox(height: 24),
            _buildSensorSummaryCards(),
            const SizedBox(height: 20),
            _buildSensorCharts(),
          ],
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
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8F9FA),
            const Color(0xFFF8F9FA).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4B715A).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco, color: Color(0xFF4B715A), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pakcoy Hidroponik',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitoring 7 hari terakhir',
                  style: GoogleFonts.poppins(
                    color: Colors.black.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '↑ 12% pertumbuhan',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Pertumbuhan Pakcoy',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.eco, size: 32, color: Color(0xFF4B715A)),
                      const SizedBox(height: 8),
                      Text(
                        '75%',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Pertumbuhan',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green, 'Sehat'),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.red, 'Perlu Perhatian'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '75% tanaman dalam kondisi sehat',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSensorSummaryCards() {
    final tempAvg =
        _weeklyData.isNotEmpty
            ? _weeklyData.map((d) => d['temp']).reduce((a, b) => a + b) /
                _weeklyData.length
            : _currentTemp;

    final humidityAvg =
        _weeklyData.isNotEmpty
            ? _weeklyData.map((d) => d['humidity']).reduce((a, b) => a + b) /
                _weeklyData.length
            : _currentHumidity;

    final phAvg =
        _weeklyData.isNotEmpty
            ? _weeklyData.map((d) => d['ph']).reduce((a, b) => a + b) /
                _weeklyData.length
            : _currentPh;

    final tdsAvg =
        _weeklyData.isNotEmpty
            ? _weeklyData.map((d) => d['tds']).reduce((a, b) => a + b) /
                _weeklyData.length
            : _currentTds;

    final waterAvg =
        _weeklyData.isNotEmpty
            ? _weeklyData.map((d) => d['water']).reduce((a, b) => a + b) /
                _weeklyData.length
            : _currentWaterLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rata-rata Sensor (7 hari)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                'Suhu',
                '${tempAvg.toStringAsFixed(1)}°C',
                Icons.thermostat,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSensorCard(
                'Kelembaban',
                '${humidityAvg.toStringAsFixed(1)}%',
                Icons.water_drop,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSensorCard(
                'pH',
                phAvg.toStringAsFixed(1),
                Icons.blur_circular,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSensorCard(
                'TDS',
                '${tdsAvg.toStringAsFixed(0)} ppm',
                Icons.scatter_plot_outlined,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSensorCard(
          'Ketinggian Air',
          '${waterAvg.toStringAsFixed(1)} cm',
          Icons.waves,
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildSensorCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String value, String label) {
    bool isSelected = _selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4B715A) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Data grafik sensor selama 7 hari',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildChartCard(
          'Suhu',
          _buildTemperatureChart(),
          '°C',
          '${_currentTemp.toStringAsFixed(1)}',
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          'Kelembaban',
          _buildHumidityChart(),
          '%',
          '${_currentHumidity.toStringAsFixed(1)}',
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          'pH',
          _buildPHChart(),
          'pH',
          '${_currentPh.toStringAsFixed(1)}',
          Colors.purple,
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          'TDS',
          _buildTDSChart(),
          'ppm',
          '${_currentTds.toStringAsFixed(0)}',
          Colors.teal,
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          'Ketinggian Air',
          _buildWaterLevelChart(),
          'cm',
          '${_currentWaterLevel.toStringAsFixed(1)}',
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildChartCard(
    String title,
    Widget chart,
    String unit,
    String currentValue,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text(
                '$title dari Hari ke Hari',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              if (!_isLoading)
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
                              _isFirebaseConnected ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isFirebaseConnected ? 'Live' : 'Offline',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color:
                              _isFirebaseConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentValue,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: color))
                    : _weeklyData.isEmpty
                    ? Center(
                      child: Text(
                        'Tidak ada data statistik',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                    : chart,
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return LineChart(
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
                if (index >= 0 && index < _weeklyData.length) {
                  return Text(
                    _weeklyData[index]['day'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
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
                return Text(
                  '${value.toInt()}°C',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots:
                _weeklyData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    (entry.value['temp'] as num).toDouble(),
                  );
                }).toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xff4ade80), Color(0xff22c55e)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (index == _weeklyData.length - 1) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xff22c55e),
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
                  const Color(0xff4ade80).withOpacity(0.4),
                  const Color(0xff22c55e).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: _weeklyData.isNotEmpty ? _weeklyData.length - 1 : 0,
        minY: 0,
        maxY: 50,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots
                  .map((barSpot) {
                    int index = barSpot.x.toInt();
                    if (index >= 0 && index < _weeklyData.length) {
                      return LineTooltipItem(
                        '${_weeklyData[index]['day']}\n${barSpot.y.toStringAsFixed(1)}°C',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  })
                  .where((item) => item != null)
                  .cast<LineTooltipItem>()
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHumidityChart() {
    return LineChart(
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
                if (index >= 0 && index < _weeklyData.length) {
                  return Text(
                    _weeklyData[index]['day'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
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
                return Text(
                  '${value.toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots:
                _weeklyData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    (entry.value['humidity'] as num).toDouble(),
                  );
                }).toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xff3b82f6), Color(0xff1d4ed8)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (index == _weeklyData.length - 1) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xff1d4ed8),
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xff1d4ed8),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xff3b82f6).withOpacity(0.4),
                  const Color(0xff1d4ed8).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: _weeklyData.isNotEmpty ? _weeklyData.length - 1 : 0,
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots
                  .map((barSpot) {
                    int index = barSpot.x.toInt();
                    if (index >= 0 && index < _weeklyData.length) {
                      return LineTooltipItem(
                        '${_weeklyData[index]['day']}\n${barSpot.y.toStringAsFixed(1)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  })
                  .where((item) => item != null)
                  .cast<LineTooltipItem>()
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPHChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 2,
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
                if (index >= 0 && index < _weeklyData.length) {
                  return Text(
                    _weeklyData[index]['day'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
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
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots:
                _weeklyData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    (entry.value['ph'] as num).toDouble(),
                  );
                }).toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xffa855f7), Color(0xff7c3aed)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (index == _weeklyData.length - 1) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xff7c3aed),
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xff7c3aed),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xffa855f7).withOpacity(0.4),
                  const Color(0xff7c3aed).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: _weeklyData.isNotEmpty ? _weeklyData.length - 1 : 0,
        minY: 0,
        maxY: 14,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots
                  .map((barSpot) {
                    int index = barSpot.x.toInt();
                    if (index >= 0 && index < _weeklyData.length) {
                      return LineTooltipItem(
                        '${_weeklyData[index]['day']}\npH ${barSpot.y.toStringAsFixed(1)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  })
                  .where((item) => item != null)
                  .cast<LineTooltipItem>()
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTDSChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 200,
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
                if (index >= 0 && index < _weeklyData.length) {
                  return Text(
                    _weeklyData[index]['day'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
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
              interval: 200,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} ppm',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots:
                _weeklyData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    (entry.value['tds'] as num).toDouble(),
                  );
                }).toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xff14b8a6), Color(0xff0d9488)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (index == _weeklyData.length - 1) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xff0d9488),
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xff0d9488),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xff14b8a6).withOpacity(0.4),
                  const Color(0xff0d9488).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: _weeklyData.isNotEmpty ? _weeklyData.length - 1 : 0,
        minY: 0,
        maxY: 1500,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots
                  .map((barSpot) {
                    int index = barSpot.x.toInt();
                    if (index >= 0 && index < _weeklyData.length) {
                      return LineTooltipItem(
                        '${_weeklyData[index]['day']}\n${barSpot.y.toInt()} ppm',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  })
                  .where((item) => item != null)
                  .cast<LineTooltipItem>()
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWaterLevelChart() {
    return LineChart(
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
                if (index >= 0 && index < _weeklyData.length) {
                  return Text(
                    _weeklyData[index]['day'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
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
                return Text(
                  '${value.toInt()} cm',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots:
                _weeklyData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    (entry.value['water'] as num).toDouble(),
                  );
                }).toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xff6366f1), Color(0xff4b3aed)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (index == _weeklyData.length - 1) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xff4b3aed),
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xff4b3aed),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xff6366f1).withOpacity(0.4),
                  const Color(0xff4b3aed).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: _weeklyData.isNotEmpty ? _weeklyData.length - 1 : 0,
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots
                  .map((barSpot) {
                    int index = barSpot.x.toInt();
                    if (index >= 0 && index < _weeklyData.length) {
                      return LineTooltipItem(
                        '${_weeklyData[index]['day']}\n${barSpot.y.toStringAsFixed(1)} cm',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  })
                  .where((item) => item != null)
                  .cast<LineTooltipItem>()
                  .toList();
            },
          ),
        ),
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
                  isActive: true,
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
