<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "test";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

try {
    // Create water_bills table
    $sql = "CREATE TABLE IF NOT EXISTS water_bills (
        id INT AUTO_INCREMENT PRIMARY KEY,
        device_id INT,
        reading_value INT NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        ocr_result_id INT,
        paid BOOLEAN DEFAULT FALSE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (device_id) REFERENCES devices(id),
        FOREIGN KEY (ocr_result_id) REFERENCES ocr_results(id)
    )";

    if (!$conn->query($sql)) {
        throw new Exception("Error creating water_bills table: " . $conn->error);
    }

    echo "Water bills table setup completed successfully\n";
    
    // Show table structure
    $result = $conn->query("DESCRIBE water_bills");
    while ($row = $result->fetch_assoc()) {
        print_r($row);
        echo "\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?>