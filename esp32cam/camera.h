#ifndef CAMERA_H
#define CAMERA_H

#include "config.h"
#include <esp_camera.h>

class Camera {
private:
    static bool initialized;

public:
    static bool init() {
        if (initialized) {
            return true;
        }

        camera_config_t config;
        config.ledc_channel = LEDC_CHANNEL_0;
        config.ledc_timer = LEDC_TIMER_0;
        config.pin_d0 = CAMERA_PIN_Y2;
        config.pin_d1 = CAMERA_PIN_Y3;
        config.pin_d2 = CAMERA_PIN_Y4;
        config.pin_d3 = CAMERA_PIN_Y5;
        config.pin_d4 = CAMERA_PIN_Y6;
        config.pin_d5 = CAMERA_PIN_Y7;
        config.pin_d6 = CAMERA_PIN_Y8;
        config.pin_d7 = CAMERA_PIN_Y9;
        config.pin_xclk = CAMERA_PIN_XCLK;
        config.pin_pclk = CAMERA_PIN_PCLK;
        config.pin_vsync = CAMERA_PIN_VSYNC;
        config.pin_href = CAMERA_PIN_HREF;
        config.pin_sscb_sda = CAMERA_PIN_SIOD;
        config.pin_sscb_scl = CAMERA_PIN_SIOC;
        config.pin_pwdn = CAMERA_PIN_PWDN;
        config.pin_reset = CAMERA_PIN_RESET;
        config.xclk_freq_hz = CAMERA_XCLK_FREQ;
        config.pixel_format = PIXFORMAT_JPEG;
        config.frame_size = CAMERA_FRAME_SIZE;
        config.jpeg_quality = CAMERA_JPEG_QUALITY;
        config.fb_count = CAMERA_FB_COUNT;

        esp_err_t err = esp_camera_init(&config);
        if (err != ESP_OK) {
            Serial.printf("Camera initialization failed with error 0x%x\n", err);
            return false;
        }

        initialized = true;
        Serial.println("Camera initialized successfully");
        return true;
    }

    static camera_fb_t* capture() {
        if (!initialized) {
            return nullptr;
        }
        return esp_camera_fb_get();
    }

    static void release(camera_fb_t* fb) {
        if (fb) {
            esp_camera_fb_return(fb);
        }
    }
};

bool Camera::initialized = false;

#endif // CAMERA_H