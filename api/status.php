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

$userCheckStmt = $conn->prepare("SELECT id FROM users WHERE id = ? LIMIT 1");
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

$sql = "SELECT id, name, description, status_class, is_active, icon_class, `order`
        FROM status
        WHERE COALESCE(is_active, 0) = 1
        ORDER BY `order` ASC, id ASC";

$result = $conn->query($sql);
if (!$result) {
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

echo json_encode([
    'success' => true,
    'data' => $rows,
]);
