#include <ESP8266WiFi.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>
#include <EEPROM.h>
#include "html_content.h"

#define EEPROM_ADDR 0
int currentNumber = 0;
int textSize = 4;
int xPos = 0;
int yPos = 0;

// Cấu hình Wi-Fi
const char *ssid = "duc";          // Thay bằng SSID Wi-Fi của bạn
const char *password = "11111111"; // Thay bằng mật khẩu Wi-Fi của bạn

// Khai báo chân cho OLED
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SDA_PIN 4           // GPIO 12 cho SDA (D6)
#define SCL_PIN 5           // GPIO 14 cho SCL (D5)
#define SCREEN_ADDRESS 0x3C // I2C address for most SSD1306 displays

// Khởi tạo đối tượng OLED
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

WiFiServer server(80); // Tạo server chạy trên port 80

void setup()
{
    Serial.begin(115200);
    EEPROM.begin(512);

    // Read last saved number
    EEPROM.get(EEPROM_ADDR, currentNumber);
    if (currentNumber < 0 || currentNumber > 9999)
    {
        currentNumber = 0; // Default if invalid
    }

    // Cấu hình giao tiếp I2C first
    Wire.begin(SDA_PIN, SCL_PIN);

    // Khởi tạo OLED with additional checks
    if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS))
    {
        Serial.println(F("SSD1306 allocation failed"));
        for (;;)
            ;
    }

    display.clearDisplay();
    display.setTextSize(4);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println(F("OK"));
    display.display();
    delay(2000);

    // WiFi connection
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(1000);
        Serial.println("Connecting to WiFi...");
    }

    // Print IP address
    Serial.println("Connected to WiFi");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    // Show IP on OLED
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("Server IP:");
    display.println(WiFi.localIP());
    display.display();
    delay(3000); // Show IP for 3 seconds

    // Bắt đầu server
    server.begin();
    Serial.println("Server started");

    // Display initial number from EEPROM
    displayNumber(currentNumber);
}

void loop()
{
    WiFiClient client = server.available();
    if (client)
    {
        String currentLine = "";
        String inputText = "";
        bool success = false;
        unsigned long connectionTime = millis();

        while (client.connected() && millis() - connectionTime < 3000) // 3 second timeout
        {
            if (client.available())
            {
                char c = client.read();
                if (c == '\n')
                {
                    if (currentLine.length() == 0)
                    {
                        // Serve the HTML with current number
                        String htmlContent = FPSTR(INDEX_HTML);
                        htmlContent.replace("%VALUE%", String(currentNumber));

                        client.println("HTTP/1.1 200 OK");
                        client.println("Content-Type: text/html");
                        client.println("Connection: close");
                        client.println();
                        client.print(htmlContent);
                        success = true;
                        Serial.println("Sent main page");
                        break;
                    }
                    currentLine = "";
                }
                else if (c != '\r')
                {
                    currentLine += c;
                }

                // Process display request ngay lập tức khi nhận được
                if (currentLine.endsWith(" HTTP/1.1") && currentLine.startsWith("GET /display"))
                {
                    int numPos = currentLine.indexOf("num=");
                    int sizePos = currentLine.indexOf("size=");
                    int xPos_param = currentLine.indexOf("x=");
                    int yPos_param = currentLine.indexOf("y=");

                    if (numPos > 0)
                    {
                        inputText = currentLine.substring(numPos + 4, currentLine.indexOf('&', numPos));
                        currentNumber = inputText.toInt();

                        if (sizePos > 0) {
                            String sizeStr = currentLine.substring(sizePos + 5, currentLine.indexOf('&', sizePos));
                            textSize = constrain(sizeStr.toInt(), 1, 8);
                        }

                        if (xPos_param > 0) {
                            String xStr = currentLine.substring(xPos_param + 2, currentLine.indexOf('&', xPos_param));
                            xPos = xStr.toInt();
                        }

                        if (yPos_param > 0) {
                            String yStr = currentLine.substring(yPos_param + 2, currentLine.indexOf(' ', yPos_param));
                            yPos = yStr.toInt();
                        }

                        displayNumber(currentNumber);
                        success = true;
                        Serial.println("Processed display request: " + inputText);

                        // Send minimal success response
                        client.println("HTTP/1.1 200 OK");
                        client.println("Content-Type: text/plain");
                        client.println("Connection: close");
                        client.println();
                        client.println("OK");

                        // Update stored number
                        currentNumber = inputText.toInt();
                        EEPROM.put(EEPROM_ADDR, currentNumber);
                        EEPROM.commit();
                        break;
                    }
                }
            }
        }

        // Send error response if no successful processing occurred
        if (!success)
        {
            client.println("HTTP/1.1 408 Request Timeout");
            client.println("Content-Type: text/html");
            client.println("Connection: close");
            client.println();
            client.println("Request timeout or invalid request");
        }

        // Ensure proper connection cleanup
        client.flush();
        while (client.available())
        {
            client.read(); // Clear any remaining data
        }
        client.stop();
    }
}
void displayNumber(int number)
{
    number = constrain(number, 0, 9999);
    display.clearDisplay();
    display.setTextSize(textSize);
    display.setTextColor(SSD1306_WHITE);

    char numStr[5];
    sprintf(numStr, "%04d", number);
    
    // Calculate base position
    int16_t x1, y1;
    uint16_t w, h;
    display.getTextBounds(numStr, 0, 0, &x1, &y1, &w, &h);
    int baseX = (SCREEN_WIDTH - w) / 2;
    int baseY = (SCREEN_HEIGHT - h) / 2;
    
    // Apply position offset with constraints
    baseX = constrain(baseX + xPos, -w, SCREEN_WIDTH);
    baseY = constrain(baseY + yPos, -h, SCREEN_HEIGHT);
    
    display.setCursor(baseX, baseY);
    display.print(numStr);
    display.display();
}
