import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  List<Map<String, dynamic>> _waterUsageData = [];
  double? _totalBill;
  double? _totalUsage;
  List<Map<String, dynamic>> _billBreakdown = [];
  bool _isLoading = true;

  static const String serverUrl = 'http://192.168.1.172/iotdigi-main';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/get.php'));
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _waterUsageData = List<Map<String, dynamic>>.from(data['ocr_readings'] ?? []);
            _isLoading = false;
          });
          _calculateBill();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _calculateBill() {
    if (_waterUsageData.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 2 readings to calculate bill'),
        ),
      );
      return;
    }

    try {
      final startReading = double.parse(_waterUsageData.first['ocr_text'].toString());
      final endReading = double.parse(_waterUsageData.last['ocr_text'].toString());
      _totalUsage = endReading - startReading;
      
      double bill = 0;
      var remainingUsage = _totalUsage!;
      _billBreakdown = [];

      final rates = [
        {'limit': 10.0, 'price': 5973},
        {'limit': 10.0, 'price': 7052},
        {'limit': 10.0, 'price': 8669},
        {'limit': double.infinity, 'price': 15929}
      ];

      for (final rate in rates) {
        if (remainingUsage > 0) {
          final usage = remainingUsage.clamp(0.0, rate['limit'] as double);
          final tierBill = usage * (rate['price'] as int);
          _billBreakdown.add({
            'usage': usage,
            'rate': rate['price'],
            'amount': tierBill,
          });
          bill += tierBill;
          remainingUsage -= usage;
        } else {
          break;
        }
      }

      setState(() {
        _totalBill = bill;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tính hoá đơn: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tính hoá đơn tiền nước'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Cập nhật và tính lại',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_waterUsageData.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chỉ số đầu: ${_waterUsageData.first['ocr_text']} m³',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chỉ số cuối: ${_waterUsageData.last['ocr_text']} m³',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng tiêu thụ: ${_totalUsage?.toStringAsFixed(1)} m³',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chi tiết hoá đơn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._billBreakdown.map((tier) => Card(
              child: ListTile(
                title: Text('${tier['usage'].toStringAsFixed(1)} m³'),
                subtitle: Text('Đơn giá: ${tier['rate']} VNĐ/m³'),
                trailing: Text(
                  '${tier['amount'].toStringAsFixed(0)} VNĐ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_totalBill?.toStringAsFixed(0)} VNĐ',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}