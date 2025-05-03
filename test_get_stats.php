<?php
// Test script to check stats data
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "test";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Check if tables exist
$tables = ['water_bills', 'ocr_results'];
foreach ($tables as $table) {
    $result = $conn->query("SHOW TABLES LIKE '$table'");
    echo "$table exists: " . ($result->num_rows > 0 ? "Yes" : "No") . "\n";
}

// Check data in water_bills
echo "\nWater Bills Data:\n";
$result = $conn->query("SELECT * FROM water_bills");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        print_r($row);
    }
} else {
    echo "Error querying water_bills: " . $conn->error . "\n";
}

// Check data in ocr_results
echo "\nOCR Results Data:\n";
$result = $conn->query("SELECT * FROM ocr_results");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        print_r($row);
    }
} else {
    echo "Error querying ocr_results: " . $conn->error . "\n";
}

// Test the join query
echo "\nTesting join query:\n";
$sql = "SELECT wb.amount, wb.created_at, o.ocr_text as reading
        FROM water_bills wb
        JOIN ocr_results o ON wb.ocr_result_id = o.id
        ORDER BY wb.created_at ASC";
$result = $conn->query($sql);
if ($result) {
    while ($row = $result->fetch_assoc()) {
        print_r($row);
    }
} else {
    echo "Error with join query: " . $conn->error . "\n";
}

$conn->close();
?>