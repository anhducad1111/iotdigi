import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'bill_screen.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  Timer? _refreshTimer;
  double _temperature = 0;
  double _humidity = 0;
  double _gasLevel = 0;
  List<Map<String, dynamic>> _waterUsageData = [];
  bool _isLoading = true;
  String? _error;
  
  static const String serverUrl = 'http://192.168.1.172/iotdigi-main';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchData(),
    );
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/get.php'));
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            if (data['latest_sensor_reading'] != null) {
              final reading = data['latest_sensor_reading'];
              _temperature = double.parse(reading['temperature'].toString());
              _humidity = double.parse(reading['humidity'].toString());
              _gasLevel = double.parse(reading['mq2']?.toString() ?? '0');
            }
            _waterUsageData = List<Map<String, dynamic>>.from(data['ocr_readings'] ?? []);
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        throw Exception('Không thể tải dữ liệu cảm biến');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi tải dữ liệu cảm biến';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Color _getGasLevelColor(double level) {
    if (level > 700) return Colors.red;
    if (level > 500) return Colors.orange;
    return Colors.green;
  }

  Widget _buildUsageChart() {
    if (_waterUsageData.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: ChartPainter(
          data: _waterUsageData,
          lineColor: Colors.green,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // Temperature Card
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[100]!,
                    Colors.blue[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.thermostat,
                    size: 48,
                    color: _temperature > 40 ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhiệt độ',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_temperature.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _temperature > 40 ? Colors.red : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Humidity Card
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.teal[100]!,
                    Colors.teal[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop,
                    size: 48,
                    color: Colors.teal[700],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Độ ẩm',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_humidity.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Gas Level Card
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple[100]!,
                    Colors.purple[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud,
                    size: 48,
                    color: _getGasLevelColor(_gasLevel),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Khí gas (MQ2)',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_gasLevel.toStringAsFixed(0)} ppm',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getGasLevelColor(_gasLevel),
                    ),
                  ),
                  if (_gasLevel > 700)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Cảnh báo!',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Water Usage Card
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green[100]!,
                    Colors.green[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 48,
                    color: Colors.green[700],
                    icon: const Icon(Icons.calculate),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BillScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tính hoá đơn',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (_waterUsageData.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Latest: ${_waterUsageData.last['ocr_text']} m³',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color lineColor;

  ChartPainter({
    required this.data,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final values = data.map((e) => double.parse(e['ocr_text'].toString())).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final pointWidth = size.width / (data.length - 1);

    path.moveTo(0, size.height - ((values.first - minValue) / range * size.height));

    for (int i = 1; i < data.length; i++) {
      path.lineTo(
        pointWidth * i,
        size.height - ((values[i] - minValue) / range * size.height),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}