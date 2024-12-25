from machine import Pin, SoftI2C
import ssd1306
from time import sleep
import random
import urequests
import dht

# Initialize OLED display
i2c = SoftI2C(scl=Pin(22), sda=Pin(21))
oled_width = 128
oled_height = 64
oled = ssd1306.SSD1306_I2C(oled_width, oled_height, i2c)
dht_sensor = dht.DHT22(Pin(2))
# Function to simulate DHT sensor data
def read_dht_data():
    try:
        dht_sensor.measure()
        temp = dht_sensor.temperature()
        hum = dht_sensor.humidity()
        return temp, hum
    except Exception as e:
        print(f'DHT sensor error: {e}')
        return None, None

# Function to read sensor and update OLED display
def read_and_display_sensor():
    temp, hum = read_dht_data()
    if (isinstance(temp, float) and isinstance(hum, float)) or (isinstance(temp, int) and (isinstance(hum, int))):
        oled.fill(0)
        oled.text('Temp: {:.1f} C'.format(temp), 0, 0)
        oled.text('Hum: {:.1f} %'.format(hum), 0, 10)
        oled.show()
        return temp, hum
    return None, None

# URL của endpoint PHP
url = 'http://192.168.1.5/video_upload/post.php'

print('Starting sensor monitoring...')

while True:
    try:
        temp, hum = read_and_display_sensor()
        
        if temp is not None and hum is not None:
            data = 'temp={}&hum={}'.format(temp, hum)
            headers = {'Content-Type': 'application/x-www-form-urlencoded'}
            response = urequests.post(url, data=data, headers=headers)
            print('Data sent:', data)
            print('Server response:', response.text)
            response.close()  # Close the response to free resources
    except Exception as e:
        print('Error:', str(e))
    
    sleep(10)  # Wait for 10 seconds before next reading