import requests
import time

# API key
api_key = 'K85797055088957'

# OCR.Space API URL 
api_url = 'https://api.ocr.space/parse/image'

# Image URL
img_url = 'http://192.168.1.5/video_upload/video_stream/uploaded_image.jpg'

def process_image():
    while True:
        payload = {
            'apikey': api_key,
            'url': img_url,
            'OCREngine': '2'
        }
        response = requests.post(api_url, data=payload)
        if response.status_code == 200:
            print("Image processed successfully:", response.json())
        else:
            print("Error processing image:", response.status_code, response.text)
        time.sleep(10)

# Call the function
process_image()