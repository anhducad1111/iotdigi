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

// Handle POST requests
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Handle file upload
    if (isset($_FILES['file'])) {
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
    // Handle sensor data
    elseif (isset($_POST['temp']) && isset($_POST['hum'])) {
        $temp = floatval($_POST['temp']);
        $hum = floatval($_POST['hum']);

        // Validate data
        if ($temp !== 0 && $hum !== 0) {
            // Insert data into database
            $sql = "INSERT INTO dht_data (temperature, humidity) VALUES (?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("dd", $temp, $hum);

            if ($stmt->execute()) {
                $response = [
                    'status' => 'success',
                    'message' => 'Sensor data recorded successfully',
                    'data' => [
                        'temperature' => $temp,
                        'humidity' => $hum,
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
                'message' => 'Invalid temperature or humidity values'
            ];
        }
    } else {
        $response = [
            'status' => 'error',
            'message' => 'No file or sensor data provided'
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