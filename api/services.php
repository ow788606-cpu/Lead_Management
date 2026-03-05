<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/db.php';

$method = $_SERVER['REQUEST_METHOD'];
$requestUserId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

if ($method === 'GET') {
    if ($requestUserId <= 0) {
        echo json_encode(['success' => true, 'data' => []]);
        exit;
    }

    $sql = "SELECT service_id, service_name
            FROM services
            WHERE deleted_at IS NULL
              AND service_user_id = $requestUserId
            ORDER BY service_id ASC";
    $result = $conn->query($sql);

    if (!$result) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to fetch services',
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
    exit;
}

if ($method === 'POST') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $userId = (int)($payload['user_id'] ?? 1);
    $name = trim((string)($payload['service_name'] ?? ''));

    if ($name === '') {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Service name is required',
        ]);
        exit;
    }

    $stmt = $conn->prepare(
        "INSERT INTO services (service_user_id, service_name, service_is_active, created_by, created_at, updated_at)
         VALUES (?, ?, 0, ?, NOW(), NOW())"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Prepare failed',
        ]);
        exit;
    }

    $stmt->bind_param('isi', $userId, $name, $userId);
    $ok = $stmt->execute();
    $newId = $conn->insert_id;
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to create service',
        ]);
        exit;
    }

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'data' => [
            'service_id' => $newId,
            'service_name' => $name,
        ],
    ]);
    exit;
}

if ($method === 'DELETE') {
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0 || $userId <= 0) {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid service id',
        ]);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE services
         SET deleted_at = NOW(), updated_at = NOW()
         WHERE service_id = ? AND service_user_id = ? AND deleted_at IS NULL"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Prepare failed',
        ]);
        exit;
    }

    $stmt->bind_param('ii', $id, $userId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to delete service',
        ]);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

http_response_code(405);
echo json_encode([
    'success' => false,
    'message' => 'Method not allowed',
]);
