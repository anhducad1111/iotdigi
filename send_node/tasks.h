#ifndef TASKS_H
#define TASKS_H

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>
#include <LoRa.h>
#include <DHT.h>
#include "config.h"

// Global variables
extern DHT dht;
extern float lastTemp;
extern float lastHum;
extern float lastGasReading;
extern String lastOcrValue;
extern float lastBill;
extern int currentAddressIndex;

// Function declarations
void readSensors();
void postSensorData();
void getOcrAndSendLora();
void printSensorData();
String getNextAddress();

// Print sensor data to Serial
void printSensorData() {
    Serial.println("\n=== Sensor Data ===");
    Serial.printf("Temperature: %.1f°C\n", lastTemp);
    Serial.printf("Humidity: %.1f%%\n", lastHum);
    Serial.printf("Gas Level: %.1f%%\n", lastGasReading);
    if (lastGasReading > GAS_THRESHOLD) {
        Serial.println("!! Gas Alert !!");
    }
    Serial.printf("OCR Value: %s\n", lastOcrValue.c_str());
    Serial.printf("Water Bill: %.0f VND\n", lastBill);
    Serial.printf("WiFi: %s\n", WiFi.status() == WL_CONNECTED ? "Connected" : "Disconnected");
    Serial.println("================");
}

// Read sensor values
void readSensors() {
    float newTemp = dht.readTemperature();
    float newHum = dht.readHumidity();
    
    if (!isnan(newTemp) && !isnan(newHum)) {
        lastTemp = newTemp;
        lastHum = newHum;
        printSensorData();
    }

    // Read gas sensor
    lastGasReading = analogRead(MQ2_PIN) / 1023.0 * 100.0;
    if (lastGasReading > GAS_THRESHOLD) {
        Serial.printf("WARNING: Gas Level %.1f%%!\n", lastGasReading);
    }
}

// Get fixed address
String getNextAddress() {
    return FIXED_ADDRESS;
}

// Post sensor data to server
void postSensorData() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi not connected!");
        return;
    }
    
    HTTPClient http;
    WiFiClient client;
    http.begin(client, POST_URL);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");
    
    String data = "temp=" + String(lastTemp, 1) + 
                 "&humidity=" + String(lastHum, 1) + 
                 "&gas=" + String(lastGasReading, 1);
                 
    int httpCode = http.POST(data);
    
    if (httpCode > 0) {
        String response = http.getString();
        Serial.printf("[HTTP] POST Code: %d\nResponse: ", httpCode);
        Serial.println(response);
        
        StaticJsonDocument<512> doc;
        DeserializationError error = deserializeJson(doc, response);
        if (!error) {
            String status = doc["status"];
            if (status != "success") {
                Serial.println("Warning: Server reported error!");
            }
        }
    } else {
        Serial.printf("[HTTP] POST failed: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
}

// Get OCR result and send via LoRa
void getOcrAndSendLora() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi not connected!");
        return;
    }
    
    HTTPClient http;
    WiFiClient client;
    http.begin(client, GET_URL);
    int httpCode = http.GET();

    if (httpCode == HTTP_CODE_OK) {
        String payload = http.getString();
        StaticJsonDocument<1024> doc;
        DeserializationError error = deserializeJson(doc, payload);
        
        if (!error) {
            JsonObject ocr_result = doc["latest_ocr_result"];
            String ocrValue = ocr_result["ocr_text"] | "0";
            float bill = ocr_result["water_bill"] | 0.0f;
            String address = getNextAddress();
            
            String loraPayload = ocrValue + "," + String(bill, 0) + "," + address;
            LoRa.beginPacket();
            LoRa.print(loraPayload);
            LoRa.endPacket();
            
            lastOcrValue = ocrValue;
            lastBill = bill;
            
            Serial.println("LoRa: " + loraPayload);
        } else {
            Serial.println("JSON parse error!");
        }
    } else {
        Serial.printf("[HTTP] GET failed: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
}

#endif
