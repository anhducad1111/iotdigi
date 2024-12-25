
try:
  import usocket as socket
  import urequests
except ImportError:
  import socket  
  upip.install('micropython-urequests')
from machine import Pin
import network
import camera
import upip
camera.init(0, format=camera.JPEG, fb_location=camera.PSRAM)

import esp
esp.osdebug(None)

import gc
gc.collect()

ssid = 'Ucey Kingdom'
password = '215537491'

station = network.WLAN(network.STA_IF)

station.active(True)
station.connect(ssid, password)

while station.isconnected() == False:
  pass

print('Connection successful')
print(station.ifconfig())


