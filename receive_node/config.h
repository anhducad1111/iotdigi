#ifndef CONFIG_H
#define CONFIG_H

// LoRa pins
#define LORA_SS    15    // GPIO15 (D8) - LoRa NSS/SS
#define LORA_RST   16    // GPIO16 (D0) - LoRa RST
#define LORA_DIO0   2    // GPIO2  (D4) - LoRa DIO0/IRQ
#define LORA_SCK    14   // GPIO14 (D5) - LoRa SCK
#define LORA_MISO   12   // GPIO12 (D6) - LoRa MISO
#define LORA_MOSI   13   // GPIO13 (D7) - LoRa MOSI

// LoRa frequency
#define LORA_FREQ  921E6  // 921MHz

#endif
