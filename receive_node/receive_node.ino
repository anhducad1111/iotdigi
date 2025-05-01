#include <SPI.h>
#include <LoRa.h>

// LoRa pins (chỉnh lại nếu cần)
#define SS_PIN    15
#define RST_PIN   16
#define DIO0_PIN  2

void setup() {
  Serial.begin(115200);
  LoRa.setPins(SS_PIN, RST_PIN, DIO0_PIN);
  if (!LoRa.begin(921E6)) {
    Serial.println("LoRa init failed!");
    while (1);
  }
  Serial.println("LoRa receiver ready");
}

void loop() {
  int packetSize = LoRa.parsePacket();
  if (packetSize) {
    String received = "";
    while (LoRa.available()) {
      received += (char)LoRa.read();
    }
    Serial.print("Received LoRa: ");
    Serial.println(received);

    // Nếu muốn tách dữ liệu:
    // Dữ liệu dạng: temp,hum,timestamp
    int firstComma = received.indexOf(',');
    int secondComma = received.indexOf(',', firstComma + 1);
    if (firstComma > 0 && secondComma > firstComma) {
      String temp = received.substring(0, firstComma);
      String hum = received.substring(firstComma + 1, secondComma);
      String timestamp = received.substring(secondComma + 1);

      Serial.print("Nhiệt độ: ");
      Serial.println(temp);
      Serial.print("Độ ẩm: ");
      Serial.println(hum);
      Serial.print("Timestamp: ");
      Serial.println(timestamp);
    }
  }
}