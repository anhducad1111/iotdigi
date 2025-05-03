<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "test";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['error' => 'Database connection failed: ' . $conn->connect_error]));
}

try {
    // Get OCR readings for past 5 days ordered by timestamp
    $sql = "SELECT DATE(timestamp) as date, ocr_text, timestamp 
            FROM ocr_results 
            WHERE timestamp >= DATE_SUB(CURDATE(), INTERVAL 4 DAY)
            ORDER BY timestamp ASC";
            
    $result = $conn->query($sql);
    
    if ($result === FALSE) {
        throw new Exception("Error getting stats: " . $conn->error);
    }

    // Group readings by date and calculate differences
    $dailyReadings = [];
    $previousReading = null;
    $previousDate = null;

    while ($row = $result->fetch_assoc()) {
        $date = $row['date'];
        $currentReading = floatval($row['ocr_text']);
        
        if (!isset($dailyReadings[$date])) {
            $dailyReadings[$date] = 0;
        }

        if ($previousReading !== null && $date === $previousDate) {
            $difference = $currentReading - $previousReading;
            if ($difference > 0) {  // Only add positive differences
                $dailyReadings[$date] += $difference;
            }
        }

        $previousReading = $currentReading;
        $previousDate = $date;
    }

    // Convert to array format for response
    $readings = [];
    foreach ($dailyReadings as $date => $usage) {
        $readings[] = [
            'date' => $date,
            'value' => round($usage, 1)  // Round to 1 decimal place
        ];
    }

    // Sort by date descending
    usort($readings, function($a, $b) {
        return strcmp($b['date'], $a['date']);
    });

    // Pad with zeros if less than 5 days
    while (count($readings) < 5) {
        $lastDate = end($readings)['date'];
        $previousDay = date('Y-m-d', strtotime($lastDate . ' -1 day'));
        $readings[] = [
            'date' => $previousDay,
            'value' => 0
        ];
    }

    // Limit to exactly 5 days
    $readings = array_slice($readings, 0, 5);

    echo json_encode([
        'success' => true,
        'readings' => $readings,
        'debug' => [
            'sql' => $sql,
            'now' => date('Y-m-d H:i:s'),
            'count' => count($readings)
        ]
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    error_log("get_stats.php error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage()
    ]);
}

$conn->close();
?>