/**
 * ESP32-CAM Image Capture and OCR System
 * This program uses ESP32-CAM to capture images, process them through OCR,
 * and stream results while controlling an LED.
 */

#include "config.h"
#include "camera.h"
#include "tasks.h"
#include "soc/rtc_cntl_reg.h"

// Global configuration
NetworkConfig networkConfig;

bool initWiFi() {
    WiFi.mode(WIFI_STA);
    WiFi.begin(networkConfig.getSSID(), networkConfig.getPassword());
    
    Serial.print("Connecting to WiFi");
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("\nWiFi connection failed!");
        return false;
    }

    Serial.println("\nWiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    return true;
}

void setup() {
    // Initialize serial
    Serial.begin(115200);
    delay(100);
    Serial.println("\nInitializing ESP32-CAM...");

    // Disable brownout detector
    REG_CLR_BIT(RTC_CNTL_BROWN_OUT_REG, RTC_CNTL_BROWN_OUT_ENA);

    // Setup LED
    pinMode(LED_PIN, OUTPUT);
    analogWrite(LED_PIN, 0);  // Start with LED off
    Serial.println("LED initialized");

    // Initialize camera
    if (!Camera::init()) {
        Serial.println("Camera initialization failed!");
        return;
    }
    Serial.println("Camera initialized");

    // Connect to WiFi
    if (!initWiFi()) {
        return;
    }

    // Configure image URL
    networkConfig.imageUrl = "https://" + String(networkConfig.getNgrokUrl()) + 
                           "/video_upload/video_stream/uploaded_image.jpg";
    Serial.println("Image URL: " + networkConfig.imageUrl);

    // Start tasks
    startTasks(networkConfig);

    Serial.println("System ready!");
    Serial.println("Available endpoints:");
    Serial.println("- LED control: http://" + WiFi.localIP().toString() + ":" + 
                  String(BRIGHTNESS_SERVER_PORT) + "/slider?value=0-800");
    Serial.println("- OCR trigger: http://" + WiFi.localIP().toString() + ":" + 
                  String(OCR_SERVER_PORT) + "/trigger");
}

void loop() {
    vTaskDelete(NULL);
}