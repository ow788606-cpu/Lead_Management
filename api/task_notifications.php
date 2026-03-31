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

function normalize_task_source(?string $source): string
{
    $source = strtolower(trim((string)$source));
    if ($source === 'lead_tasks') return 'lead_tasks';
    return 'tasks';
}

function task_filter_sql(string $userType): array
{
    if ($userType === 'business') {
        return ['owner_user_id = ?', 'i'];
    }
    return ['assigned_to = ?', 'i'];
}

function load_task_for_user(mysqli $conn, int $taskId, int $authId, string $userType, string $taskSource): bool
{
    if ($taskSource === 'lead_tasks') {
        $stmt = $conn->prepare("SELECT id FROM lead_tasks WHERE id = ? LIMIT 1");
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $stmt->bind_param('i', $taskId);
        $stmt->execute();
        $row = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        return (bool)$row;
    }

    [$filterSql, $types] = task_filter_sql($userType);
    $stmt = $conn->prepare(
        "SELECT id FROM tasks
         WHERE id = ? AND {$filterSql} AND deleted_at IS NULL
         LIMIT 1"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }
    $stmt->bind_param('i' . $types, $taskId, $authId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    return (bool)$row;
}

// ─── GET: list notifications ────────────────────────────────────────────────
if ($method === 'GET') {
    $taskId = isset($_GET['task_id']) ? (int)$_GET['task_id'] : 0;
    $taskSource = normalize_task_source($_GET['task_source'] ?? null);
    if ($taskId > 0 && !load_task_for_user($conn, $taskId, $authId, $userType, $taskSource)) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Task not found']);
        exit;
    }

    if ($taskId > 0) {
        $stmt = $conn->prepare(
            "SELECT id, task_id, title, message, is_read, created_at
             FROM task_notifications
             WHERE user_id = ? AND task_id = ? AND task_source = ?
             ORDER BY created_at DESC, id DESC"
        );
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $stmt->bind_param('iis', $authId, $taskId, $taskSource);
    } else {
        $where = "WHERE user_id = ?";
        if ($taskSource === 'lead_tasks') {
            $where .= " AND task_source = 'lead_tasks'";
        } else if (isset($_GET['task_source'])) {
            $where .= " AND task_source = 'tasks'";
        }
        $stmt = $conn->prepare(
            "SELECT id, task_id, title, message, is_read, created_at
             FROM task_notifications
             {$where}
             ORDER BY created_at DESC, id DESC"
        );
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $stmt->bind_param('i', $authId);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    $rows = [];
    while ($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
    $stmt->close();

    echo json_encode(['success' => true, 'data' => $rows]);
    exit;
}

// ─── POST: create notification ──────────────────────────────────────────────
if ($method === 'POST') {
    $payload = json_decode(file_get_contents('php://input'), true);
    if (!is_array($payload)) {
        $payload = [];
    }

    $taskId = isset($payload['task_id']) ? (int)$payload['task_id'] : 0;
    $taskSource = normalize_task_source($payload['task_source'] ?? null);
    $title = trim((string)($payload['title'] ?? ''));
    $message = trim((string)($payload['message'] ?? ''));

    if ($taskId <= 0 || $title === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'task_id and title required']);
        exit;
    }

    if (!load_task_for_user($conn, $taskId, $authId, $userType, $taskSource)) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Task not found']);
        exit;
    }

    $stmt = $conn->prepare(
        "INSERT INTO task_notifications (task_id, user_id, task_source, title, message, is_read, created_at)
         VALUES (?, ?, ?, ?, ?, 0, NOW())"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }
    $stmt->bind_param('iisss', $taskId, $authId, $taskSource, $title, $message);
    $ok = $stmt->execute();
    $newId = $conn->insert_id;
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create notification']);
        exit;
    }

    echo json_encode(['success' => true, 'data' => ['id' => $newId]]);
    exit;
}

// ─── PATCH/PUT: update read state ────────────────────────────────────────────
if ($method === 'PATCH' || $method === 'PUT') {
    $payload = json_decode(file_get_contents('php://input'), true);
    if (!is_array($payload)) {
        $payload = [];
    }

    $id = isset($payload['id']) ? (int)$payload['id'] : 0;
    $isRead = isset($payload['is_read']) ? (int)(bool)$payload['is_read'] : null;

    if ($id <= 0 || $isRead === null) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'id and is_read required']);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE task_notifications
         SET is_read = ?
         WHERE id = ? AND user_id = ?"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }
    $stmt->bind_param('iii', $isRead, $id, $authId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to update notification']);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
