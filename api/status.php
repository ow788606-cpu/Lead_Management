<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed',
    ]);
    exit;
}

require_once __DIR__ . '/db.php';

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($userId <= 0) {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid user id',
    ]);
    exit;
}

$userCheckStmt = $conn->prepare("SELECT user_Id FROM users WHERE user_Id = ? LIMIT 1");
if (!$userCheckStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Prepare failed',
    ]);
    exit;
}
$userCheckStmt->bind_param('i', $userId);
$userCheckStmt->execute();
$userExists = $userCheckStmt->get_result()->fetch_assoc();
$userCheckStmt->close();

if (!$userExists) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'User not found',
    ]);
    exit;
}

$stmt = $conn->prepare(
    "SELECT DISTINCT s.id, s.name, s.description, s.status_class, s.is_active, s.icon_class, s.`order`
     FROM status s
     INNER JOIN leads l ON l.status = s.id
     WHERE COALESCE(s.is_active, 0) = 1
       AND l.deleted_at IS NULL
       AND l.owner_user_id = ?
     ORDER BY s.`order` ASC, s.id ASC"
);
if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Prepare failed',
    ]);
    exit;
}

$stmt->bind_param('i', $userId);
$stmt->execute();
$result = $stmt->get_result();
if (!$result) {
    $stmt->close();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to fetch statuses',
    ]);
    exit;
}

$rows = [];
while ($row = $result->fetch_assoc()) {
    $rows[] = $row;
}
$stmt->close();

echo json_encode([
    'success' => true,
    'data' => $rows,
]);
