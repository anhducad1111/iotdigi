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
    // Handle OCR text data
    if (isset($_POST['ocr_text']) || (json_decode(file_get_contents('php://input'), true)['ocr_text'] ?? null)) {
        // Get OCR text from either POST data or JSON body
        $ocr_text = $_POST['ocr_text'] ?? json_decode(file_get_contents('php://input'), true)['ocr_text'];
        
        // Insert OCR text into database
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
        // ... (keep existing sensor data handling code)
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