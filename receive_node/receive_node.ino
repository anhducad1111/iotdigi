#include <SPI.h>
#include <LoRa.h>
#include "config.h"
#include "tasks.h"

// Global variables required by tasks.h
WaterData currentData = {"0", 0.0, ""};

void setup() {
    Serial.begin(115200);
    while (!Serial);
    
    Serial.println("\nStarting LoRa Receiver...");

    // Initialize SPI for LoRa
    SPI.begin();
    
    // Initialize LoRa
    if (!initLoRa()) {
        Serial.println("LoRa initialization failed!");
        while (1); // Stop if failed
    }
}

void loop() {
    int packetSize = LoRa.parsePacket();
    if (packetSize) {
        // Read packet
        String received = "";
        while (LoRa.available()) {
            received += (char)LoRa.read();
        }
        
        // Print raw data first
        Serial.println("\nReceived Packet:");
        Serial.println("Raw: " + received);
        Serial.printf("RSSI: %d dBm\n", LoRa.packetRssi());
        Serial.printf("SNR: %.1f dB\n", LoRa.packetSnr());

        // Parse and display data
        if (parseLoRaPacket(received, &currentData)) {
            printWaterData(currentData);
        } else {
            Serial.println("Error: Invalid packet format");
        }
        Serial.println(); // Extra line for readability
    }
}
