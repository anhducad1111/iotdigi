<?php
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "test";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['error' => 'Connection failed: ' . $conn->connect_error]));
}

try {
    // Create devices table
    $sql = "CREATE TABLE IF NOT EXISTS devices (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,             
        location_lat FLOAT,                     
        location_lng FLOAT,                     
        user_id INT,                          
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
    )";

    if (!$conn->query($sql)) {
        throw new Exception("Error creating devices table: " . $conn->error);
    }

    // Create notifications table
    $sql = "CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        device_id INT,
        type ENUM('gas', 'fire', 'system') NOT NULL,
        message TEXT NOT NULL,
        `read` TINYINT(1) DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (device_id) REFERENCES devices(id)
    )";

    if (!$conn->query($sql)) {
        throw new Exception("Error creating notifications table: " . $conn->error);
    }

    // Check if notifications table is empty
    $result = $conn->query("SELECT COUNT(*) as count FROM notifications");
    $row = $result->fetch_assoc();
    
    if ($row['count'] == 0) {
        // Insert sample notification
        $sql = "INSERT INTO notifications (device_id, type, message) VALUES (?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $device_id = 1;
        $type = 'system';
        $message = 'Thiết bị đã được khởi tạo thành công';
        $stmt->bind_param("iss", $device_id, $type, $message);
        
        if (!$stmt->execute()) {
            throw new Exception("Error inserting sample notification: " . $stmt->error);
        }
        $stmt->close();
    }

    // Create water_bills table
    $sql = "CREATE TABLE IF NOT EXISTS water_bills (
        id INT AUTO_INCREMENT PRIMARY KEY,
        device_id INT,
        ocr_result_id INT,                    
        amount FLOAT NOT NULL,                
        rate_per_unit FLOAT DEFAULT 5000,     
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (device_id) REFERENCES devices(id),
        FOREIGN KEY (ocr_result_id) REFERENCES ocr_results(id)
    )";

    if (!$conn->query($sql)) {
        throw new Exception("Error creating water_bills table: " . $conn->error);
    }

    // Modify ocr_results table to add device_id if not exists
    $result = $conn->query("SHOW COLUMNS FROM ocr_results LIKE 'device_id'");
    if ($result->num_rows == 0) {
        $sql = "ALTER TABLE ocr_results 
                ADD COLUMN device_id INT AFTER id,
                ADD FOREIGN KEY (device_id) REFERENCES devices(id)";
        
        if (!$conn->query($sql)) {
            throw new Exception("Error modifying ocr_results table: " . $conn->error);
        }
    }

    // Check if devices table is empty
    $result = $conn->query("SELECT COUNT(*) as count FROM devices");
    $row = $result->fetch_assoc();
    
    if ($row['count'] == 0) {
        // Insert sample device
        $sql = "INSERT INTO devices (name, user_id) VALUES (?, ?)";
        $stmt = $conn->prepare($sql);
        $name = "ESP32-CAM 1";
        $userId = 1; // Assuming admin user has ID 1
        $stmt->bind_param("si", $name, $userId);
        
        if (!$stmt->execute()) {
            throw new Exception("Error inserting sample device: " . $stmt->error);
        }
        $stmt->close();
    }

    echo json_encode([
        'success' => true,
        'message' => 'Database setup completed successfully'
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}

$conn->close();
?>