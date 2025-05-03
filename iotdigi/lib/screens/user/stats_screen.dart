import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<double> waterUsage = List.filled(5, 0.0);
  List<String> dates = List.filled(5, '');
  bool isLoading = false;
  String? error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchData());
  }

  void _initializeDates() {
    final now = DateTime.now();
    for (int i = 0; i < 5; i++) {
      final date = now.subtract(Duration(days: 4 - i));
      dates[i] = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.172/iotdigi-main/get_stats.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['readings'] != null) {
          final readings = List<Map<String, dynamic>>.from(data['readings']);
          final newUsage = List<double>.filled(5, 0.0);
          
          // Map each reading to its corresponding day
          for (var reading in readings) {
            final date = reading['date'].toString();
            final index = dates.indexOf(date);
            if (index != -1) {
              newUsage[index] = double.parse(reading['value'].toString());
            }
          }

          setState(() {
            waterUsage = newUsage;
            isLoading = false;
          });
        } else {
          throw Exception('Dữ liệu không hợp lệ');
        }
      } else {
        throw Exception('Lỗi kết nối máy chủ');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<BarChartGroupData> _createBarGroups() {
    const barWidth = 25.0;
    
    return List.generate(5, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: waterUsage[index],
            color: Colors.blue.shade400,
            width: barWidth,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length >= 2) {
      return '${parts[2]}/${parts[1]}';
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (error != null)
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  )
                else
                  SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceEvenly,
                            maxY: waterUsage.reduce((a, b) => a > b ? a : b).ceil() * 1.2,
                            barGroups: _createBarGroups(),
                            titlesData: FlTitlesData(
                              show: true,
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < dates.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _formatDate(dates[index]),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false),
                            barTouchData: BarTouchData(enabled: false),
                          ),
                        ),
                        ...List.generate(
                          5,
                          (index) {
                            final value = waterUsage[index];
                            final width = MediaQuery.of(context).size.width - 32;
                            final sectionWidth = width / 5;
                            final barLeft = (sectionWidth * index) + (sectionWidth - 25) / 2;

                            return Positioned(
                              top: 0,
                              left: barLeft,
                              child: Text(
                                '${value.toStringAsFixed(0)} m³',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
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
}