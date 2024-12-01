// main.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// Data models
class SensorData {
  final double temperature;
  final double humidity;

  SensorData({required this.temperature, required this.humidity});

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: double.parse(json['temperature'].toString()),
      humidity: double.parse(json['humidity'].toString()),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Stream',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _brightness = 0;
  SensorData? _sensorData;
  String _ocrText = '--';
  Timer? _timer;
  final List<int> brightnessLevels = [0, 200, 400, 600, 800];

  @override
  void initState() {
    super.initState();
    _startDataFetching();
  }

  void _startDataFetching() {
    _fetchData(); // Initial fetch
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://your-server/get.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            if (data['latest_sensor_reading'] != null) {
              _sensorData = SensorData.fromJson(data['latest_sensor_reading']);
            }
            if (data['latest_ocr_result'] != null) {
              _ocrText = data['latest_ocr_result']['ocr_text'];
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> _updateBrightness(double value) async {
    final brightness = brightnessLevels[value.round()];
    try {
      await http.get(
        Uri.parse('http://192.168.1.11:81/slider?value=$brightness'),
      );
    } catch (e) {
      print('Error updating brightness: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFFD1C5), Color(0xFFA47857)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'Video Stream từ Camera',
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 4.0,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'http://your-server/video_stream/uploaded_image.jpg',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: child,
                      );
                    },
                  ),
                ),
                Slider(
                  value: _brightness,
                  max: 4,
                  divisions: 4,
                  onChanged: (value) {
                    setState(() {
                      _brightness = value;
                    });
                    _updateBrightness(value);
                  },
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildSensorCard(
                              'Temperature',
                              Icons.thermostat,
                              '${_sensorData?.temperature ?? '--'}°C',
                            ),
                            _buildSensorCard(
                              'Humidity',
                              Icons.water_drop,
                              '${_sensorData?.humidity ?? '--'}%',
                            ),
                            _buildSensorCard(
                              'OCR Result',
                              Icons.text_fields,
                              _ocrText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, IconData icon, String value) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}