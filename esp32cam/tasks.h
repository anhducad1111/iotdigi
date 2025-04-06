#ifndef TASKS_H
#define TASKS_H

#include "config.h"
#include "camera.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// Task handles
static TaskHandle_t ledTaskHandle = nullptr;
static TaskHandle_t ocrTaskHandle = nullptr;
static TaskHandle_t streamingTaskHandle = nullptr;

// Servers
static WiFiServer brightnessServer(BRIGHTNESS_SERVER_PORT);
static WiFiServer ocrServer(OCR_SERVER_PORT);

// Tasks
void ledControlTask(void* parameter) {
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);

    while (true) {
        WiFiClient client = brightnessServer.available();
        if (client) {
            String request = client.readStringUntil('\r');
            if (request.indexOf("GET /slider?value=") >= 0) {
                int value = request.substring(request.indexOf("value=") + 6).toInt();
                value = constrain(value, 0, 800);
                int pwmValue = map(value, 0, 800, 0, 255);
                analogWrite(LED_PIN, pwmValue);
                Serial.printf("LED: %d (PWM: %d)\n", value, pwmValue);
                
                client.println("HTTP/1.1 200 OK");
                client.println("Content-Type: text/plain");
                client.println("Access-Control-Allow-Origin: *");
                client.println();
                client.println("OK");
            }
            client.stop();
        }
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}

void ocrProcessingTask(void* parameter) {
    NetworkConfig* config = (NetworkConfig*)parameter;
    unsigned long lastOcrTime = 0;
    DynamicJsonDocument jsonDoc(1024);

    while (true) {
        WiFiClient client = ocrServer.available();
        if (client) {
            String request = client.readStringUntil('\r');
            if (request.indexOf("GET /trigger") >= 0) {
                Serial.println("Manual OCR trigger");
                
                HTTPClient http;
                String boundary = HTTP_BOUNDARY;
                String requestBody = "--" + boundary + "\r\n";
                requestBody += "Content-Disposition: form-data; name=\"url\"\r\n\r\n";
                requestBody += config->imageUrl + "\r\n";
                requestBody += "--" + boundary + "\r\n";
                requestBody += "Content-Disposition: form-data; name=\"OCREngine\"\r\n\r\n2\r\n";
                requestBody += "--" + boundary + "--\r\n";

                http.begin(config->getOcrApiUrl());
                http.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);
                http.addHeader("apikey", config->getOcrApiKey());

                int httpCode = http.POST(requestBody);
                Serial.printf("OCR API Response: %d\n", httpCode);

                if (httpCode == HTTP_CODE_OK) {
                    String response = http.getString();
                    jsonDoc.clear();
                    DeserializationError error = deserializeJson(jsonDoc, response);
                    
                    if (!error) {
                        const char* text = jsonDoc["ParsedResults"][0]["ParsedText"] | "none";
                        if (strcmp(text, "none") != 0) {
                            Serial.println("OCR Result: " + String(text));
                            
                            HTTPClient resultHttp;
                            resultHttp.begin(String(config->getServerUrl()) + "/video_upload/post.php");
                            resultHttp.addHeader("Content-Type", "application/json");
                            
                            String jsonResult;
                            StaticJsonDocument<200> resultDoc;
                            resultDoc["ocr_text"] = text;
                            serializeJson(resultDoc, jsonResult);
                            
                            resultHttp.POST(jsonResult);
                            resultHttp.end();
                        }
                    }
                }
                http.end();
                
                client.println("HTTP/1.1 200 OK");
                client.println("Content-Type: text/plain");
                client.println("Access-Control-Allow-Origin: *");
                client.println();
                client.println("OCR Complete");
            }
            client.stop();
        }

        // Auto OCR
        if (millis() - lastOcrTime >= OCR_AUTO_INTERVAL) {
            // Similar OCR process for auto trigger
            lastOcrTime = millis();
        }

        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

void streamingTask(void* parameter) {
    NetworkConfig* config = (NetworkConfig*)parameter;
    unsigned long lastCapture = 0;

    while (true) {
        if (millis() - lastCapture >= 100) { // 10 FPS
            camera_fb_t* fb = Camera::capture();
            if (fb) {
                if (WiFi.status() == WL_CONNECTED) {
                    HTTPClient http;
                    http.begin(String(config->getServerUrl()) + "/video_upload/post.php");
                    
                    String boundary = HTTP_BOUNDARY;
                    http.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);
                    
                    String head = "--" + boundary + "\r\n";
                    head += "Content-Disposition: form-data; name=\"file\"; filename=\"frame.jpg\"\r\n";
                    head += "Content-Type: image/jpeg\r\n\r\n";
                    String tail = "\r\n--" + boundary + "--\r\n";
                    
                    uint8_t* buffer = (uint8_t*)malloc(head.length() + fb->len + tail.length());
                    if (buffer) {
                        uint32_t pos = 0;
                        memcpy(buffer, head.c_str(), head.length());
                        pos += head.length();
                        memcpy(buffer + pos, fb->buf, fb->len);
                        pos += fb->len;
                        memcpy(buffer + pos, tail.c_str(), tail.length());
                        
                        http.POST(buffer, pos + tail.length());
                        free(buffer);
                    }
                    http.end();
                }
                Camera::release(fb);
                lastCapture = millis();
            }
        }
        vTaskDelay(pdMS_TO_TICKS(20));
    }
}

void startTasks(NetworkConfig& config) {
    // Start servers
    brightnessServer.begin();
    ocrServer.begin();
    Serial.println("Servers started");

    // Create tasks
    xTaskCreatePinnedToCore(ledControlTask, "LED_Control", 2048, nullptr, 3, &ledTaskHandle, 1);
    xTaskCreatePinnedToCore(ocrProcessingTask, "OCR_Process", 8192, &config, 2, &ocrTaskHandle, 0);
    xTaskCreatePinnedToCore(streamingTask, "Streaming", 4096, &config, 1, &streamingTaskHandle, 1);

    Serial.println("Tasks started");
}

#endif // TASKS_H