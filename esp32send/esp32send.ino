#include "config.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <DHT.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_GFX.h>
#include <ArduinoJson.h>

// Initialize DHT sensor
DHT dht(DHTPIN, DHT22);

// Initialize display
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Global variables
String lastOcrText = "";
unsigned long lastReadTime = 0;
int wifiRetryCount = 0;

void setup() {
  // Initialize Serial
  Serial.begin(SERIAL_BAUD);
  Serial.println("ESP32 Temperature & Humidity Monitor");

  // Initialize I2C for OLED
  Wire.begin(OLED_SDA, OLED_SCL);

  // Initialize DHT sensor
  dht.begin();

  // Initialize display
  if(!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;); // Don't proceed, loop forever
  }
  
  initDisplay();
  setupWiFi();
}

void loop() {
  unsigned long currentTime = millis();
  
  // Read sensor every SENSOR_READ_INTERVAL
  if (currentTime - lastReadTime >= SENSOR_READ_INTERVAL) {
    lastReadTime = currentTime;
    
    // Read and validate sensor data
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    
    if (!isValidReading(temperature, humidity)) {
      Serial.println("Failed to read from DHT sensor or invalid readings!");
      return;
    }

    // Update display with sensor data
    updateDisplay(temperature, humidity, lastOcrText);

    // Send data to server
    if (WiFi.status() == WL_CONNECTED) {
      postSensorData(temperature, humidity);
      getAndDisplayOCR();
      wifiRetryCount = 0; // Reset retry count on successful connection
    } else {
      Serial.println("WiFi disconnected, attempting to reconnect...");
      setupWiFi();
    }
  }
}

bool isValidReading(float temp, float hum) {
  // Check for NaN
  if (isnan(temp) || isnan(hum)) return false;
  
  // Check ranges (similar to original implementation)
  if (temp < -40.0 || temp > 80.0) return false;
  if (hum < 0.0 || hum > 100.0) return false;
  
  return true;
}

void initDisplay() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.dim(false); // Full brightness
  display.setTextWrap(true);
  display.display();
}

void setupWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  
  while (WiFi.status() != WL_CONNECTED && wifiRetryCount < 20) {
    delay(500);
    Serial.print(".");
    wifiRetryCount++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConnected to WiFi");
    Serial.println("IP address: " + WiFi.localIP().toString());
  } else {
    Serial.println("\nFailed to connect to WiFi");
  }
}

void updateDisplay(float temperature, float humidity, String ocrText) {
  display.clearDisplay();
  
  // Calculate text positions (similar to original implementation)
  char tempText[16];
  char humText[16];
  snprintf(tempText, sizeof(tempText), "Temp: %.1f C", temperature);
  snprintf(humText, sizeof(humText), "Hum: %.1f %%", humidity);
  
  int16_t x1, y1;
  uint16_t w, h;
  
  // Center temperature text
  display.getTextBounds(tempText, 0, 0, &x1, &y1, &w, &h);
  int x_temp = (SCREEN_WIDTH - w) / 2;
  display.setCursor(x_temp, 0);
  display.print(tempText);
  
  // Center humidity text
  display.getTextBounds(humText, 0, 0, &x1, &y1, &w, &h);
  int x_hum = (SCREEN_WIDTH - w) / 2;
  display.setCursor(x_hum, 10);
  display.print(humText);
  
  // Display OCR text with proper formatting
  if (ocrText.length() > 0) {
    String ocr_display = "OCR: " + ocrText;
    display.getTextBounds(ocr_display.c_str(), 0, 0, &x1, &y1, &w, &h);
    int x_ocr = (SCREEN_WIDTH - w) / 2;
    display.setCursor(x_ocr, 20);
    display.print(ocr_display);
  }
  
  display.display(); // Important: update display buffer
}

void postSensorData(float temperature, float humidity) {
  HTTPClient http;
  http.setTimeout(HTTP_TIMEOUT);
  
  String postData = "temp=" + String(temperature, 1) + "&hum=" + String(humidity, 1);
  
  http.begin(POST_URL);
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  
  int httpResponseCode = http.POST(postData);
  
  if (httpResponseCode > 0) {
    Serial.println("HTTP Response code: " + String(httpResponseCode));
    String response = http.getString();
    Serial.println("Response: " + response);
  } else {
    Serial.println("Error on sending POST: " + String(httpResponseCode));
  }
  
  http.end();
}

void getAndDisplayOCR() {
  HTTPClient http;
  http.setTimeout(HTTP_TIMEOUT);
  
  http.begin(GET_URL);
  
  int httpResponseCode = http.GET();
  
  if (httpResponseCode > 0) {
    String response = http.getString();
    
    // Parse JSON response
    StaticJsonDocument<512> doc;
    DeserializationError error = deserializeJson(doc, response);
    
    if (!error && doc["status"] == "success" && doc["latest_ocr_result"]) {
      const char* ocr_text = doc["latest_ocr_result"]["ocr_text"];
      if (ocr_text) {
        lastOcrText = String(ocr_text);
        updateDisplay(dht.readTemperature(), dht.readHumidity(), lastOcrText);
      }
    } else {
      Serial.println("Error parsing JSON or no OCR result");
    }
  } else {
    Serial.println("Error getting OCR: " + String(httpResponseCode));
  }
  
  http.end();
}
