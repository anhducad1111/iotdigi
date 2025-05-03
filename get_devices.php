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
    // For debugging
    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

    // 1. Get base device info
    $devices = [];
    $sql = "SELECT d.*, u.Address as user_address
            FROM devices d
            LEFT JOIN users u ON d.user_id = u.id";
    $result = $conn->query($sql);
    
    if ($result === FALSE) {
        throw new Exception("Error getting devices: " . $conn->error);
    }

    while ($device = $result->fetch_assoc()) {
        $device_id = $device['id'];
        
        // 2. Get latest OCR for this device
        $sql_ocr = "SELECT ocr_text, timestamp 
                    FROM ocr_results 
                    WHERE device_id = $device_id 
                    ORDER BY timestamp DESC 
                    LIMIT 1";
        $ocr_result = $conn->query($sql_ocr)->fetch_assoc();

        // Check if 'paid' column exists
        $columns_result = $conn->query("SHOW COLUMNS FROM water_bills LIKE 'paid'");
        $has_paid_column = $columns_result->num_rows > 0;

        // 3. Get all bills for this device
        $sql_bills = "SELECT id, amount, created_at, rate_per_unit" .
                    ($has_paid_column ? ", paid" : ", FALSE as paid") .
                    " FROM water_bills
                      WHERE device_id = $device_id
                      ORDER BY created_at DESC";
        $bills_result = $conn->query($sql_bills);
        if ($bills_result === FALSE) {
            throw new Exception("Error getting bills: " . $conn->error);
        }

        $bills = [];
        while ($bill = $bills_result->fetch_assoc()) {
            // Convert paid to boolean
            $bill['paid'] = $has_paid_column ? (bool)$bill['paid'] : false;
            $bills[] = $bill;
        }

        // Combine all data
        $devices[] = [
            'id' => $device['id'],
            'name' => $device['name'],
            'address' => $device['user_address'],
            'last_reading' => $ocr_result ? $ocr_result['ocr_text'] : null,
            'last_update' => $ocr_result ? $ocr_result['timestamp'] : null,
            'bills' => array_map(function($bill) {
                return [
                    'id' => $bill['id'],
                    'amount' => floatval($bill['amount']),
                    'date' => $bill['created_at'],
                    'rate' => floatval($bill['rate_per_unit']),
                    'paid' => $bill['paid']
                ];
            }, $bills),
            'debug_info' => [
                'has_ocr' => !empty($ocr_result),
                'bill_count' => count($bills),
                'sql_ocr' => $sql_ocr,
                'sql_bills' => $sql_bills
            ]
        ];
    }

    echo json_encode([
        'success' => true,
        'devices' => $devices,
        'debug' => [
            'sql_base' => $sql,
            'device_count' => count($devices),
            'mysql_version' => mysqli_get_server_info($conn)
        ]
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    error_log("get_devices.php error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ], JSON_PRETTY_PRINT);
}

$conn->close();
?>