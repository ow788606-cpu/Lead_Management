<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Api-Token');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

require_once __DIR__ . '/db.php';

$payload    = json_decode(file_get_contents('php://input'), true);
$identifier = trim((string)($payload['identifier'] ?? ''));
$password   = (string)($payload['password'] ?? '');

if ($identifier === '' || $password === '') {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid credentials']);
    exit;
}

// Fetch user by ID, email, or username
$stmt = $conn->prepare(
    "SELECT user_Id, userName, first_name, last_name, email, user_secret, user_type
     FROM users
     WHERE deleted_at IS NULL
       AND (CAST(user_Id AS CHAR) = ? OR email = ? OR userName = ?)
     LIMIT 1"
);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error']);
    exit;
}

$stmt->bind_param('sss', $identifier, $identifier, $identifier);
$stmt->execute();
$result = $stmt->get_result();
$user   = $result ? $result->fetch_assoc() : null;
$stmt->close();

if (!$user) {
    // Constant-time response to prevent user enumeration
    password_verify('dummy', '$2y$10$dummydummydummydummydummydummydummydummydummydummy');
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid credentials']);
    exit;
}

$secret = (string)($user['user_secret'] ?? '');

// Only accept properly hashed passwords
if ($secret === '' || !password_verify($password, $secret)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid credentials']);
    exit;
}

$userId   = (int)$user['user_Id'];
$userType = (string)($user['user_type'] ?? 'personal');

// For employee accounts, find the company owner's ID
$ownerUserId = $userId;
if ($userType === 'employee') {
    $ownerStmt = $conn->prepare(
        "SELECT company_owner_user_id FROM users WHERE user_Id = ? LIMIT 1"
    );
    if ($ownerStmt) {
        $ownerStmt->bind_param('i', $userId);
        $ownerStmt->execute();
        $ownerRow = $ownerStmt->get_result()->fetch_assoc();
        $ownerStmt->close();
        if ($ownerRow && !empty($ownerRow['company_owner_user_id'])) {
            $ownerUserId = (int)$ownerRow['company_owner_user_id'];
        }
    }
}

$firstName = trim((string)($user['first_name'] ?? ''));
$lastName  = trim((string)($user['last_name'] ?? ''));
$fullName  = trim($firstName . ' ' . $lastName);
if ($fullName === '') {
    $fullName = trim((string)($user['userName'] ?? ''));
}

echo json_encode([
    'success' => true,
    'data' => [
        'user_id'               => $userId,
        'username'              => trim((string)($user['userName'] ?? '')),
        'name'                  => $fullName,
        'email'                 => (string)($user['email'] ?? ''),
        'user_type'             => $userType,
        'company_owner_user_id' => $ownerUserId,
    ],
]);
