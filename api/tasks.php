<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $leadId = isset($_GET['lead_id']) ? (int)$_GET['lead_id'] : 0;
    
    if ($userId <= 0) {
        echo json_encode(['success' => true, 'data' => []]);
        exit;
    }

    // If lead_id is provided, filter by both user_id and lead_id
    if ($leadId > 0) {
        $sql = "SELECT id, owner_user_id, created_by, assigned_to, lead_id, contact_id, title, description, status, priority,
                       due_at, completed_at, created_at, updated_at
                FROM tasks
                WHERE deleted_at IS NULL
                  AND owner_user_id = $userId
                  AND lead_id = $leadId
                ORDER BY id DESC";
    } else {
        // Otherwise, get all tasks for the user
        $sql = "SELECT id, owner_user_id, created_by, assigned_to, lead_id, contact_id, title, description, status, priority,
                       due_at, completed_at, created_at, updated_at
                FROM tasks
                WHERE deleted_at IS NULL
                  AND owner_user_id = $userId
                ORDER BY id DESC";
    }
    
    $result = $conn->query($sql);

    if (!$result) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to fetch tasks',
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
    $leadId = isset($payload['lead_id']) ? (int)$payload['lead_id'] : null;
    $title = trim((string)($payload['title'] ?? ''));
    $description = trim((string)($payload['description'] ?? ''));
    $priority = strtolower(trim((string)($payload['priority'] ?? 'normal')));
    $dueAt = trim((string)($payload['due_at'] ?? ''));

    $allowedPriorities = ['low', 'normal', 'high', 'critical'];
    if (!in_array($priority, $allowedPriorities, true)) {
        $priority = 'normal';
    }

    if ($title === '') {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Task title is required',
        ]);
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
        echo json_encode([
            'success' => false,
            'message' => 'Prepare failed',
        ]);
        exit;
    }

    $stmt->bind_param('iiiissss', $userId, $userId, $userId, $leadId, $title, $description, $priority, $dueAtValue);
    $ok = $stmt->execute();
    $newId = $conn->insert_id;
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to create task',
        ]);
        exit;
    }

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'data' => [
            'id' => $newId,
        ],
    ]);
    exit;
}

if ($method === 'PUT') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $id = (int)($payload['id'] ?? 0);
    $userId = (int)($payload['user_id'] ?? 0);
    
    if ($id <= 0 || $userId <= 0) {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid task update payload',
        ]);
        exit;
    }
    
    // Check if this is a completion request
    if (isset($payload['is_completed']) && $payload['is_completed'] === true) {
        $stmt = $conn->prepare(
            "UPDATE tasks
             SET status = 'completed', completed_at = NOW(), updated_at = NOW()
             WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL"
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
                'message' => 'Failed to complete task',
            ]);
            exit;
        }

        echo json_encode(['success' => true]);
        exit;
    }
    
    // Handle regular task updates
    $title = trim((string)($payload['title'] ?? ''));
    $description = trim((string)($payload['description'] ?? ''));
    $priority = strtolower(trim((string)($payload['priority'] ?? 'normal')));
    $dueAt = trim((string)($payload['due_at'] ?? ''));
    
    $allowedPriorities = ['low', 'normal', 'high', 'critical'];
    if (!in_array($priority, $allowedPriorities, true)) {
        $priority = 'normal';
    }
    
    if ($title === '') {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Task title is required',
        ]);
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
        echo json_encode([
            'success' => false,
            'message' => 'Prepare failed',
        ]);
        exit;
    }
    
    $stmt->bind_param('ssssii', $title, $description, $priority, $dueAtValue, $id, $userId);
    $ok = $stmt->execute();
    $stmt->close();
    
    if (!$ok) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to update task',
        ]);
        exit;
    }
    
    echo json_encode(['success' => true]);
    exit;
}

if ($method === 'PATCH') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $id = (int)($payload['id'] ?? 0);
    $userId = (int)($payload['user_id'] ?? 0);
    $action = trim((string)($payload['action'] ?? ''));

    if ($id <= 0 || $userId <= 0 || $action === '') {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid task update payload',
        ]);
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
                'message' => 'Failed to complete task',
            ]);
            exit;
        }

        echo json_encode(['success' => true]);
        exit;
    }
}

if ($method === 'DELETE') {
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0 || $userId <= 0) {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid task id',
        ]);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE tasks
         SET deleted_at = NOW(), updated_at = NOW()
         WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL"
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
            'message' => 'Failed to delete task',
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
