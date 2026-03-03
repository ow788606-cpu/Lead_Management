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
