#ifndef TASKS_H
#define TASKS_H

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>
#include <LoRa.h>
#include <DHT.h>
#include "config.h"

// Data structures
struct SensorData {
    float temperature;
    float humidity;
    float airQuality;
};

struct WaterData {
    String reading;
    float bill;
    String address;
};

// Global variables
extern DHT dht;
extern SensorData sensorData;
extern WaterData waterData;

// Function declarations
bool initWiFi();
bool initLoRa();
bool initSensors();
bool readSensors(SensorData* data);
bool postSensorData(const SensorData& data);
bool getOcrFromServer(WaterData* data);
bool sendLoraData(const WaterData& data);
void printSensorData(const SensorData& data);

// Function implementations
bool initWiFi() {
    Serial.print("Connecting to WiFi");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi connected!");
        return true;
    }
    
    Serial.println("\nWiFi connection failed!");
    return false;
}

bool initLoRa() {
    LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
    if (!LoRa.begin(LORA_FREQ)) {
        Serial.println("LoRa init failed!");
        return false;
    }
    Serial.println("LoRa OK");
    return true;
}

bool initSensors() {
    dht.begin();
    pinMode(MQ135_PIN, INPUT);
    Serial.println("Sensors initialized");
    return true;
}

bool readSensors(SensorData* data) {
    if (!data) return false;

    float newTemp = dht.readTemperature();
    float newHum = dht.readHumidity();
    
    if (isnan(newTemp) || isnan(newHum)) {
        Serial.println("DHT reading error!");
        return false;
    }

    data->temperature = newTemp;
    data->humidity = newHum;
    data->airQuality = analogRead(MQ135_PIN) / 1023.0 * 100.0;

    return true;
}

bool postSensorData(const SensorData& data) {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi not connected!");
        return false;
    }
    
    HTTPClient http;
    WiFiClient client;
    
    http.begin(client, POST_URL);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");
    
    String postData = String("temp=") + data.temperature + 
                     "&humidity=" + data.humidity + 
                     "&air_quality=" + data.airQuality;
                     
    int httpCode = http.POST(postData);
    
    if (httpCode > 0) {
        Serial.printf("[HTTP] POST: %d\n", httpCode);
        String response = http.getString();
        Serial.println(response);
        http.end();
        return httpCode == HTTP_CODE_OK;
    }
    
    Serial.printf("[HTTP] POST failed: %s\n", http.errorToString(httpCode).c_str());
    http.end();
    return false;
}

bool getOcrFromServer(WaterData* data) {
    if (!data || WiFi.status() != WL_CONNECTED) return false;
    
    HTTPClient http;
    WiFiClient client;
    
    http.begin(client, GET_URL);
    int httpCode = http.GET();
    
    if (httpCode == HTTP_CODE_OK) {
        String payload = http.getString();
        StaticJsonDocument<1024> doc;
        
        DeserializationError error = deserializeJson(doc, payload);
        if (!error && doc["status"] == "success") {
            if (doc["water_data"]["latest_reading"].isNull()) {
                Serial.println("No OCR data available");
                http.end();
                return false;
            }
            
            JsonObject latest = doc["water_data"]["latest_reading"];
            data->reading = latest["ocr_text"].as<String>();
            data->bill = latest["water_bill"].as<float>();
            
            Serial.println("Got OCR data: " + data->reading + ", Bill: " + String(data->bill));
            http.end();
            return true;
        }
        Serial.println("Invalid JSON response");
    }
    
    http.end();
    return false;
}

bool sendLoraData(const WaterData& data) {
    String packet = data.reading + "," + String(data.bill, 0) + "," + data.address;
    
    LoRa.beginPacket();
    LoRa.print(packet);
    LoRa.endPacket();
    
    Serial.println("LoRa sent: " + packet);
    return true;
}

void printSensorData(const SensorData& data) {
    Serial.println("\n=== Sensor Data ===");
    Serial.printf("Temperature: %.1f°C\n", data.temperature);
    Serial.printf("Humidity: %.1f%%\n", data.humidity);
    Serial.printf("Air Quality: %.1f PPM\n", data.airQuality);
    if (data.airQuality > AIR_QUALITY_THRESHOLD) {
        Serial.println("!! Poor Air Quality !!");
    }
    Serial.println("================");
}

#endif
