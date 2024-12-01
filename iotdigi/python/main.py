import socket
from machine import Pin, PWM
import camera
import _thread

# Thiết lập LED với PWM để điều chỉnh độ sáng
led = PWM(Pin(4), freq=1000)
led.duty(0)

def send_response(conn, status, content_type, body):
    conn.send(f'HTTP/1.1 {status}\n'.encode())
    conn.send(f'Content-Type: {content_type}\n'.encode())
    conn.send(b'Connection: close\n\n')
    conn.sendall(body.encode())

def handle_brightness():
    brightness_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    brightness_socket.bind(('', 81))
    brightness_socket.listen(5)
    while True:
        conn, addr = brightness_socket.accept()
        print(f'Brightness control connection from {addr}')
        request = conn.recv(1024).decode()
        print(f'Brightness Control Request = {request}')
        
        slider_value = request.find('/slider?value=')
        if slider_value != -1:
            try:
                value = int(request.split('=')[1].split(' ')[0])
                led.duty(value)
                print(f'Set brightness to {value}')
                send_response(conn, '200 OK', 'text/plain', 'Brightness adjusted')
            except ValueError:
                send_response(conn, '400 Bad Request', 'text/plain', 'Invalid brightness value')
        else:
            send_response(conn, '404 Not Found', 'text/html', '<html><body><h1>404 Not Found</h1></body></html>')
        
        conn.close()
    brightness_socket.close()

def handle_streaming():
    stream_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    stream_socket.bind(('', 80))
    stream_socket.listen(5)
    while True:
        conn, addr = stream_socket.accept()
        print(f'Video streaming connection from {addr}')
        try:
            conn.send(b'HTTP/1.1 200 OK\r\n')
            conn.send(b'Content-Type: multipart/x-mixed-replace; boundary=frame\r\n\r\n')
            while True:
                frame = camera.capture()
                conn.send(b'--frame\r\n')
                conn.send(b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
        except OSError:
            print("Stream connection closed.")
        finally:
            conn.close()
    stream_socket.close()

# Khởi chạy các luồng
_thread.start_new_thread(handle_brightness, ())
handle_streaming()