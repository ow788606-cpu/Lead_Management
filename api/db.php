<?php
declare(strict_types=1);

$conn = new mysqli('127.0.0.1', 'root', '', 'lead');

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed',
    ]);
    exit;
}

$conn->set_charset('utf8mb4');

// Also create PDO connection for compatibility
try {
    $pdo = new PDO('mysql:host=127.0.0.1;dbname=lead;charset=utf8mb4', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'PDO Database connection failed',
    ]);
    exit;
}
