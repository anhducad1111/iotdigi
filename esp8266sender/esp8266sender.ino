#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>
#include <SPI.h>
#include <LoRa.h>

// WiFi credentials
const char* ssid = "duy";
const char* password = "11111111";

// Server endpoints
const char* postUrl = "http://192.168.1.2/iotdigi-main/post.php";
const char* getUrl  = "http://192.168.1.2/iotdigi-main/get.php";

// LoRa pins (chỉnh lại nếu cần)
#define SS_PIN    15
#define RST_PIN   16
#define DIO0_PIN  2

unsigned long lastPostTime = 0;
unsigned long lastLoRaTime = 0;
const unsigned long postInterval = 10000; // 10 giây
const unsigned long loraInterval = 10000; // 10 giây

void setup() {
  Serial.begin(115200);
  delay(100);
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");

  int n = WiFi.scanNetworks();
  for (int i = 0; i < n; ++i) {
    Serial.print("BSSID: ");
    Serial.print(WiFi.BSSIDstr(i));
    Serial.print(", RSSI: ");
    Serial.println(WiFi.RSSI(i));
  }

  // Khởi tạo LoRa
  LoRa.setPins(SS_PIN, RST_PIN, DIO0_PIN);
  if (!LoRa.begin(921E6)) {
    Serial.println("LoRa init failed!");
    while (1);
  }
  Serial.println("LoRa sender ready");
}

void loop() {
  unsigned long now = millis();

  // Luồng 1: Fake dữ liệu và gửi lên server
  if (now - lastPostTime > postInterval) {
    lastPostTime = now;
    if (WiFi.status() == WL_CONNECTED) {
      float temp = random(250, 350) / 10.0; // 25.0 - 35.0 độ C
      float hum = random(400, 800) / 10.0;  // 40.0 - 80.0 %

      HTTPClient http;
      WiFiClient client;
      http.begin(client, postUrl);
      http.addHeader("Content-Type", "application/x-www-form-urlencoded");

      String postData = "temp=" + String(temp, 1) + "&humidity=" + String(hum, 1);
      int httpResponseCode = http.POST(postData);

      Serial.print("POST data: ");
      Serial.println(postData);
      Serial.print("HTTP Response code: ");
      Serial.println(httpResponseCode);

      http.end();
    } else {
      Serial.println("WiFi not connected for POST!");
    }
  }

  // Luồng 2: Lấy dữ liệu mới nhất từ server và gửi qua LoRa
  if (now - lastLoRaTime > loraInterval) {
    lastLoRaTime = now;
    if (WiFi.status() == WL_CONNECTED) {
      WiFiClient client;
      HTTPClient http;
      http.begin(client, getUrl);
      int httpCode = http.GET();

      if (httpCode == HTTP_CODE_OK) {
        String payload = http.getString();
        Serial.println("Received from server: " + payload);

        // Parse JSON
        StaticJsonDocument<512> doc;
        DeserializationError error = deserializeJson(doc, payload);
        if (!error) {
          // Lấy dữ liệu mới nhất
          float temp = doc["latest_sensor_reading"]["temperature"];
          float hum = doc["latest_sensor_reading"]["humidity"];
          String timestamp = doc["latest_sensor_reading"]["timestamp"];

          // Đóng gói dữ liệu gửi qua LoRa
          String loraPayload = String(temp,1) + "," + String(hum,1) + "," + timestamp;
          LoRa.beginPacket();
          LoRa.print(loraPayload);
          LoRa.endPacket();

          Serial.println("Sent LoRa: " + loraPayload);
        } else {
          Serial.println("JSON parse error!");
        }
      } else {
        Serial.print("HTTP GET failed, code: ");
        Serial.println(httpCode);
      }
      http.end();
    } else {
      Serial.println("WiFi not connected for GET!");
    }
  }
}