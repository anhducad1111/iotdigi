#ifndef CONFIG_H
#define CONFIG_H

// WiFi settings
const char* WIFI_SSID = "duc";
const char* WIFI_PASSWORD = "11111111";

// Server endpoints 
const char* POST_URL = "http://192.168.137.1/video_upload/post.php";
const char* GET_URL = "http://192.168.137.1/video_upload/get.php";

// Fixed location address
const char* FIXED_ADDRESS = "470 Tran Dai Nghia, Da Nang";

// Pin definitions
#define DHT_PIN      2     // D4 (GPIO2) - DHT22 needs 10kΩ pullup
#define MQ135_PIN    A0    // A0 - MQ135 air quality sensor
#define LORA_SS      5     // D1 (GPIO5)  - LoRa NSS/SS
#define LORA_RST     16    // D0 (GPIO16) - LoRa RST
#define LORA_DIO0    4     // D2 (GPIO4)  - LoRa DIO0/IRQ
#define LORA_SCK     14    // D5 (GPIO14) - LoRa SCK
#define LORA_MISO    12    // D6 (GPIO12) - LoRa MISO
#define LORA_MOSI    13    // D7 (GPIO13) - LoRa MOSI

// Constants
#define DHTTYPE DHT22
#define LORA_FREQ 921E6
#define AIR_QUALITY_THRESHOLD 1.0f  // in PPM

// Timing intervals (milliseconds)
const unsigned long POST_INTERVAL = 10000;     // 10 seconds  
const unsigned long LORA_INTERVAL = 10000;     // 10 seconds
const unsigned long SENSOR_INTERVAL = 2000;    // 2 seconds

#endif
