# 🌟 IoT Digi - Smart IoT Platform

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white)](https://www.espressif.com)
[![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)](https://www.php.net)

## 📱 Overview

IoT Digi là một nền tảng IoT thông minh cho phép:
- 📸 Giám sát camera ESP32
- 💡 Điều khiển đèn LED 
- 📊 Theo dõi cảm biến
- 📖 Nhận dạng văn bản OCR
- 👥 Quản lý người dùng và thiết bị

## 🚀 Bắt đầu

### Yêu cầu tiên quyết

- [x] XAMPP
- [x] Flutter SDK
- [x] Arduino IDE
- [x] ESP32 board
- [x] ESP8266 board (tùy chọn)

### 🔧 Cài đặt

#### 1. Cài đặt Backend

1. Cài đặt XAMPP và khởi động Apache + MySQL
2. Copy toàn bộ project vào thư mục `htdocs`
3. Tạo database và tables:
```sql
php setup_auth_db.php
```

#### 2. Cài đặt ESP32 Camera

1. Mở thư mục `esp32cam` trong Arduino IDE
2. Cập nhật `config.h` với thông tin WiFi của bạn:
```cpp
#define WIFI_SSID "your_wifi_ssid"
#define WIFI_PASS "your_wifi_password"
```
3. Upload code lên ESP32-CAM

#### 3. Cài đặt ESP32 Sender (Tùy chọn)

1. Mở thư mục `esp32send` trong Arduino IDE 
2. Cập nhật `config.h` tương tự như trên
3. Upload code

#### 4. Cài đặt Flutter App

1. Di chuyển vào thư mục Flutter:
```bash
cd iotdigi
```

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Chạy ứng dụng:
```bash
flutter run
```

## 📱 Sử dụng App

### 🔐 Đăng nhập/Đăng ký
- Sử dụng màn hình đăng ký để tạo tài khoản mới
- Đăng nhập với tài khoản đã tạo

### 🎮 Tính năng chính
- **Camera Stream**: Xem video trực tiếp từ ESP32-CAM
- **LED Control**: Điều khiển đèn LED
- **Sensor Data**: Theo dõi dữ liệu cảm biến
- **OCR**: Nhận dạng văn bản từ hình ảnh

### 👑 Admin Panel
- Quản lý danh sách thiết bị
- Theo dõi thông báo
- Quản lý người dùng

## 🤝 Đóng góp

Mọi đóng góp đều được chào đón! Vui lòng:
1. Fork project
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit thay đổi (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

## 📝 License

MIT License - xem [LICENSE](LICENSE) để biết thêm chi tiết

##  Cảm ơn
   - 🌱 Additional sensors

## 📚 Documentation
Full documentation for each component:
- [ESP32-CAM Documentation](esp32cam/README.md)
- [Environmental Monitor Guide](esp32send/README.md)
- [Mobile App Guide](iotdigi/README.md)