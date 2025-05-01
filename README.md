# IoT Environmental Monitoring and OCR System

## Table of Contents
1. [Project Overview](#project-overview)
2. [System Architecture](#system-architecture)
   - [ESP32-CAM Module](#1-esp32-cam-module)
   - [ESP32 Environmental Monitor](#2-esp32-environmental-monitor)
   - [LoRa Communication Nodes](#3-lora-communication-nodes)
   - [Web Application](#4-web-application)
   - [Flutter Mobile App](#5-flutter-mobile-app-demo)
3. [Network Architecture](#network-architecture)
4. [Hardware Components](#hardware-components)
5. [Software Requirements](#software-requirements)
6. [Installation and Setup](#installation-and-setup)
7. [Testing Procedures](#testing-procedures)
8. [Future Enhancements](#future-enhancements)

## Project Overview
An integrated IoT system combining:
1. ESP32-CAM for image capture and OCR
2. ESP32 environmental monitor
3. LoRa communication nodes for wireless data transmission
4. Web application for data visualization
5. Flutter mobile application (Demo)

## System Architecture

### 1. ESP32-CAM Module
- Real-time image streaming (10 FPS)
- OCR processing with OCR.space API
- LED brightness control (0-800)
- FreeRTOS multi-tasking on dual cores

### 2. ESP32 Environmental Monitor
- Temperature/humidity monitoring (DHT22)
- OLED display interface (128x64)
- OCR text display with auto-scroll
- 10-second update interval

### 3. LoRa Communication Nodes
**Send Node:**
- WiFi connectivity for server communication
- Retrieves latest OCR data every 10 seconds
- Transmits OCR text, timestamp, and location via LoRa
- Operates at 921MHz frequency
- Enables long-range wireless data transmission

**Receive Node:**
- LoRa receiver for multi-source data collection
- Real-time data parsing and serial display
- Receives OCR text from multiple sending nodes
- Each transmission includes:
  * OCR text content
  * Timestamp of capture
  * Location/source identifier
- Operates at 921MHz frequency

**LoRa Pin Configuration:**
```
Component  ESP8266 Pin  Description
----------------------------------------
NSS/SS     GPIO15      Chip select
RST        GPIO16      Reset
DIO0       GPIO2       Interrupt
```

### 4. Web Application
**Technology Stack:**
```
Backend:  PHP + MySQL
Frontend: HTML/CSS + JavaScript
Server:   Apache (XAMPP)
```

**Features:**
- Live camera stream viewer
- Environmental data graphs
- OCR text history & search
- LED brightness control
- Data export to CSV

**File Structure:**
```
video_upload/
├── post.php          # Data reception
├── get.php           # Data retrieval
├── index.html        # Main interface
├── css/             # Stylesheets
├── js/              # JavaScript files
└── video_stream/    # Image storage
```

### 5. Flutter Mobile App (Demo)
**Features:**
- Real-time data monitoring
- Push notifications
- Interactive charts
- Device control panel

**Architecture:**
- Material Design 3
- Provider state management
- REST API integration
- Local SQLite cache

## Network Architecture

### API Endpoints
1. **Data Upload**
```
POST /video_upload/post.php
Content-Type: multipart/form-data
Body: {
    file: image_data,
    temp: float,
    humidity: float,
    ocr_text: string
}
```

2. **Data Retrieval**
```
GET /video_upload/get.php
Response: {
    "temp": 25.6,
    "humidity": 65.4,
    "ocr_text": "Sample text",
    "timestamp": "2025-04-06 12:44:08"
}
```

3. **Device Control**
```
LED:    http://[ESP-IP]:81/slider?value=0-800
OCR:    http://[ESP-IP]:82/trigger
Stream: /video_stream/uploaded_image.jpg
```

### Network Settings
```
WiFi:
  SSID: duc
  Password: 11111111

Servers:
  Local: http://192.168.1.3
  NGROK: https://df92-14-254-246-197.ngrok-free.app
```

## Hardware Components

### ESP32-CAM Requirements
- ESP32-CAM AI Thinker board
- OV2640 camera module
- LED on GPIO 4
- FTDI programmer

### Environmental Monitor Setup
```
Component  ESP32 Pin    Description
----------------------------------------
DHT22      GPIO2       Temp/Humidity sensor
OLED SDA   GPIO21      Display data
OLED SCL   GPIO22      Display clock
```

### LoRa Nodes Setup
1. **Send Node (ESP8266)**
   - LoRa transceiver module SX1278
   - WiFi connectivity for OCR data retrieval
   - Supports long-range data transmission
   - Pin configuration as specified in System Architecture
   - 10-second update interval

2. **Receive Node (ESP8266)**
   - LoRa transceiver module SX1278
   - Multi-source data reception capability
   - Serial output (115200 baud) for monitoring
   - Pin configuration as specified in System Architecture
   - Real-time data parsing and display

## Software Requirements

### Development Tools
1. **Arduino IDE 2.0+**
   - ESP32 board package
   - Required libraries

2. **Web Development**
   - XAMPP v3.3.0+
   - PHP 7.4+
   - MySQL 5.7+

3. **Mobile Development**
   - Flutter 3.0+
   - Dart SDK 2.17+
   - Android Studio/VS Code

### Required Libraries
```
Arduino:
- ESP32 Camera Driver
- ArduinoJson
- WiFi & HTTPClient
- DHT sensor library
- Adafruit SSD1306
- Adafruit GFX
- LoRa (by Sandeep Mistry)

Flutter:
- http: ^0.13.0
- provider: ^6.0.0
- shared_preferences: ^2.0.0
- charts_flutter: ^0.12.0
```

## Installation and Setup

### 1. Server Setup
```bash
# 1. Install XAMPP
# 2. Clone repository
git clone https://github.com/anhducad1111/iotdigi.git
cd iotdigi

# 3. Configure database
mysql -u root < database/schema.sql

# 4. Configure NGROK (optional)
ngrok http 80
```

### 2. ESP32 Configuration
1. Update WiFi settings in config.h
2. Flash respective firmware
3. Connect hardware components
4. Verify through serial monitor

### 3. Mobile App Setup
```bash
cd iotdigi
flutter pub get
flutter run
```

## Testing Procedures
1. **Hardware Verification**
   - Camera streaming
   - Sensor readings
   - Display function
   - LED control

2. **Software Testing**
   - API endpoints
   - Data storage
   - Real-time updates
   - Mobile features

## Future Enhancements
1. **Mobile App**
   - User authentication
   - Offline capability
   - Custom notifications

2. **Web Interface**
   - Advanced analytics
   - Multiple device support
   - Data export options

3. **IoT Devices**
   - Power management
   - OTA updates
   - Additional sensors

## Documentation
Full documentation for each component:
- [ESP32-CAM Documentation](esp32cam/README.md)
- [Environmental Monitor Guide](esp32send/README.md)
- [Mobile App Guide](iotdigi/README.md)
