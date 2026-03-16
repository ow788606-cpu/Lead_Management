<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
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
        echo json_encode([
            'success' => true,
            'data' => [],
        ]);
        exit;
    }

    $sql = "SELECT id, name, COALESCE(description, '') AS description, COALESCE(tag_class, '#0B5CFF') AS color_hex
            FROM tags
            WHERE deleted_at IS NULL
              AND user_id = $requestUserId
            ORDER BY id DESC";
    $result = $conn->query($sql);

    if (!$result) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to fetch tags',
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
    $name = trim((string)($payload['name'] ?? ''));
    $description = trim((string)($payload['description'] ?? ''));
    $colorHex = strtoupper(trim((string)($payload['color_hex'] ?? '#0B5CFF')));

    if ($name === '') {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Name is required',
        ]);
        exit;
    }

    $stmt = $conn->prepare(
        "INSERT INTO tags (user_id, name, description, tag_class, is_active, created_by, created_at)
         VALUES (?, ?, ?, ?, 0, ?, NOW())"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Prepare failed',
        ]);
        exit;
    }

    $stmt->bind_param('isssi', $userId, $name, $description, $colorHex, $userId);
    $ok = $stmt->execute();
    $newId = $conn->insert_id;
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to create tag',
        ]);
        exit;
    }

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'data' => [
            'id' => $newId,
            'name' => $name,
            'description' => $description,
            'color_hex' => $colorHex,
        ],
    ]);
    exit;
}

if ($method === 'PUT') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $userId = (int)($payload['user_id'] ?? 0);
    $tagId = (int)($payload['id'] ?? 0);
    $name = trim((string)($payload['name'] ?? ''));
    $description = trim((string)($payload['description'] ?? ''));
    $colorHex = strtoupper(trim((string)($payload['color_hex'] ?? '#0B5CFF')));

    if ($tagId <= 0 || $userId <= 0) {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid tag id or user id',
        ]);
        exit;
    }

    if ($name === '') {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Name is required',
        ]);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE tags 
         SET name = ?, description = ?, tag_class = ?
         WHERE id = ? AND user_id = ? AND deleted_at IS NULL"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Prepare failed',
        ]);
        exit;
    }

    $stmt->bind_param('sssii', $name, $description, $colorHex, $tagId, $userId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to update tag',
        ]);
        exit;
    }

    echo json_encode([
        'success' => true,
        'data' => [
            'id' => $tagId,
            'name' => $name,
            'description' => $description,
            'color_hex' => $colorHex,
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
            'message' => 'Invalid tag id',
        ]);
        exit;
    }

    $stmt = $conn->prepare("UPDATE tags SET deleted_at = NOW() WHERE id = ? AND user_id = ?");
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
            'message' => 'Failed to delete tag',
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
