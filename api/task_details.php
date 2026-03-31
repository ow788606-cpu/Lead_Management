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

function load_task_for_user(mysqli $conn, int $taskId, int $authId, string $userType, string $taskSource): ?array
{
    if ($taskSource === 'lead_tasks') {
        $stmt = $conn->prepare(
            "SELECT id FROM lead_tasks WHERE id = ? LIMIT 1"
        );
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $stmt->bind_param('i', $taskId);
        $stmt->execute();
        $row = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        return $row ?: null;
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
    return $row ?: null;
}

// ─── GET: fetch task details ────────────────────────────────────────────────
if ($method === 'GET') {
    $taskId = isset($_GET['task_id']) ? (int)$_GET['task_id'] : 0;
    $taskSource = normalize_task_source($_GET['task_source'] ?? null);
    if ($taskId <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'task_id required']);
        exit;
    }

    if (!load_task_for_user($conn, $taskId, $authId, $userType, $taskSource)) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Task not found']);
        exit;
    }

    $stmt = $conn->prepare(
        "SELECT comments, attachments, collaborators, activities
         FROM task_details
         WHERE task_id = ? AND user_id = ? AND task_source = ?
         LIMIT 1"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }
    $stmt->bind_param('iis', $taskId, $authId, $taskSource);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    $decode = function ($value) {
        if ($value === null || $value === '') return [];
        $decoded = json_decode((string)$value, true);
        return is_array($decoded) ? $decoded : [];
    };

    if (!$row) {
        echo json_encode([
            'success' => true,
            'data' => [
                'task_id' => $taskId,
                'task_source' => $taskSource,
                'comments' => [],
                'attachments' => [],
                'collaborators' => [],
                'activities' => [],
            ],
        ]);
        exit;
    }

    echo json_encode([
        'success' => true,
        'data' => [
            'task_id' => $taskId,
            'task_source' => $taskSource,
            'comments' => $decode($row['comments'] ?? null),
            'attachments' => $decode($row['attachments'] ?? null),
            'collaborators' => $decode($row['collaborators'] ?? null),
            'activities' => $decode($row['activities'] ?? null),
        ],
    ]);
    exit;
}

// ─── PUT/POST: upsert task details ──────────────────────────────────────────
if ($method === 'PUT' || $method === 'POST') {
    $payload = json_decode(file_get_contents('php://input'), true);
    if (!is_array($payload)) {
        $payload = [];
    }

    $taskId = isset($payload['task_id']) ? (int)$payload['task_id'] : 0;
    $taskSource = normalize_task_source($payload['task_source'] ?? null);
    if ($taskId <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'task_id required']);
        exit;
    }

    if (!load_task_for_user($conn, $taskId, $authId, $userType, $taskSource)) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Task not found']);
        exit;
    }

    $encode = function ($value) {
        if (is_string($value)) {
            $trim = trim($value);
            if ($trim !== '' && ($trim[0] === '[' || $trim[0] === '{')) {
                return $trim;
            }
        }
        return json_encode(is_array($value) ? $value : []);
    };

    $comments = $encode($payload['comments'] ?? []);
    $attachments = $encode($payload['attachments'] ?? []);
    $collaborators = $encode($payload['collaborators'] ?? []);
    $activities = $encode($payload['activities'] ?? []);

    $stmt = $conn->prepare(
        "INSERT INTO task_details (task_id, user_id, task_source, comments, attachments, collaborators, activities, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
         ON DUPLICATE KEY UPDATE
           comments = VALUES(comments),
           attachments = VALUES(attachments),
           collaborators = VALUES(collaborators),
           activities = VALUES(activities),
           updated_at = NOW()"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }
    $stmt->bind_param('iisssss', $taskId, $authId, $taskSource, $comments, $attachments, $collaborators, $activities);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to save task details']);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
