#ifndef ESP32_CONFIG_H
#define ESP32_CONFIG_H

// Pin Definitions
#define DHTPIN 2
#define OLED_SDA 21
#define OLED_SCL 22

// Display Configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C

// Network Configuration
#define WIFI_SSID "duy"
#define WIFI_PASSWORD "11111111"

// Server URLs
#define POST_URL "http://192.168.1.2/iotdigi-main/post.php"
#define GET_URL "http://192.168.1.2/iotdigi-main/get.php"

// Timing Configuration
#define SENSOR_READ_INTERVAL 10000  // 10 seconds
#define HTTP_TIMEOUT 5000           // 5 seconds
#define SERIAL_BAUD 115200

#endif // ESP32_CONFIG_H