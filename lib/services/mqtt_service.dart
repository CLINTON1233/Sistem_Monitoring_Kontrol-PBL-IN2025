import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? client;
  Function(Map<String, double>)? onDataReceived;

  Future<void> connect() async {
    client = MqttServerClient('broker.emqx.io', 'flutter_client');
    client!.port = 1883;
    client!.keepAlivePeriod = 30;
    client!.autoReconnect = true;

    try {
      print('Connecting to MQTT broker...');
      await client!.connect();

      if (client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('MQTT Connected');

        client!.subscribe('sensor/data', MqttQos.atLeastOnce);

        client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
          final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            message.payload.message,
          );

          print('Received: $payload');
          _parseAndNotify(payload);
        });
      }
    } catch (e) {
      print('MQTT connection error: $e');
      client!.disconnect();
    }
  }

  void _parseAndNotify(String payload) {
    try {
      Map<String, double> sensorData = {};

      print('Raw payload: $payload');

      // pH
      RegExp phRegex = RegExp(r'pH:\s*([\d.]+)');
      var phMatch = phRegex.firstMatch(payload);
      if (phMatch != null) {
        sensorData['ph'] = double.tryParse(phMatch.group(1) ?? '') ?? 0.0;
        print('Parsed pH: ${sensorData['ph']}');
      }

      // TDS
      RegExp tdsRegex = RegExp(r'TDS:\s*([\d.]+)\s*ppm');
      var tdsMatch = tdsRegex.firstMatch(payload);
      if (tdsMatch != null) {
        sensorData['tds'] = double.tryParse(tdsMatch.group(1) ?? '') ?? 0.0;
        print('Parsed TDS: ${sensorData['tds']}');
      }

      // Water Level
      RegExp waterRegex = RegExp(r'Tinggi Air:\s*([\d.]+)\s*cm');
      var waterMatch = waterRegex.firstMatch(payload);
      if (waterMatch != null) {
        sensorData['waterLevel'] =
            double.tryParse(waterMatch.group(1) ?? '') ?? 0.0;
        print('Parsed Water Level: ${sensorData['waterLevel']}');
      }

      // Temperature
      RegExp tempRegex = RegExp(r'Suhu:\s*([\d.]+)°?C');
      var tempMatch = tempRegex.firstMatch(payload);
      if (tempMatch != null) {
        sensorData['temperature'] =
            double.tryParse(tempMatch.group(1) ?? '') ?? 0.0;
        print('Parsed Temperature: ${sensorData['temperature']}');
      }

      // Humidity
      RegExp humidityRegex = RegExp(r'Kelembaban:\s*([\d.]+)%');
      var humidityMatch = humidityRegex.firstMatch(payload);
      if (humidityMatch != null) {
        sensorData['humidity'] =
            double.tryParse(humidityMatch.group(1) ?? '') ?? 0.0;
        print('Parsed Humidity: ${sensorData['humidity']}');
      }

      print('Parsed data: $sensorData');

      if (onDataReceived != null) {
        onDataReceived!(sensorData);
      }
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  void disconnect() {
    client?.disconnect();
  }
}
