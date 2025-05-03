<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Get JSON data
$data = json_decode(file_get_contents('php://input'), true);
$email = $data['email'] ?? '';
$password = $data['password'] ?? '';
$address = $data['address'] ?? '';

if (empty($email) || empty($password) || empty($address)) {
    http_response_code(400);
    echo json_encode(['error' => 'Email, password, and address are required']);
    exit;
}

// Validate email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid email format']);
    exit;
}

// Database connection
$conn = new mysqli('localhost', 'root', '', 'test');

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed']);
    exit;
}

// Check if email already exists
$stmt = $conn->prepare('SELECT id FROM users WHERE email = ?');
$stmt->bind_param('s', $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    http_response_code(400);
    echo json_encode(['error' => 'Email already registered']);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

// Hash password
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

// Insert new user
$stmt = $conn->prepare('INSERT INTO users (email, password, address, is_admin) VALUES (?, ?, ?, FALSE)');
$stmt->bind_param('sss', $email, $hashedPassword, $address);

if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode(['error' => 'Registration failed']);
    $stmt->close();
    $conn->close();
    exit;
}

// Success
echo json_encode([
    'success' => true,
    'user' => [
        'email' => $email,
        'address' => $address,
        'isAdmin' => false
    ]
]);

$stmt->close();
$conn->close();