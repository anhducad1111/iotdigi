<?php
// Database connection
$conn = new mysqli('localhost', 'root', '', 'test');

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Create users table
$sql = "CREATE TABLE IF NOT EXISTS `users` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `email` varchar(255) NOT NULL UNIQUE,
    `password` varchar(255) NOT NULL,
    `is_admin` boolean DEFAULT false,
    `created_at` datetime DEFAULT current_timestamp(),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;";

if ($conn->query($sql) === TRUE) {
    echo "Users table created successfully\n";
} else {
    echo "Error creating table: " . $conn->error . "\n";
}

// Create default admin user
$adminEmail = 'admin@example.com';
$adminPassword = password_hash('admin123', PASSWORD_DEFAULT);

// Check if admin user already exists
$stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
$stmt->bind_param('s', $adminEmail);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt = $conn->prepare("INSERT INTO users (email, password, is_admin) VALUES (?, ?, TRUE)");
    $stmt->bind_param('ss', $adminEmail, $adminPassword);
    
    if ($stmt->execute()) {
        echo "Default admin user created:\n";
        echo "Email: admin@example.com\n";
        echo "Password: admin123\n";
    } else {
        echo "Error creating admin user: " . $stmt->error . "\n";
    }
} else {
    echo "Admin user already exists\n";
}

$stmt->close();
$conn->close();