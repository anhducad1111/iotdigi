# System Architecture

```mermaid
graph TD
    subgraph IoT Devices
        ESP32CAM[ESP32-CAM Module]
        OLED[OLED Display]
        SendNode[Send Node]
        ReceiveNode[Receive Node]
    end

    subgraph Web Server
        PHP[PHP Backend]
        DB[(MySQL Database)]
    end

    subgraph Client
        Browser[Web Browser]
    end

    ESP32CAM -->|Video Stream| PHP
    SendNode -->|Data| ReceiveNode
    ReceiveNode -->|Processed Data| PHP
    OLED -->|Display Status| Browser

    PHP -->|Store Data| DB
    PHP -->|Serve Video/Data| Browser

    Browser -->|View Stream| PHP
    Browser -->|Control Interface| PHP
