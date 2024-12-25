import socket
from machine import Pin, PWM, reset
import camera
import _thread
import urequests
import time
import sys
import gc

# Thiết lập LED với PWM để điều chỉnh độ sáng
led = PWM(Pin(4), freq=1000)
led.duty(0)

# Add OCR API constants
OCR_API_KEY = 'K85797055088957'
NGROK_URL = "1e39-14-236-11-218.ngrok-free.app"  # URL ngrok không cần https://
SERVER_IP = f"https://{NGROK_URL}"  # Use HTTPS for ngrok
IMG_URL = f'{SERVER_IP}/video_upload/video_stream/uploaded_image.jpg'
OCR_API_URL = 'https://api.ocr.space/parse/image'

# Add after constants
DELAY_ON_ERROR = 1
MAX_RETRIES = 3
def send_response(conn, status, content_type, body):
    conn.send(f'HTTP/1.1 {status}\n'.encode())
    conn.send(f'Content-Type: {content_type}\n'.encode())
    conn.send(f'Access-Control-Allow-Origin: *\n'.encode())
    conn.send(b'Connection: close\n\n')
    conn.sendall(body.encode())


def handle_ocr():
    error_count = 0  # Counter for errors
    max_errors = 20  # Maximum allowed errors
    
    while True:
        try:
            # Process OCR
            boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
            headers = {
                'apikey': OCR_API_KEY,
                'Content-Type': f'multipart/form-data; boundary={boundary}'
            }

            parts = [
                f'--{boundary}',
                'Content-Disposition: form-data; name="url"',
                '',
                IMG_URL,
                f'--{boundary}',
                'Content-Disposition: form-data; name="OCREngine"',
                '',
                '2',
                f'--{boundary}--'
            ]

            ocr_payload = '\r\n'.join(parts).encode('utf-8')

            ocr_response = urequests.post(
                OCR_API_URL, data=ocr_payload, headers=headers)

            if ocr_response.status_code == 200:
                result = ocr_response.json()
                parsed_text = result['ParsedResults'][0]['ParsedText']
                if not parsed_text.strip() or parsed_text.strip().lower() == "none":
                    error_count += 1
                    print(f"No text detected. Error count: {error_count}")
                else:
                    error_count = 0  # Reset error count on successful detection
                    print("Extracted text:", parsed_text)

                # Send OCR result to PHP server
                result_payload = {
                    'ocr_text': parsed_text
                }
                result_response = urequests.post(
                    f'{SERVER_IP}/video_upload/post.php', json=result_payload)
                result_response.close()
            else:
                error_count += 1
                print(f"OCR API error: {ocr_response.status_code}")

            ocr_response.close()

        except Exception as e:
            error_count += 1
            print(f'Error in OCR processing: {e}')

        if error_count >= max_errors:
            print(f"Too many errors ({error_count}). Stopping program...")
            reset()  # Reset the device

        time.sleep(10)


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
                send_response(conn, '200 OK', 'text/plain',
                              'Brightness adjusted')
            except ValueError:
                send_response(conn, '400 Bad Request',
                              'text/plain', 'Invalid brightness value')
        else:
            send_response(conn, '404 Not Found', 'text/html',
                          '<html><body><h1>404 Not Found</h1></body></html>')

        conn.close()
    brightness_socket.close()


def handle_streaming():
    boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
    retry_count = 0
    while True:
        gc.collect()  # Memory management
        frame = camera.capture()
        if not frame:
            print("Failed to capture frame")
            continue
        try:
            data = (
                f'--{boundary}\r\n'
                'Content-Disposition: form-data; name="file"; filename="frame.jpg"\r\n'
                'Content-Type: image/jpeg\r\n\r\n'
            ).encode() + frame + f'\r\n--{boundary}--\r\n'.encode()

            headers = {
                'Content-Type': f'multipart/form-data; boundary={boundary}'
            }

            # Sửa lại URL endpoint
            upload_url = f"{SERVER_IP}/video_upload/post.php"
            response = urequests.post(upload_url, data=data, headers=headers)
            print(f'Upload response: {response.status_code}')
            response.close()
            
            if response.status_code != 200:
                retry_count += 1
                if retry_count >= MAX_RETRIES:
                    print("Max retries reached, resetting...")
                    reset()
            else:
                retry_count = 0
            
        except Exception as e:
            print(f'Failed to upload frame: {e}')
            time.sleep(DELAY_ON_ERROR)
            retry_count += 1
            if retry_count >= MAX_RETRIES:
                print("Max retries reached, resetting...")
                reset()


# Khởi chạy các luồng
_thread.start_new_thread(handle_brightness, ())
_thread.start_new_thread(handle_ocr, ())
handle_streaming()
