<?php
header('Content-Type: application/json');

// MySQL connection settings
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "test";

// Google Geolocation API configuration
$project_id = "esp32camproject-458417";
$api_key = "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"; // Replace with your actual API key

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['device_id']) || !isset($data['wifi_networks'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required data']);
    exit;
}

// Connect to database
$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed']);
    exit;
}

$device_id = $data['device_id'];
$wifi_networks = $data['wifi_networks'];

// Store WiFi data
foreach ($wifi_networks as $network) {
    $stmt = $conn->prepare("INSERT INTO wifi_locations (device_id, ssid, mac_address, rssi) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("issi", $device_id, $network['ssid'], $network['mac_address'], $network['rssi']);
    $stmt->execute();
    $stmt->close();
}

// Prepare data for Google Geolocation API
$geolocation_data = [
    'considerIp' => false,
    'wifiAccessPoints' => array_map(function($network) {
        return [
            'macAddress' => $network['mac_address'],
            'signalStrength' => $network['rssi'],
            'signalToNoiseRatio' => 0
        ];
    }, $wifi_networks)
];

// Call Google Geolocation API with project ID
$geolocation_url = "https://www.googleapis.com/geolocation/v1/geolocate?key=" . $api_key;
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $geolocation_url);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($geolocation_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'X-Goog-FieldMask: location,accuracy'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($http_code === 200) {
    $location = json_decode($response, true);
    
    if (isset($location['location'])) {
        // Update device location in database
        $stmt = $conn->prepare("UPDATE devices SET location_lat = ?, location_lng = ? WHERE id = ?");
        $stmt->bind_param("ddi", 
            $location['location']['lat'],
            $location['location']['lng'],
            $device_id
        );
        $stmt->execute();
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'location' => $location['location']
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Invalid location data from API']);
    }
} else {
    http_response_code(500);
    echo json_encode([
        'error' => 'Failed to get location',
        'api_response' => $response
    ]);
}

$conn->close();
?>