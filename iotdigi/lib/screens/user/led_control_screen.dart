import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class LedControlScreen extends StatefulWidget {
  const LedControlScreen({super.key});

  @override
  State<LedControlScreen> createState() => _LedControlScreenState();
}

class _LedControlScreenState extends State<LedControlScreen> {
  double _brightness = 0.0;
  final bool _isConnected = true;
  bool _isSending = false;
  static const String esp32CamIp = '192.168.137.75';

  Future<void> _updateBrightness(double value) async {
    if (_isSending) return;

    setState(() {
      _brightness = value;
      _isSending = true;
    });

    try {
      // Convert percentage (0-100) to ESP32 range (0-800)
      final scaledValue = (value * 8).round();
      
      final response = await http.get(
        Uri.parse('http://$esp32CamIp:81/slider?value=$scaledValue'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) {
        throw Exception('Không thể cập nhật độ sáng');
      }

      // Small delay to prevent rapid requests
      await Future.delayed(const Duration(milliseconds: 100));

    } catch (e) {
      debugPrint('Lỗi cập nhật độ sáng: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật độ sáng: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
        // Reset brightness on error
        setState(() {
          _brightness = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConnectionStatus(),
          const SizedBox(height: 32),
          _buildLedControl(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.error,
            color: _isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Đã kết nối' : 'Mất kết nối',
            style: TextStyle(
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb,
            size: 48,
            color: _brightness > 0 ? Colors.yellow : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '${_brightness.round()}%',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildButton('Tắt', 0),
              _buildButton('25%', 25),
              _buildButton('50%', 50),
              _buildButton('75%', 75),
              _buildButton('100%', 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, double value) {
    final bool isActive = _brightness == value;
    return ElevatedButton(
      onPressed: _isConnected ? () => _updateBrightness(value) : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: isActive ? Theme.of(context).primaryColor : null,
        foregroundColor: isActive ? Colors.white : null,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}