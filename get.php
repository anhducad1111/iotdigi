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
$sql = "SELECT timestamp, temperature, humidity, air_quality 
        FROM sensor_data 
        ORDER BY timestamp DESC 
        LIMIT 10";

$result = $conn->query($sql);
$sensor_readings = [];
$latest_sensor_reading = null;

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        if ($latest_sensor_reading === null) {
            $latest_sensor_reading = $row;
        }
        $sensor_readings[] = [
            'temperature' => number_format($row['temperature'], 1),
            'humidity' => number_format($row['humidity'], 1),
            'air_quality' => number_format($row['air_quality'], 1),
            'timestamp' => $row['timestamp']
        ];
    }
}

// Get current month's first and latest readings
$current_month = date('Y-m');
$readings_sql = "SELECT id, ocr_text, water_bill, timestamp 
                FROM ocr_results 
                WHERE DATE_FORMAT(timestamp, '%Y-%m') = '$current_month'
                ORDER BY timestamp ASC";
$readings_result = $conn->query($readings_sql);

$first_reading = null;
$latest_reading = null;
$all_readings = [];
$water_usage = 0;

if ($readings_result->num_rows > 0) {
    while($row = $readings_result->fetch_assoc()) {
        if ($first_reading === null) {
            $first_reading = $row;
        }
        $latest_reading = $row;
        
        // Calculate water usage from first reading
        if ($first_reading) {
            $water_usage = intval($row['ocr_text']) - intval($first_reading['ocr_text']);
            $row['water_usage'] = $water_usage;
        }
        
        $all_readings[] = $row;
    }
}

$response = [
    'status' => 'success',
    'sensor_data' => [
        'latest' => $latest_sensor_reading,
        'history' => $sensor_readings
    ],
    'water_data' => [
        'first_reading' => $first_reading,
        'latest_reading' => $latest_reading,
        'all_readings' => $all_readings,
        'debug' => [
            'month' => $current_month,
            'total_readings' => count($all_readings),
            'total_water_usage' => $water_usage
        ]
    ]
];

$conn->close();
echo json_encode($response);
?>
