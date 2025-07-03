import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sistem_monitoring_kontrol/pages/home/home_page.dart';
import 'package:sistem_monitoring_kontrol/pages/guide/guide_page.dart';
import 'package:sistem_monitoring_kontrol/pages/profile/profile_page.dart';
import 'package:sistem_monitoring_kontrol/utils/datetime_extensions.dart';

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

  // MQTT
  late MqttServerClient _mqttClient;
  bool _isMqttConnected = false;

  // Firebase
  late DatabaseReference _databaseRef;
  bool _isFirebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
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
      'monitoring_client_${DateTime.now().millisecondsSinceEpoch}',
    );
    _mqttClient.port = 1883;
    _mqttClient.keepAlivePeriod = 60;
    _mqttClient.onDisconnected = _onMqttDisconnected;
    _mqttClient.logging(on: false);

    final connMess = MqttConnectMessage()
        .withClientIdentifier('monitoring_client')
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
        _updateChartData();
      });

      // Kirim ke Firebase jika sudah terinisialisasi
      if (_isFirebaseInitialized) {
        _sendToFirebase(data);
      } else {
        print('Firebase not initialized, skipping Firebase upload');
      }

      print(
        'Data diterima: pH=$_phValue, TDS=$_tdsValue, Air=$_waterHeight, Suhu=$_temperature, Kelembaban=$_humidity',
      );
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  Future<void> _sendToFirebase(Map<String, dynamic> sensorData) async {
    try {
      // Current date information
      final now = DateTime.now();
      final dayOfWeek = now.weekday;
      final weekKey = '${now.year}-${now.weekOfYear}';

      // Main sensor data
      final dataToSend = {
        'pH': _phValue,
        'tds': _tdsValue,
        'water_level': _waterHeight,
        'temperature': _temperature,
        'humidity': _humidity,
        'timestamp': ServerValue.timestamp,
        'device': 'monitoring_app', // Berbeda dengan home_app untuk tracking
      };

      // Send to main sensor readings
      await _databaseRef.push().set(dataToSend);

      // Send to weekly statistics
      final weeklyStatsRef = FirebaseDatabase.instance.ref(
        'statistics/$weekKey/days/$dayOfWeek',
      );

      // Get current data first to preserve existing values
      final snapshot = await weeklyStatsRef.get();
      Map<String, dynamic> currentData = {};

      if (snapshot.exists) {
        currentData = Map<String, dynamic>.from(snapshot.value as Map);
      }

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
        // Preserve existing values if they exist
        ...currentData,
      });

      print('Data berhasil dikirim ke Firebase (readings & statistics)');
    } catch (e) {
      print('Gagal mengirim ke Firebase: $e');
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
    _tdsSpots.add(FlSpot(newX, _tdsValue));
    _phSpots.add(FlSpot(newX, _phValue));

    DateTime now = DateTime.now();
    _timeLabels.add('${now.hour}:${now.minute.toString().padLeft(2, '0')}');
  }

  @override
  void dispose() {
    _mqttClient.disconnect();
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
    return Scaffold(
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
                color: _isMqttConnected ? Colors.green : Colors.red,
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
              // TDS Chart
              _buildChart(
                title: 'Grafik TDS',
                value: '${_tdsValue.toStringAsFixed(0)} ppm',
                spots: _tdsSpots,
                maxY: 1000,
                colors: [Color(0xff3b82f6), Color(0xff1d4ed8)],
              ),
              const SizedBox(height: 24),

              // pH Chart
              _buildChart(
                title: 'Grafik pH',
                value: _phValue.toStringAsFixed(1),
                spots: _phSpots,
                maxY: 14,
                colors: [Color(0xffa855f7), Color(0xff7c3aed)],
              ),
              const SizedBox(height: 20),

              // Sensor Readings
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
                            color: _isMqttConnected ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isMqttConnected ? 'Live' : 'Offline',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _isMqttConnected ? Colors.green : Colors.red,
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
                _isMqttConnected ? Icons.trending_up : Icons.signal_wifi_off,
                size: 14,
                color:
                    _isMqttConnected
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
