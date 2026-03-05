<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed',
    ]);
    exit;
}

require_once __DIR__ . '/db.php';

$payload = json_decode(file_get_contents('php://input'), true);
$identifier = trim((string)($payload['identifier'] ?? ''));
$password = (string)($payload['password'] ?? '');

if ($identifier === '' || $password === '') {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid user id and password',
    ]);
    exit;
}

$stmt = $conn->prepare(
    "SELECT user_Id, userName, email, user_secret
     FROM users
     WHERE deleted_at IS NULL
       AND (CAST(user_Id AS CHAR) = ? OR email = ? OR userName = ?)
     LIMIT 1"
);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Prepare failed',
    ]);
    exit;
}

$stmt->bind_param('sss', $identifier, $identifier, $identifier);
$stmt->execute();
$result = $stmt->get_result();
$user = $result ? $result->fetch_assoc() : null;
$stmt->close();

if (!$user) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid user id and password',
    ]);
    exit;
}

$secret = (string)($user['user_secret'] ?? '');
$isValid = false;

if ($secret !== '') {
    $isValid = password_verify($password, $secret);
    if (!$isValid) {
        $isValid = hash_equals($secret, $password);
    }
}

if (!$isValid) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid user id and password',
    ]);
    exit;
}

$username = trim((string)($user['userName'] ?? ''));
if ($username === '') {
    $username = (string)($user['email'] ?? '');
}

echo json_encode([
    'success' => true,
    'data' => [
        'user_id' => (int)$user['user_Id'],
        'username' => $username,
    ],
]);
