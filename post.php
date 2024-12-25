<?php
header('Content-Type: application/json');

// Database configuration
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "test";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode([
        'status' => 'error',
        'message' => 'Connection failed: ' . $conn->connect_error
    ]));
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST['ocr_text']) || (json_decode(file_get_contents('php://input'), true)['ocr_text'] ?? null)) {
        
        $ocr_text = $_POST['ocr_text'] ?? json_decode(file_get_contents('php://input'), true)['ocr_text'];
        if ($ocr_text !== 'none') {
            $sql = "INSERT INTO ocr_results (ocr_text) VALUES (?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("s", $ocr_text);
    
            if ($stmt->execute()) {
                $response = [
                    'status' => 'success',
                    'message' => 'OCR text recorded successfully',
                    'data' => [
                        'ocr_text' => $ocr_text,
                        'timestamp' => date('Y-m-d H:i:s')
                    ]
                ];
            } else {
                $response = [
                    'status' => 'error',
                    'message' => 'Error recording OCR text: ' . $stmt->error
                ];
            }
            $stmt->close();
        } else {
            $response = [
                'status' => 'error',
                'message' => 'OCR text is "none", not recorded'
            ];
        }
    }
    // Handle file upload (existing code)
    elseif (isset($_FILES['file'])) {
        $upload_dir = 'video_stream/';
        $file_path = $upload_dir . 'uploaded_image.jpg';
        
        if (move_uploaded_file($_FILES['file']['tmp_name'], $file_path)) {
            $response = [
                'status' => 'success',
                'message' => 'File uploaded successfully',
                'filename' => 'uploaded_image.jpg'
            ];
        } else {
            $response = [
                'status' => 'error',
                'message' => 'Error uploading file'
            ];
        }
    }
    // Handle sensor data (existing code)
    elseif (isset($_POST['temp']) && isset($_POST['hum'])) {
        $temperature = floatval($_POST['temp']);
        $humidity = floatval($_POST['hum']);
        
        // Insert sensor data into database
        $sql = "INSERT INTO dht_data (temperature, humidity, timestamp) VALUES (?, ?, NOW())";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("dd", $temperature, $humidity);
        
        if ($stmt->execute()) {
            $response = [
                'status' => 'success',
                'message' => 'Sensor data recorded successfully',
                'data' => [
                    'temperature' => $temperature,
                    'humidity' => $humidity,
                    'timestamp' => date('Y-m-d H:i:s')
                ]
            ];
        } else {
            $response = [
                'status' => 'error',
                'message' => 'Error recording sensor data: ' . $stmt->error
            ];
        }
        $stmt->close();
    } else {
        $response = [
            'status' => 'error',
            'message' => 'No file, sensor data, or OCR text provided'
        ];
    }
} else {
    $response = [
        'status' => 'error',
        'message' => 'Invalid request method'
    ];
}

$conn->close();
echo json_encode($response);
?>