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

// Get latest 10 readings
$sql = "SELECT temperature, humidity, timestamp FROM dht_data ORDER BY timestamp DESC LIMIT 10";
$result = $conn->query($sql);

$readings = [];
$latest = null;

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        if ($latest === null) {
            $latest = $row;
        }
        $readings[] = [
            'temperature' => number_format($row['temperature'], 1),
            'humidity' => number_format($row['humidity'], 1),
            'timestamp' => $row['timestamp']
        ];
    }
}

$response = [
    'status' => 'success',
    'latest' => $latest,
    'readings' => $readings
];

$conn->close();
echo json_encode($response);
?>