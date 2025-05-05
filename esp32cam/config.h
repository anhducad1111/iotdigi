#ifndef CONFIG_H
#define CONFIG_H

#include <Arduino.h>

// Pin Definitions
#define LED_PIN             4
#define CAMERA_PIN_PWDN    32
#define CAMERA_PIN_RESET   -1
#define CAMERA_PIN_XCLK     0
#define CAMERA_PIN_SIOD    26
#define CAMERA_PIN_SIOC    27
#define CAMERA_PIN_Y9      35
#define CAMERA_PIN_Y8      34
#define CAMERA_PIN_Y7      39
#define CAMERA_PIN_Y6      36
#define CAMERA_PIN_Y5      21
#define CAMERA_PIN_Y4      19
#define CAMERA_PIN_Y3      18
#define CAMERA_PIN_Y2       5
#define CAMERA_PIN_VSYNC   25
#define CAMERA_PIN_HREF    23
#define CAMERA_PIN_PCLK    22

// Camera Settings
#define CAMERA_XCLK_FREQ   20000000
#define CAMERA_FRAME_SIZE  FRAMESIZE_VGA
#define CAMERA_JPEG_QUALITY 12
#define CAMERA_FB_COUNT    2

// Server Ports
#define BRIGHTNESS_SERVER_PORT 81
#define OCR_SERVER_PORT 82

// OCR Settings
#define OCR_AUTO_INTERVAL 3600000  // 1 hour in milliseconds
#define HTTP_BOUNDARY "----WebKitFormBoundary7MA4YWxkTrZu0gW"

// Network Configuration
class NetworkConfig {
public:
    NetworkConfig() : imageUrl("") {}
    
    const char* getSSID() const { return "duc"; }
    const char* getPassword() const { return "11111111"; }
    const char* getNgrokUrl() const { return "679f-113-162-128-178.ngrok-free.app"; }
    const char* getServerUrl() const { return "http://192.168.137.1"; }
    const char* getOcrApiUrl() const { return "https://api.ocr.space/parse/image"; }
    const char* getOcrApiKey() const { return "K85797055088957"; }
    
    String imageUrl;  // Will be constructed in setup()
};

#endif // CONFIG_H