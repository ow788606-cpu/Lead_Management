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

// ─── GET: list services ───────────────────────────────────────────────────────
if ($method === 'GET') {
    $stmt = $conn->prepare(
        "SELECT service_id, service_name
         FROM services
         WHERE deleted_at IS NULL
           AND service_user_id = ?
         ORDER BY service_id ASC"
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

// ─── POST: create service ─────────────────────────────────────────────────────
if ($method === 'POST') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $name    = trim((string)($payload['service_name'] ?? ''));

    if ($name === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Service name is required']);
        exit;
    }

    $stmt = $conn->prepare(
        "INSERT INTO services (service_user_id, service_name, service_is_active, created_by, created_at, updated_at)
         VALUES (?, ?, 0, ?, NOW(), NOW())"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('isi', $ownerId, $name, $ownerId);
    $ok    = $stmt->execute();
    $newId = $conn->insert_id;
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create service']);
        exit;
    }

    http_response_code(201);
    echo json_encode(['success' => true, 'data' => ['service_id' => $newId, 'service_name' => $name]]);
    exit;
}

// ─── PUT: update service ──────────────────────────────────────────────────────
if ($method === 'PUT') {
    $payload   = json_decode(file_get_contents('php://input'), true);
    $serviceId = (int)($payload['service_id'] ?? 0);
    $name      = trim((string)($payload['service_name'] ?? ''));

    if ($serviceId <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid service id']);
        exit;
    }
    if ($name === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Service name is required']);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE services
         SET service_name = ?, updated_at = NOW()
         WHERE service_id = ? AND service_user_id = ? AND deleted_at IS NULL"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('sii', $name, $serviceId, $ownerId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to update service']);
        exit;
    }

    echo json_encode(['success' => true, 'data' => ['service_id' => $serviceId, 'service_name' => $name]]);
    exit;
}

// ─── DELETE: soft-delete service ─────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid service id']);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE services
         SET deleted_at = NOW(), updated_at = NOW()
         WHERE service_id = ? AND service_user_id = ? AND deleted_at IS NULL"
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
        echo json_encode(['success' => false, 'message' => 'Failed to delete service']);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
