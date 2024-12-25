<?php
header('Content-Type: application/json');

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

// Get latest 10 sensor readings
$sensor_sql = "SELECT temperature, humidity, timestamp FROM dht_data ORDER BY timestamp DESC LIMIT 10";
$sensor_result = $conn->query($sensor_sql);

$sensor_readings = [];
$latest_sensor_reading = null;

if ($sensor_result->num_rows > 0) {
    while($sensor_row = $sensor_result->fetch_assoc()) {
        if ($latest_sensor_reading === null) {
            $latest_sensor_reading = $sensor_row;
        }
        $sensor_readings[] = [
            'temperature' => number_format($sensor_row['temperature'], 1),
            'humidity' => number_format($sensor_row['humidity'], 1),
            'timestamp' => $sensor_row['timestamp']
        ];
    }
}

// Get latest OCR result
$ocr_sql = "SELECT ocr_text, timestamp FROM ocr_results ORDER BY timestamp DESC LIMIT 1";
$ocr_result = $conn->query($ocr_sql);

$latest_ocr_result = null;

if ($ocr_result->num_rows > 0) {
    $latest_ocr_result = $ocr_result->fetch_assoc();
}

$current_month = date('Y-m');
$ocr_month_sql = "SELECT id, ocr_text, timestamp FROM ocr_results WHERE timestamp LIKE '$current_month%' ORDER BY timestamp";
$ocr_month_result = $conn->query($ocr_month_sql);

$ocr_readings = [];

if ($ocr_month_result->num_rows > 0) {
    while($ocr_row = $ocr_month_result->fetch_assoc()) {
        $ocr_readings[] = $ocr_row;
    }
}

$leak_alert = false;
$current_time = time();  // Lấy thời gian hiện tại

if (count($ocr_readings) > 1) {
    for ($i = 0; $i < count($ocr_readings); $i++) {
        for ($j = $i + 1; $j < count($ocr_readings); $j++) {
            $time1 = strtotime($ocr_readings[$i]['timestamp']);
            $time2 = strtotime($ocr_readings[$j]['timestamp']);
            $reading1 = (float)$ocr_readings[$i]['ocr_text'];
            $reading2 = (float)$ocr_readings[$j]['ocr_text'];

            // Kiểm tra nếu thời gian chênh lệch <= 24 giờ và giá trị tăng > 5
            if (($time2 - $time1) <= 86400 && ($time2 - $time1) >= 0 && ($reading2 - $reading1) > 5) {
                $leak_alert = true;
                break 2; // Thoát khỏi cả hai vòng lặp nếu phát hiện
            }
        }
    }
}

$response = [
    'status' => 'success',
    'latest_sensor_reading' => $latest_sensor_reading,
    'sensor_readings' => $sensor_readings,
    'latest_ocr_result' => $latest_ocr_result,
    'ocr_readings' => $ocr_readings,
    'leak_alert' => $leak_alert 
];
$conn->close();
echo json_encode($response);
?>