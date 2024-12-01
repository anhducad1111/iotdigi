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

$response = [
    'status' => 'success',
    'latest_sensor_reading' => $latest_sensor_reading,
    'sensor_readings' => $sensor_readings,
    'latest_ocr_result' => $latest_ocr_result
];

$conn->close();
echo json_encode($response);
?>