#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>
#include <SPI.h>
#include <LoRa.h>
#include <DHT.h>
#include "config.h"
#include "tasks.h"

// Global variables (required by tasks.h)
DHT dht(DHT_PIN, DHTTYPE);
float lastTemp = 0;
float lastHum = 0;
float lastGasReading = 0;
String lastOcrValue = "0";
float lastBill = 0;
int currentAddressIndex = 0;

// Timing trackers
unsigned long lastPostTime = 0;
unsigned long lastLoraTime = 0;
unsigned long lastGasTime = 0;
unsigned long lastSensorTime = 0;

void setup() {
    // Start Serial at bootloader baud rate
    Serial.begin(74880);
    delay(100);
    
    // Switch to normal baud rate
    Serial.begin(115200);
    delay(3000);  // Give more time for stability
    
    Serial.println("\nInitializing...");
    Serial.println("Note: DHT22 requires 10kΩ pull-up resistor on D4!");
    
    // Initialize sensors
    dht.begin();
    pinMode(MQ2_PIN, INPUT);
    
    // Initialize LoRa with our pins
    LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
    if (!LoRa.begin(921E6)) {
        Serial.println("LoRa init failed!");
        while (1);
    }
    Serial.println("LoRa OK");
    
    // Connect WiFi
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("Connecting WiFi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi OK");
    
    // Initial readings
    readSensors();
    Serial.println("Setup complete!");
}

void loop() {
    unsigned long now = millis();

    // Read sensors every 2 seconds
    if (now - lastSensorTime >= SENSOR_INTERVAL) {
        lastSensorTime = now;
        readSensors();
    }

    // Post data every 10 seconds
    if (now - lastPostTime >= POST_INTERVAL) {
        lastPostTime = now;
        postSensorData();
    }

    // Get OCR and send LoRa every 10 seconds
    if (now - lastLoraTime >= LORA_INTERVAL) {
        lastLoraTime = now;
        getOcrAndSendLora();
    }
}
