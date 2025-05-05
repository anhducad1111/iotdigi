#ifndef TASKS_H
#define TASKS_H

#include <SPI.h>
#include <LoRa.h>
#include "config.h"

// Data structure for parsed LoRa packet
struct WaterData {
    String reading;      // Water meter reading
    float bill;         // Water bill amount
    String address;     // Location address
};

// Global variables
extern WaterData currentData;

// Function declarations
bool initLoRa();
bool parseLoRaPacket(String packet, WaterData* data);
void printWaterData(const WaterData& data);

// Initialize LoRa
bool initLoRa() {
    LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
    if (!LoRa.begin(LORA_FREQ)) {
        Serial.println("LoRa init failed!");
        return false;
    }
    Serial.println("LoRa init successful");
    return true;
}

// Parse LoRa packet
bool parseLoRaPacket(String packet, WaterData* data) {
    if (!data) return false;
    
    // Find commas
    int firstComma = packet.indexOf(',');
    if (firstComma < 0) return false;
    
    int secondComma = packet.indexOf(',', firstComma + 1);
    if (secondComma < 0) return false;

    // Extract fields
    String reading = packet.substring(0, firstComma);
    String billStr = packet.substring(firstComma + 1, secondComma);
    String address = packet.substring(secondComma + 1);

    // Clean up fields
    reading.trim();
    billStr.trim();
    address.trim();

    // Validate fields
    if (reading.length() == 0 || billStr.length() == 0 || address.length() == 0) {
        return false;
    }

    // Store results
    data->reading = reading;
    data->bill = billStr.toFloat();
    data->address = address;

    return true;
}

// Print water data
void printWaterData(const WaterData& data) {
    Serial.println("\n=== Water Data ===");
    Serial.print("Reading: "); 
    Serial.print(data.reading);
    Serial.println(" m³");
    
    Serial.print("Bill: ");
    Serial.print(data.bill, 0);
    Serial.println(" VND");
    
    Serial.print("Address: ");
    Serial.println(data.address);
    Serial.println("================\n");
}

#endif
