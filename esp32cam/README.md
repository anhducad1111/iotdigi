# ESP32-CAM Image Processing System

## Overview
ESP32-CAM system for continuous image capture, OCR processing, and LED control using FreeRTOS multi-tasking.

## Code Structure

### 1. Configuration (config.h)
- Pin definitions
- Network settings
- Camera configuration
- Server ports and URLs
```cpp
#define LED_PIN 4
#define BRIGHTNESS_SERVER_PORT 81
#define OCR_SERVER_PORT 82
```

### 2. Camera Management (camera.h)
Simple camera operations class:
```cpp
class Camera {
    static bool init();        // Initialize camera
    static camera_fb_t* capture(); // Capture frame
    static void release(camera_fb_t* fb); // Release frame
}
```

### 3. Task Management (tasks.h)
FreeRTOS tasks implementation:
- LED control (20Hz update)
- OCR processing (manual/auto)
- Image streaming (10 FPS)

## Network Endpoints

### 1. LED Control
- URL: `http://[ESP-IP]:81/slider?value=0-800`
- Method: GET
- Example: `http://192.168.1.100:81/slider?value=500`

### 2. OCR Trigger
- URL: `http://[ESP-IP]:82/trigger`
- Method: GET
- Manual OCR processing trigger

## Task Details

### 1. LED Control Task
- Priority: 3 (Highest)
- Core: 1
- Stack: 2048 bytes
- Features:
  * Basic pinMode/analogWrite
  * Value range: 0-800
  * Web server response

### 2. OCR Processing Task
- Priority: 2
- Core: 0
- Stack: 8192 bytes
- Features:
  * Manual trigger via HTTP
  * Automatic hourly processing
  * OCR.space API integration

### 3. Image Streaming Task
- Priority: 1 (Lowest)
- Core: 1
- Stack: 4096 bytes
- Features:
  * 10 FPS capture rate
  * HTTP POST with multipart/form-data
  * Memory-efficient buffer handling

## Installation

1. Configure network settings in config.h:
```cpp
const char* ssid = "duc";
const char* password = "11111111";
```

2. Set server URLs:
```cpp
const char* serverUrl = "http://192.168.1.3";
const char* ngrokUrl = "df92-14-254-246-197.ngrok-free.app";
```

3. Upload code using FTDI adapter:
   - GPIO0 to GND for programming
   - Connect FTDI RX->TX, TX->RX

## Hardware Setup

1. ESP32-CAM AI Thinker
   - External 5V power supply
   - Clean ground connection

2. LED Connection
   - GPIO 4 (Built-in LED)
   - No external components required

3. Programming Connection
   ```
   FTDI    ESP32-CAM
   5V  ->  5V
   GND ->  GND
   TX  ->  U0R (GPIO3)
   RX  ->  U0T (GPIO1)
   ```

## Operation Notes

1. Server Communication
   - Images sent as JPEG
   - OCR text as JSON
   - LED control via HTTP GET

2. Error Handling
   - Camera initialization check
   - WiFi connection monitoring
   - Memory allocation verification

3. Performance
   - LED response: ~50ms
   - Image capture: 100ms (10 FPS)
   - OCR process: Rate limited

## Debugging

1. Serial Output
   - Baud Rate: 115200
   - Initialization status
   - Task creation results
   - OCR processing status

2. LED Indicators
   - Power LED
   - GPIO 4 (Controllable)
   - Flash LED (unused)

3. Common Issues
   - Camera initialization failure
   - WiFi connection problems
   - Memory allocation errors

## Dependencies
1. ESP32 Arduino Core
2. ESP32 Camera Driver
3. ArduinoJson
4. WiFi and HTTPClient libraries