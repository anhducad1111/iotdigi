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
    // Get all notifications with device names
    $sql = "SELECT n.*, d.name as device_name 
            FROM notifications n
            LEFT JOIN devices d ON n.device_id = d.id
            ORDER BY n.created_at DESC
            LIMIT 50";
            
    $result = $conn->query($sql);
    
    if ($result === FALSE) {
        throw new Exception("Error getting notifications: " . $conn->error);
    }

    $notifications = [];
    while ($row = $result->fetch_assoc()) {
        $notifications[] = [
            'id' => $row['id'],
            'device_id' => $row['device_id'],
            'device_name' => $row['device_name'],
            'type' => $row['type'],
            'message' => $row['message'],
            'created_at' => $row['created_at'],
            'read' => $row['read']
        ];
    }

    echo json_encode([
        'success' => true,
        'notifications' => $notifications
    ]);

} catch (Exception $e) {
    error_log("get_notifications.php error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage()
    ]);
}

$conn->close();
?>