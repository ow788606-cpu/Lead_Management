<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Api-Token, X-User-Id');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/db.php';

$auth     = requireApiAuth();
$authId   = $auth['user_id'];
$userType = $auth['user_type'];

$method = $_SERVER['REQUEST_METHOD'];

// ─── GET: list tasks ──────────────────────────────────────────────────────────
if ($method === 'GET') {
    $leadId = isset($_GET['lead_id']) ? (int)$_GET['lead_id'] : 0;

    // Match web logic: business → owner_user_id, others → assigned_to
    if ($userType === 'business') {
        $filterSql   = 'owner_user_id = ?';
        $filterParam = $authId;
    } else {
        $filterSql   = 'assigned_to = ?';
        $filterParam = $authId;
    }

    if ($leadId > 0) {
        $stmt = $conn->prepare(
            "SELECT id, owner_user_id, created_by, assigned_to, lead_id, contact_id,
                    title, description, status, priority, due_at, completed_at, created_at, updated_at
             FROM tasks
             WHERE deleted_at IS NULL
               AND {$filterSql}
               AND lead_id = ?
             ORDER BY id DESC"
        );
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $stmt->bind_param('ii', $filterParam, $leadId);
    } else {
        $stmt = $conn->prepare(
            "SELECT id, owner_user_id, created_by, assigned_to, lead_id, contact_id,
                    title, description, status, priority, due_at, completed_at, created_at, updated_at
             FROM tasks
             WHERE deleted_at IS NULL
               AND {$filterSql}
             ORDER BY id DESC"
        );
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $stmt->bind_param('i', $filterParam);
    }

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

// ─── POST: create task ────────────────────────────────────────────────────────
if ($method === 'POST') {
    $payload     = json_decode(file_get_contents('php://input'), true);
    $leadId      = isset($payload['lead_id']) ? (int)$payload['lead_id'] : null;
    $title       = trim((string)($payload['title'] ?? ''));
    $description = trim((string)($payload['description'] ?? ''));
    $priority    = strtolower(trim((string)($payload['priority'] ?? 'normal')));
    $dueAt       = trim((string)($payload['due_at'] ?? ''));

    $allowedPriorities = ['low', 'normal', 'high', 'critical'];
    if (!in_array($priority, $allowedPriorities, true)) {
        $priority = 'normal';
    }

    if ($title === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Task title is required']);
        exit;
    }

    $dueAtValue = null;
    if ($dueAt !== '') {
        $dt = date_create($dueAt);
        if ($dt !== false) {
            $dueAtValue = $dt->format('Y-m-d H:i:s');
        }
    }

    $stmt = $conn->prepare(
        "INSERT INTO tasks (owner_user_id, created_by, assigned_to, lead_id, title, description, status, priority, due_at, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, NOW(), NOW())"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('iiiissss', $authId, $authId, $authId, $leadId, $title, $description, $priority, $dueAtValue);
    $ok    = $stmt->execute();
    $newId = $conn->insert_id;
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create task']);
        exit;
    }

    http_response_code(201);
    echo json_encode(['success' => true, 'data' => ['id' => $newId]]);
    exit;
}

// ─── PUT: update task ─────────────────────────────────────────────────────────
if ($method === 'PUT') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $id      = (int)($payload['id'] ?? 0);

    if ($id <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid task id']);
        exit;
    }

    // Complete task shortcut
    if (isset($payload['is_completed']) && $payload['is_completed'] === true) {
        $stmt = $conn->prepare(
            "UPDATE tasks
             SET status = 'completed', completed_at = NOW(), updated_at = NOW()
             WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL"
        );
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $stmt->bind_param('ii', $id, $authId);
        $ok = $stmt->execute();
        $stmt->close();

        if (!$ok) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to complete task']);
            exit;
        }

        echo json_encode(['success' => true]);
        exit;
    }

    $title       = trim((string)($payload['title'] ?? ''));
    $description = trim((string)($payload['description'] ?? ''));
    $priority    = strtolower(trim((string)($payload['priority'] ?? 'normal')));
    $dueAt       = trim((string)($payload['due_at'] ?? ''));

    $allowedPriorities = ['low', 'normal', 'high', 'critical'];
    if (!in_array($priority, $allowedPriorities, true)) {
        $priority = 'normal';
    }

    if ($title === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Task title is required']);
        exit;
    }

    $dueAtValue = null;
    if ($dueAt !== '') {
        $dt = date_create($dueAt);
        if ($dt !== false) {
            $dueAtValue = $dt->format('Y-m-d H:i:s');
        }
    }

    $stmt = $conn->prepare(
        "UPDATE tasks
         SET title = ?, description = ?, priority = ?, due_at = ?, updated_at = NOW()
         WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('ssssii', $title, $description, $priority, $dueAtValue, $id, $authId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to update task']);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

// ─── PATCH: quick actions (e.g. complete) ─────────────────────────────────────
if ($method === 'PATCH') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $id      = (int)($payload['id'] ?? 0);
    $action  = trim((string)($payload['action'] ?? ''));

    if ($id <= 0 || $action === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid request']);
        exit;
    }

    if ($action === 'complete') {
        $stmt = $conn->prepare(
            "UPDATE tasks
             SET status = 'completed', completed_at = NOW(), updated_at = NOW()
             WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL"
        );
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $stmt->bind_param('ii', $id, $authId);
        $ok = $stmt->execute();
        $stmt->close();

        if (!$ok) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to complete task']);
            exit;
        }

        echo json_encode(['success' => true]);
        exit;
    }

    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Unknown action']);
    exit;
}

// ─── DELETE: soft-delete task ─────────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid task id']);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE tasks
         SET deleted_at = NOW(), updated_at = NOW()
         WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('ii', $id, $authId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to delete task']);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
