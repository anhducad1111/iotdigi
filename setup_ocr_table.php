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
    // Create ocr_results table
    $sql = "CREATE TABLE IF NOT EXISTS ocr_results (
        id INT AUTO_INCREMENT PRIMARY KEY,
        device_id INT,
        ocr_text VARCHAR(50) NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (device_id) REFERENCES devices(id)
    )";

    if (!$conn->query($sql)) {
        throw new Exception("Error creating ocr_results table: " . $conn->error);
    }

    // Check if timestamp column exists
    $result = $conn->query("SHOW COLUMNS FROM ocr_results LIKE 'timestamp'");
    if ($result->num_rows == 0) {
        // Add timestamp column if it doesn't exist
        $sql = "ALTER TABLE ocr_results 
                ADD COLUMN timestamp DATETIME DEFAULT CURRENT_TIMESTAMP";
        
        if (!$conn->query($sql)) {
            throw new Exception("Error adding timestamp column: " . $conn->error);
        }
    }

    echo "OCR table setup completed successfully\n";
    
    // Show table structure
    $result = $conn->query("DESCRIBE ocr_results");
    while ($row = $result->fetch_assoc()) {
        print_r($row);
        echo "\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?>