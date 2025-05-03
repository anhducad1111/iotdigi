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
                        'timestamp' => time()
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
        $upload_dir = __DIR__ . '/video_stream/';
        $file_path = $upload_dir . 'uploaded_image.jpg';
        
        error_log("Received file upload request. File details: " . print_r($_FILES['file'], true));
        
        // Create video_stream directory if it doesn't exist
        if (!is_dir($upload_dir)) {
            error_log("Creating upload directory: " . $upload_dir);
            if (!mkdir($upload_dir, 0777, true)) {
                error_log("Failed to create directory: " . error_get_last()['message']);
            }
        }

        // Ensure directory has correct permissions
        chmod($upload_dir, 0777);
        
        if (!is_writable($upload_dir)) {
            error_log("Upload directory is not writable");
            chmod($upload_dir, 0777);
        }
        
        if (move_uploaded_file($_FILES['file']['tmp_name'], $file_path)) {
            error_log("File uploaded successfully to: " . $file_path);
            $response = [
                'status' => 'success',
                'message' => 'File uploaded successfully',
                'filename' => 'uploaded_image.jpg'
            ];
        } else {
            $error = error_get_last();
            error_log("Failed to move uploaded file. Error: " . ($error ? $error['message'] : 'Unknown error'));
            $response = [
                'status' => 'error',
                'message' => 'Error uploading file: ' . ($error ? $error['message'] : 'Unknown error')
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
                    'timestamp' => time()
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