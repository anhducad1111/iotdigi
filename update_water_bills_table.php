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
    // Add paid status column
    $sql = "ALTER TABLE water_bills 
            ADD COLUMN paid BOOLEAN DEFAULT FALSE";

    if (!$conn->query($sql)) {
        throw new Exception("Error adding paid column: " . $conn->error);
    }

    echo "Water bills table updated successfully\n";
    
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