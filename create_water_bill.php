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

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['device_id'])) {
    die(json_encode([
        'status' => 'error',
        'message' => 'Device ID is required'
    ]));
}

try {
    // Get latest OCR reading for this device
    $stmt = $conn->prepare("SELECT ocr_text FROM ocr_results WHERE device_id = ? ORDER BY timestamp DESC LIMIT 1");
    $stmt->bind_param("i", $data['device_id']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($reading = $result->fetch_assoc()) {
        // Calculate bill amount based on water usage
        $usage = intval(preg_replace('/[^0-9]/', '', $reading['ocr_text']));
        
        // Water rate tiers (in VND per cubic meter)
        $rates = [
            10 => 5973,  // First 10m³
            20 => 7052,  // Next 10m³
            30 => 8669,  // Next 10m³
            PHP_INT_MAX => 15929  // Over 30m³
        ];
        
        $total_amount = 0;
        $remaining = $usage;
        $prev_tier = 0;
        
        foreach ($rates as $tier => $rate) {
            $tier_usage = min($remaining, $tier - $prev_tier);
            $total_amount += $tier_usage * $rate;
            $remaining -= $tier_usage;
            $prev_tier = $tier;
            if ($remaining <= 0) break;
        }

        // Create water bill record
        $stmt = $conn->prepare("INSERT INTO water_bills (device_id, reading_value, amount, ocr_result_id) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("iidi", $data['device_id'], $usage, $total_amount, $data['ocr_result_id']);
        
        if ($stmt->execute()) {
            echo json_encode([
                'status' => 'success',
                'message' => 'Water bill created successfully',
                'data' => [
                    'reading' => $usage,
                    'amount' => $total_amount,
                    'device_id' => $data['device_id']
                ]
            ]);
        } else {
            throw new Exception('Failed to create water bill');
        }
    } else {
        throw new Exception('No OCR reading found for this device');
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>