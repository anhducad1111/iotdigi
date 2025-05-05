#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>
#include <LoRa.h>
#include <DHT.h>
#include <SPI.h>
#include "config.h"
#include "tasks.h"

// Global variables required by tasks.h
DHT dht(DHT_PIN, DHTTYPE);
SensorData sensorData = {0, 0, 0};  // temp, humidity, air quality
WaterData waterData = {"0", 0.0, FIXED_ADDRESS}; // reading, bill, address

// Timing trackers
unsigned long lastReadTime = 0;
unsigned long lastPostTime = 0;
unsigned long lastLoraTime = 0;

void setup() {
    // Initialize serial with proper bootloader rate
    Serial.begin(74880);
    delay(100);
    Serial.begin(115200);
    delay(1000);
    Serial.println("\nInitializing...");
    
    // Initialize hardware
    if (!initWiFi() || !initLoRa() || !initSensors()) {
        Serial.println("Initialization failed!");
        while (1); // Stop if any init fails
    }

    // Initial readings
    readSensors(&sensorData);
    printSensorData(sensorData);
}

void loop() {
    unsigned long now = millis();

    // Read sensors (every 2 seconds)
    if (now - lastReadTime >= SENSOR_INTERVAL) {
        lastReadTime = now;
        if (readSensors(&sensorData)) {
            printSensorData(sensorData);
        }
    }

    // Post to server (every 10 seconds)
    if (now - lastPostTime >= POST_INTERVAL) {
        lastPostTime = now;
        postSensorData(sensorData);
    }

    // Get OCR and send via LoRa (every 10 seconds)
    if (now - lastLoraTime >= LORA_INTERVAL) {
        lastLoraTime = now;
        if (getOcrFromServer(&waterData)) {
            sendLoraData(waterData);
        } else {
            Serial.println("Failed to get OCR data, sending last known values");
            sendLoraData(waterData);  // Send last known values anyway
        }
    }
}
