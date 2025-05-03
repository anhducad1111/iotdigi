import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    // Tự động làm mới mỗi phút
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => _fetchNotifications(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.159/iotdigi-main/get_notifications.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(data['notifications']);
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải thông báo: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'gas':
        return Icons.local_fire_department;
      case 'fire':
        return Icons.warning;
      case 'system':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'gas':
        return Colors.orange;
      case 'fire':
        return Colors.red;
      case 'system':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _notifications.isEmpty
            ? const Center(
                child: Text('Không có thông báo'),
              )
            : ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getNotificationIcon(notification['type']),
                        color: _getNotificationColor(notification['type']),
                      ),
                      title: Text(notification['message']),
                      subtitle: Text(
                        'Thiết bị: ${notification['device_name']} • ${notification['created_at']}',
                      ),
                      trailing: Icon(
                        Icons.circle,
                        size: 12,
                        color: notification['read'] == 0
                            ? Colors.blue
                            : Colors.transparent,
                      ),
                      onTap: () {
                        // Đánh dấu đã đọc
                        if (notification['read'] == 0) {
                          http.post(
                            Uri.parse('http://192.168.1.159/iotdigi-main/mark_notification_read.php'),
                            body: {
                              'id': notification['id'].toString(),
                            },
                          );
                          setState(() {
                            notification['read'] = 1;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}