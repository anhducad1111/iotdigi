#ifndef TASKS_H
#define TASKS_H

#include <SPI.h>
#include <LoRa.h>
#include "config.h"

// Struct for parsed LoRa data
struct LoRaData {
    String ocrReading;
    float waterBill;
    String address;
    bool isValid;
};

// Function declarations
bool initLoRa();
LoRaData parseLoRaPacket(const String& packet);
void displayData(const LoRaData& data);
bool validatePacket(const String& packet);

// Initialize LoRa module
bool initLoRa() {
    LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
    if (!LoRa.begin(LORA_FREQ)) {
        Serial.println("LoRa init failed!");
        return false;
    }
    Serial.println("LoRa OK");
    return true;
}

// Validate received packet
bool validatePacket(const String& packet) {
    if (packet.length() < MIN_PACKET_SIZE || packet.length() > MAX_PACKET_SIZE) {
        Serial.println("Invalid packet size");
        return false;
    }
    
    // Check for two commas
    int commaCount = 0;
    for (unsigned int i = 0; i < packet.length(); i++) {
        if (packet[i] == ',') commaCount++;
    }
    if (commaCount != 2) {
        Serial.println("Invalid packet format");
        return false;
    }
    
    return true;
}

// Parse LoRa packet into structured data
LoRaData parseLoRaPacket(const String& packet) {
    LoRaData data = {"", 0.0, "", false};
    
    if (!validatePacket(packet)) {
        return data;
    }
    
    int firstComma = packet.indexOf(',');
    int secondComma = packet.indexOf(',', firstComma + 1);
    
    if (firstComma > 0 && secondComma > firstComma) {
        data.ocrReading = packet.substring(0, firstComma);
        data.waterBill = packet.substring(firstComma + 1, secondComma).toFloat();
        data.address = packet.substring(secondComma + 1);
        data.isValid = true;
    }
    
    return data;
}

// Display parsed data nicely formatted
void displayData(const LoRaData& data) {
    if (!data.isValid) {
        Serial.println("Invalid data - cannot display");
        return;
    }
    
    Serial.println("\n=== Received Data ===");
    Serial.println("OCR Reading: " + data.ocrReading + " m³");
    Serial.printf("Water Bill: %.1f%s VND\n", data.waterBill/CURRENCY_DIVISOR, CURRENCY_SYMBOL);
    Serial.println("Address: " + data.address);
    Serial.println("===================\n");
}

#endif
