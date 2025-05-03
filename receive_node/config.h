#ifndef CONFIG_H
#define CONFIG_H

// LoRa pins (using stable pins)
#define LORA_SS    15     // D2 (GPIO4)  - LoRa NSS/SS
#define LORA_RST   5     // D1 (GPIO5)  - LoRa Reset 
#define LORA_DIO0  16    // D0 (GPIO16) - LoRa DIO0

// LoRa frequency
#define LORA_FREQ  921E6

// Serial baud rate
#define SERIAL_BAUD 115200

// Other settings
#define MAX_PACKET_SIZE 256
#define MIN_PACKET_SIZE 10  // Minimum valid packet size

// Value currency format
#define CURRENCY_SYMBOL "K"
#define CURRENCY_DIVISOR 1000.0  // For K format display

#endif
