<?php
declare(strict_types=1);

$host = 'localhost'; // ⚠️ change if needed
$db   = 'u196786599_CloopApp';
$user = 'u196786599_CloopAppMysql';
$pass = 'iE^loG+e0|K@cloop_2026';

// MySQLi connection
$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$conn->set_charset('utf8mb4');

// PDO connection
try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("PDO connection failed: " . $e->getMessage());
}