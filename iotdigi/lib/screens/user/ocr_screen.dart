import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State createState() => _OcrScreenState();
}

class _OcrScreenState extends State {
  bool _isProcessing = false;
  String? _recognizedText;
  String? _error;
  Timer? _streamTimer;
  Timer? _imageUpdateTimer;
  double _brightness = 0;
  final bool _isConnected = true;
  bool _isSending = false;
  String _currentImageUrl = '';

  // Server & Controller IPs
  static const String serverUrl = 'http://192.168.1.172/iotdigi-main';  // Local server
  static const String controllerIP = '192.168.137.246';  // ESP32-CAM local IP
  static const String ngrokUrl = '1314-42-116-76-251.ngrok-free.app'; // Ngrok URL
  static const int ocrPort = 82;
  static const int brightnessPort = 81;
  static const Duration streamInterval = Duration(milliseconds: 300);
  static const Duration ocrTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  void _startStreaming() {
    _streamTimer?.cancel();
    _imageUpdateTimer?.cancel();

    // Update URL with timestamp every 100ms for live streaming effect
    _imageUpdateTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      int retryCount = 0;
      const maxRetries = 3;
      
      Future<bool> tryUrl(String url) async {
        try {
          final response = await http.head(Uri.parse(url))
              .timeout(const Duration(seconds: 2));
          return response.statusCode == 200;
        } catch (e) {
          debugPrint('Error trying URL $url: $e');
          return false;
        }
      }

      while (retryCount < maxRetries) {
        // First try ngrok URL
        final ngrokStreamUrl = 'https://$ngrokUrl/iotdigi-main/video_stream/uploaded_image.jpg?_=$timestamp';
        debugPrint('Trying ngrok URL (attempt ${retryCount + 1}): $ngrokStreamUrl');

        if (await tryUrl(ngrokStreamUrl)) {
          if (mounted) {
            setState(() => _currentImageUrl = ngrokStreamUrl);
          }
          return;
        }

        // Try local URL
        final localStreamUrl = '$serverUrl/video_stream/uploaded_image.jpg?_=$timestamp';
        debugPrint('Trying local URL (attempt ${retryCount + 1}): $localStreamUrl');

        if (await tryUrl(localStreamUrl)) {
          if (mounted) {
            setState(() => _currentImageUrl = localStreamUrl);
          }
          return;
        }

        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      debugPrint('All connection attempts failed after $maxRetries retries');
    });

    // Poll sensor data using the same timer
    _streamTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _imageUpdateTimer?.cancel();
    super.dispose();
  }


  Future<void> _fetchData() async {
    try {
      // First try local server
      var response = await http.get(
        Uri.parse('$serverUrl/get.php'),
      ).timeout(const Duration(seconds: 5)).catchError((e) async {
        // If local fails, try through ngrok
        debugPrint('Local server fetch failed, trying ngrok...');
        return await http.get(
          Uri.parse('https://$ngrokUrl/iotdigi-main/get.php'),
        ).timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              if (data['latest_ocr_result'] != null) {
                _recognizedText = data['latest_ocr_result']['ocr_text'];
                _error = null; // Clear any previous errors
              }
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Lỗi không xác định từ máy chủ');
        }
      } else {
        throw Exception('Lỗi kết nối máy chủ (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu: $e');
      if (mounted) {
        setState(() => _error = _getErrorMessage(e));
      }
    }
  }

  Future<void> _triggerOcr() async {
    if (_isProcessing) return;

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // First try local IP
      var response = await http.get(
        Uri.parse('http://$controllerIP:$ocrPort/trigger'),
      ).timeout(const Duration(seconds: 5)).catchError((e) async {
        // If local fails, try through ngrok
        debugPrint('Local trigger failed, trying ngrok...');
        return await http.get(
          Uri.parse('https://$ngrokUrl:$ocrPort/trigger'),
        ).timeout(ocrTimeout);
      });

      debugPrint('OCR response status: ${response.statusCode}');
      debugPrint('OCR response body: ${response.body}');

      if (response.statusCode == 200) {
        // Wait for OCR processing
        await Future.delayed(const Duration(seconds: 5));
        await _fetchData();
      } else {
        throw Exception('Không thể kích hoạt chụp ảnh (Mã lỗi: ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = _getErrorMessage(e));
      }
      debugPrint('Lỗi kích hoạt OCR: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _adjustBrightness(double value) async {
    if (!mounted) return;
    setState(() => _brightness = value);
    final brightnessValue = (value * 800).round();

    try {
      // First try local IP
      await http.get(
        Uri.parse('http://$controllerIP:$brightnessPort/slider?value=$brightnessValue'),
      ).timeout(const Duration(seconds: 2)).catchError((e) async {
        // If local fails, try through ngrok
        debugPrint('Local brightness control failed, trying ngrok...');
        return await http.get(
          Uri.parse('https://$ngrokUrl:$brightnessPort/slider?value=$brightnessValue'),
        ).timeout(const Duration(seconds: 5));
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Lỗi điều chỉnh đèn: $e');
      }
      debugPrint('Lỗi điều chỉnh đèn: $e');
      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _error = null);
        }
      });
    }
  }

  // Handle connection errors and show user-friendly messages
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'Không thể kết nối với thiết bị. Vui lòng kiểm tra kết nối mạng.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Kết nối bị chậm. Vui lòng thử lại sau.';
    } else if (error.toString().contains('HandshakeException')) {
      return 'Lỗi kết nối bảo mật. Vui lòng kiểm tra cấu hình ngrok.';
    }
    return error.toString();
  }

  Widget _buildBrightnessButton(String label, double value) {
    final bool isActive = _brightness == value;
    return ElevatedButton(
      onPressed: () => _adjustBrightness(value),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: isActive ? Theme.of(context).primaryColor : null,
        foregroundColor: isActive ? Colors.white : null,
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Image.network(
                        _currentImageUrl,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        cacheWidth: 640, // Match ESP32-CAM resolution
                        headers: const {
                          'Cache-Control': 'no-cache',
                          'Pragma': 'no-cache',
                        },
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: frame != null ? child : const SizedBox(),
                          );
                        },
                        // Keep showing the previous frame while loading next one
                        loadingBuilder: (context, child, _) => child,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Image loading error: $error');
                          debugPrint('Stack trace: $stackTrace');
                          
                          String errorMessage = 'Lỗi tải stream';
                          String helpMessage = '';
                          
                          if (error.toString().contains('HandshakeException')) {
                            errorMessage = 'Lỗi kết nối bảo mật';
                            helpMessage = 'Kiểm tra URL ngrok đã được cập nhật chưa';
                          } else if (error.toString().contains('SocketException')) {
                            errorMessage = 'Lỗi kết nối mạng';
                            helpMessage = 'Kiểm tra kết nối mạng và địa chỉ máy chủ';
                          } else if (error.toString().contains('Invalid image data')) {
                            errorMessage = 'Định dạng hình ảnh không hợp lệ';
                            helpMessage = 'Kiểm tra camera có đang hoạt động không';
                          } else if (error.toString().contains('Connection refused')) {
                            errorMessage = 'Máy chủ từ chối kết nối';
                            helpMessage = 'Kiểm tra máy chủ có đang chạy không';
                          }
                          
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 8),
                                Text(errorMessage,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                if (helpMessage.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(helpMessage,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text('URL: $_currentImageUrl',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      textAlign: TextAlign.center),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBrightnessButton('Tắt', 0),
                    _buildBrightnessButton('25%', 25),
                    _buildBrightnessButton('50%', 50),
                    _buildBrightnessButton('75%', 75),
                    _buildBrightnessButton('100%', 100),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_recognizedText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Chỉ số: $_recognizedText',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isProcessing ? null : _triggerOcr,
                child: Text(_isProcessing ? 'Đang xử lý...' : 'Chụp ngay'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}