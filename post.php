<?php
header('Content-Type: application/json');

// Database configuration
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "test";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die(json_encode([
        'status' => 'error',
        'message' => 'Connection failed: ' . $conn->connect_error
    ]));
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST['ocr_text']) || (json_decode(file_get_contents('php://input'), true)['ocr_text'] ?? null)) {
        // Handle OCR text
        $ocr_text = $_POST['ocr_text'] ?? json_decode(file_get_contents('php://input'), true)['ocr_text'];
        if ($ocr_text !== "none" && $ocr_text !== 'none') {
            // Get first reading of current month
            $current_month = date('Y-m');
            $first_reading_sql = "SELECT ocr_text FROM ocr_results 
                                WHERE DATE_FORMAT(timestamp, '%Y-%m') = '$current_month' 
                                ORDER BY timestamp ASC LIMIT 1";
            $first_result = $conn->query($first_reading_sql);
            
            // Calculate water bill if we have a first reading
            $water_bill = 0;
            $debug_info = [];
            
            if ($first_result->num_rows > 0) {
                $first_row = $first_result->fetch_assoc();
                $first_reading = intval($first_row['ocr_text']);
                $curr_reading = intval($ocr_text);
                $water_usage = $curr_reading - $first_reading;
                $water_bill = calculate_water_bill($water_usage);
                
                $debug_info = [
                    'first_reading' => $first_reading,
                    'current_reading' => $curr_reading,
                    'water_usage' => $water_usage,
                    'month' => $current_month
                ];
            } else {
                $debug_info = [
                    'message' => 'First reading of month not found',
                    'month' => $current_month,
                    'query' => $first_reading_sql
                ];
            }
            
            $sql = "INSERT INTO ocr_results (ocr_text, water_bill) VALUES (?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("sd", $ocr_text, $water_bill);
    
            if ($stmt->execute()) {
                $response = [
                    'status' => 'success',
                    'message' => 'OCR text recorded successfully',
                    'data' => [
                        'ocr_text' => $ocr_text,
                        'water_bill' => $water_bill,
                        'timestamp' => time()
                    ],
                    'debug' => $debug_info
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
    // Handle file upload
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
    // Handle sensor data
    elseif (isset($_POST['temp']) && isset($_POST['humidity']) && isset($_POST['air_quality'])) {
        $temperature = floatval($_POST['temp']);
        $humidity = floatval($_POST['humidity']);
        $air_quality = floatval($_POST['air_quality']);
        
        $sql = "INSERT INTO sensor_data (temperature, humidity, air_quality) VALUES (?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ddd", $temperature, $humidity, $air_quality);
        
        if ($stmt->execute()) {
            $response = [
                'status' => 'success',
                'message' => 'Sensor data recorded successfully',
                'data' => [
                    'temperature' => $temperature,
                    'humidity' => $humidity,
                    'air_quality' => $air_quality,
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
            'message' => 'No file, sensor data, or OCR text provided',
            'received' => $_POST
        ];
    }
} else {
    $response = [
        'status' => 'error',
        'message' => 'Invalid request method'
    ];
}

function calculate_water_bill($usage) {
    if ($usage <= 0) return 0;
    $bill = 0;

    // Bậc 1: 0-10m³, giá 5.973đ/m³
    if ($usage <= 10) {
        $bill = $usage * 5973;
    }
    // Bậc 2: 10-20m³, giá 7.052đ/m³
    elseif ($usage <= 20) {
        $bill = (10 * 5973) + (($usage - 10) * 7052);
    }
    // Bậc 3: 20-30m³, giá 8.699đ/m³
    elseif ($usage <= 30) {
        $bill = (10 * 5973) + (10 * 7052) + (($usage - 20) * 8699);
    }
    // Bậc 4: >30m³, giá 15.929đ/m³
    else {
        $bill = (10 * 5973) + (10 * 7052) + (10 * 8699) + (($usage - 30) * 15929);
    }

    // Add VAT 5%
    $bill *= 1.05;
    
    // Add environmental fee (10% of water bill)
    $bill *= 1.1;

    return round($bill);
}

$conn->close();
echo json_encode($response);
?>
