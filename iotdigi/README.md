# 🌟 IoT Digi - Smart IoT Platform

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white)](https://www.espressif.com)
[![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)](https://www.php.net)

## 📱 Overview

IoT Digi is a smart IoT platform that enables:
- 📸 ESP32 camera monitoring
- 💡 LED control
- 📊 Sensor monitoring
- 📖 OCR text recognition
- 👥 User and device management

## 🚀 Getting Started

### Prerequisites

- [x] XAMPP
- [x] Flutter SDK
- [x] Arduino IDE
- [x] ESP32 board
- [x] ESP8266 board (optional)

### 🔧 Installation

#### 1. Backend Setup

1. Install XAMPP and start Apache + MySQL
2. Copy the entire project to the `htdocs` directory
3. Create database and tables:
```sql
php setup_auth_db.php
```

#### 2. ESP32 Camera Setup

1. Open the `esp32cam` folder in Arduino IDE
2. Update `config.h` with your WiFi information:
```cpp
#define WIFI_SSID "your_wifi_ssid"
#define WIFI_PASS "your_wifi_password"
```
3. Upload code to ESP32-CAM

#### 3. ESP32 Sender Setup (Optional)

1. Open the `esp32send` folder in Arduino IDE
2. Update `config.h` similarly as above
3. Upload code

#### 4. Flutter App Setup

1. Navigate to the Flutter directory:
```bash
cd iotdigi
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## 📱 Using the App

### 🔐 Login/Register
- Use the registration screen to create a new account
- Login with your created account

### 🎮 Main Features
- **Camera Stream**: View live video from ESP32-CAM
- **LED Control**: Control LED lights
- **Sensor Data**: Monitor sensor data
- **OCR**: Text recognition from images

### 👑 Admin Panel
- Manage device list
- Monitor notifications
- User management

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

MIT License - see [LICENSE](LICENSE) for more details

## 🙏 Acknowledgments
- Flutter team
- ESP32 community
- All contributors