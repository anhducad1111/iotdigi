# ESP32 Environmental Monitor

## Overview
Environmental monitoring system that displays temperature, humidity, and OCR text on an OLED display.

## Hardware Setup

### Components
1. ESP32 Development Board
2. DHT22 Temperature/Humidity Sensor
3. SSD1306 OLED Display (128x64)

### Pin Connections
```
Component  ESP32 Pin
-------------------------
DHT22      GPIO2
OLED SDA   GPIO21
OLED SCL   GPIO22
```

## Features

### 1. Sensor Reading
- Temperature (-40°C to 80°C)
- Humidity (0-100%)
- Update interval: 10 seconds

### 2. OLED Display
- Resolution: 128x64 pixels
- I2C Address: 0x3C
- Display content:
  * Temperature
  * Humidity
  * OCR Text (auto-scroll)

### 3. Network Communication
- Data upload to server
- OCR text retrieval
- Auto-reconnect capability

## Network Configuration

### WiFi Settings
```cpp
SSID: duy
Password: 11111111
```

### Server Endpoints
```cpp
POST: http://192.168.1.3/video_upload/post.php
GET:  http://192.168.1.3/video_upload/get.php
```

## Code Structure

### 1. Main Loop
```cpp
void loop() {
    readSensor();        // Get DHT22 data
    updateDisplay();     // Update OLED
    sendData();         // Send to server
    getOcrText();       // Get OCR text
    delay(10000);       // Wait 10 seconds
}
```

### 2. Display Layout
```
-------------------------
|     Temp: XX.X°C     |
|     Hum:  XX.X%      |
|                      |
| [OCR Text Scrolling] |
-------------------------
```

## Dependencies

### Libraries
1. WiFi.h
2. HTTPClient.h
3. Wire.h
4. DHT.h
5. Adafruit_SSD1306.h
6. Adafruit_GFX.h

### Arduino Settings
- Board: ESP32 Dev Module
- Upload Speed: 115200
- Flash Frequency: 80MHz

## Error Handling

### 1. Sensor Errors
- Invalid readings check
- Timeout handling
- Error indication on display

### 2. Network Issues
- Connection retry
- Timeout management
- Status display

### 3. Display Problems
- I2C error detection
- Buffer overflow protection
- Auto-reset capability

## Installation

1. Install Required Libraries
   - DHT sensor library
   - Adafruit SSD1306
   - Adafruit GFX

2. Configure Network Settings
   - Set WiFi credentials
   - Update server URLs

3. Upload Code
   - Select correct board
   - Choose proper COM port
   - Upload sketch

## Operation Notes

1. Startup Sequence
   - Initialize display
   - Connect WiFi
   - Start DHT22
   - Begin main loop

2. Display Updates
   - Sensor data: Every 10 seconds
   - OCR text: When available
   - Network status: On change

3. Error Indicators
   - Sensor: "Error" display
   - WiFi: Connection status
   - Server: Response codes

## Debugging

### Serial Monitor
- Baud Rate: 115200
- Initialization status
- Sensor readings
- Network events

### Common Issues
1. Display not working
   - Check I2C connections
   - Verify address (0x3C)

2. Sensor errors
   - Check pin connection
   - Verify power supply

3. Network problems
   - Check WiFi credentials
   - Verify server URLs