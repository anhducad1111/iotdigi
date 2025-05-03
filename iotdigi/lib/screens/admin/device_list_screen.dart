import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Device {
  final String id;
  String name;
  String? lastReading;
  String? lastUpdate;
  String? address;
  List<WaterBill> bills = [];
  bool isExpanded = false;

  Device({
    required this.id,
    required this.name,
    this.lastReading,
    this.lastUpdate,
    this.address,
    this.bills = const [],
  });
}

class WaterBill {
  final String id;
  final double amount;
  final String date;
  final bool isPaid;

  WaterBill({
    required this.id,
    required this.amount,
    required this.date,
    this.isPaid = false,
  });
}

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  static const String serverUrl = 'http://192.168.1.172/iotdigi-main';
  final List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        if (_error != null && _retryCount < maxRetries) {
          debugPrint('Auto-retrying... Attempt ${_retryCount + 1}');
          _retryCount++;
          _fetchDevices();
        } else {
          _fetchDevices();
        }
      }
    });
  }

  Future<void> _fetchDevices() async {
    if (_isLoading) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Fetching devices from: $serverUrl/get_devices.php');
      final response = await http.get(
        Uri.parse('$serverUrl/get_devices.php'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Không thể kết nối đến máy chủ');
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['devices'] != null) {
          if (!mounted) return;
          setState(() {
            _devices.clear();
            for (var deviceData in data['devices']) {
              List<WaterBill> bills = [];
              if (deviceData['bills'] != null) {
                for (var billData in deviceData['bills']) {
                  bills.add(WaterBill(
                    id: billData['id'].toString(),
                    amount: billData['amount'].toDouble(),
                    date: billData['date'],
                    isPaid: billData['paid'] ?? false,
                  ));
                }
              }
              
              debugPrint('Processing device: ${deviceData['name']}');
              debugPrint('Bills found: ${bills.length}');
              for (var bill in bills) {
                debugPrint('Bill: ${bill.amount} VNĐ, Paid: ${bill.isPaid}');
              }

              _devices.add(Device(
                id: deviceData['id'].toString(),
                name: deviceData['name'],
                address: deviceData['address'],
                lastReading: deviceData['last_reading'],
                lastUpdate: deviceData['last_update'],
                bills: bills,
              ));

              debugPrint('Loaded device: ${deviceData['name']}');
              debugPrint('Bills count: ${bills.length}');
            }
            _isLoading = false;
          });
        } else if (data['error'] != null) {
          throw Exception('Lỗi máy chủ: ${data['error']}');
        } else {
          throw Exception('Định dạng phản hồi không hợp lệ');
        }
      } else if (response.statusCode == 500) {
        try {
          final errorData = json.decode(response.body);
          throw Exception('Lỗi máy chủ (500): ${errorData['error'] ?? errorData['message'] ?? 'Không xác định'}');
        } catch (_) {
          throw Exception('Lỗi máy chủ nghiêm trọng (500): ${response.body}');
        }
      } else {
        throw Exception('Lỗi HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching devices: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _retryCount = 0; // Reset retry count on manual refresh
        await _fetchDevices();
      },
      child: Column(
        children: [
          _buildStatusBar(),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Lỗi',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildDeviceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_isLoading && _devices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_devices.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy thiết bị nào'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  _error != null ? Icons.error : Icons.info,
                  size: 16,
                  color: _error != null ? Colors.red : Colors.blue,
                ),
          const SizedBox(width: 8),
          Text(
            _isLoading ? 'Đang cập nhật...' : 'Tự động cập nhật mỗi 10 giây',
            style: const TextStyle(color: Colors.blue),
          ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: _fetchDevices,
              tooltip: 'Cập nhật ngay',
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.camera),
          title: Text(device.name),
          subtitle: Text(device.lastUpdate != null
            ? 'Cập nhật lúc: ${_formatDateTime(device.lastUpdate!)}'
            : 'Chưa có dữ liệu'),
          trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                // View camera stream
              },
              tooltip: 'Xem camera',
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                setState(() {
                  device.isExpanded = !device.isExpanded;
                });
              },
              tooltip: 'Xem chi tiết',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (device.address != null)
                  _buildInfoRow('Địa chỉ:', device.address!),
                if (device.lastReading != null)
                  _buildInfoRow('Chỉ số hiện tại:', device.lastReading!),
                const SizedBox(height: 8),
                const Text(
                  'Hoá đơn gần đây:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (device.bills.isNotEmpty)
                  ...device.bills.map((bill) => _buildBillRow(bill))
                else
                  const Text('Chưa có hoá đơn', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildBillRow(WaterBill bill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Số tiền: ${bill.amount.toStringAsFixed(0)} VNĐ'),
        subtitle: Text('Ngày: ${_formatDateTime(bill.date)}'),
        trailing: Chip(
          label: Text(bill.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán'),
          backgroundColor: bill.isPaid ? Colors.green.shade100 : Colors.orange.shade100,
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    final dt = DateTime.parse(dateTimeStr);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}