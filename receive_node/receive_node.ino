#include <SPI.h>
#include <LoRa.h>
#include "config.h"
#include "tasks.h"

void setup() {
    // Start serial at bootloader baud rate
    Serial.begin(74880);
    delay(100);
    
    // Switch to normal baud rate
    Serial.begin(SERIAL_BAUD);
    delay(2000);  // Wait for stability
    
    Serial.println("\nLoRa Receiver Starting...");
    
    // Initialize LoRa module
    if (!initLoRa()) {
        Serial.println("Initialization failed!");
        while (1);  // Halt if LoRa fails
    }
    
    Serial.println("Ready to receive data!");
}

void loop() {
    // Check for incoming LoRa packet
    int packetSize = LoRa.parsePacket();
    if (packetSize) {
        // Read packet
        String received = "";
        while (LoRa.available()) {
            received += (char)LoRa.read();
        }
        
        // Log raw data for debugging
        Serial.print("Raw LoRa: ");
        Serial.println(received);
        
        // Parse and display structured data
        LoRaData data = parseLoRaPacket(received);
        if (data.isValid) {
            displayData(data);
        } else {
            Serial.println("Failed to parse packet!");
        }
    }
}
