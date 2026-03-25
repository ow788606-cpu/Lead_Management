<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Api-Token, X-User-Id');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/db.php';

$auth    = requireApiAuth();
$ownerId = $auth['owner_user_id'];

$method = $_SERVER['REQUEST_METHOD'];

// ─── GET: list tags ───────────────────────────────────────────────────────────
if ($method === 'GET') {
    $stmt = $conn->prepare(
        "SELECT id, name,
                COALESCE(description, '')  AS description,
                COALESCE(tag_class, '#0B5CFF') AS color_hex
         FROM tags
         WHERE deleted_at IS NULL
           AND user_id = ?
         ORDER BY id DESC"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('i', $ownerId);
    $stmt->execute();
    $result = $stmt->get_result();
    $rows   = [];
    while ($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
    $stmt->close();

    echo json_encode(['success' => true, 'data' => $rows]);
    exit;
}

// ─── POST: create tag ─────────────────────────────────────────────────────────
if ($method === 'POST') {
    $payload     = json_decode(file_get_contents('php://input'), true);
    $name        = trim((string)($payload['name'] ?? ''));
    $description = trim((string)($payload['description'] ?? ''));
    $colorHex    = strtoupper(trim((string)($payload['color_hex'] ?? '#0B5CFF')));

    if ($name === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Name is required']);
        exit;
    }

    $stmt = $conn->prepare(
        "INSERT INTO tags (user_id, name, description, tag_class, is_active, created_by, created_at)
         VALUES (?, ?, ?, ?, 0, ?, NOW())"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('isssi', $ownerId, $name, $description, $colorHex, $ownerId);
    $ok    = $stmt->execute();
    $newId = $conn->insert_id;
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create tag']);
        exit;
    }

    http_response_code(201);
    echo json_encode(['success' => true, 'data' => [
        'id'          => $newId,
        'name'        => $name,
        'description' => $description,
        'color_hex'   => $colorHex,
    ]]);
    exit;
}

// ─── PUT: update tag ──────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $payload     = json_decode(file_get_contents('php://input'), true);
    $tagId       = (int)($payload['id'] ?? 0);
    $name        = trim((string)($payload['name'] ?? ''));
    $description = trim((string)($payload['description'] ?? ''));
    $colorHex    = strtoupper(trim((string)($payload['color_hex'] ?? '#0B5CFF')));

    if ($tagId <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid tag id']);
        exit;
    }
    if ($name === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Name is required']);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE tags
         SET name = ?, description = ?, tag_class = ?
         WHERE id = ? AND user_id = ? AND deleted_at IS NULL"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('sssii', $name, $description, $colorHex, $tagId, $ownerId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to update tag']);
        exit;
    }

    echo json_encode(['success' => true, 'data' => [
        'id'          => $tagId,
        'name'        => $name,
        'description' => $description,
        'color_hex'   => $colorHex,
    ]]);
    exit;
}

// ─── DELETE: soft-delete tag ──────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid tag id']);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE tags SET deleted_at = NOW()
         WHERE id = ? AND user_id = ?"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('ii', $id, $ownerId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to delete tag']);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
