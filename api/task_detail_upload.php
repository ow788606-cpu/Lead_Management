<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Api-Token, X-User-Id');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/db.php';

$auth     = requireApiAuth();
$authId   = $auth['user_id'];
$userType = $auth['user_type'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$taskId = isset($_POST['task_id']) ? (int)$_POST['task_id'] : 0;
$taskSource = isset($_POST['task_source']) ? strtolower(trim((string)$_POST['task_source'])) : 'tasks';
$taskSource = $taskSource === 'lead_tasks' ? 'lead_tasks' : 'tasks';
if ($taskId <= 0) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'task_id required']);
    exit;
}

// Ensure task exists
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
    if (!$row) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Task not found']);
        exit;
    }
} else {
    $filterSql = ($userType === 'business') ? 'owner_user_id = ?' : 'assigned_to = ?';
    $stmt = $conn->prepare(
        "SELECT id FROM tasks WHERE id = ? AND {$filterSql} AND deleted_at IS NULL LIMIT 1"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }
    $stmt->bind_param('ii', $taskId, $authId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if (!$row) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Task not found']);
        exit;
    }
}

if (empty($_FILES['attachment']) || !is_uploaded_file($_FILES['attachment']['tmp_name'])) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'attachment required']);
    exit;
}

$uploadDir = __DIR__ . '/uploads/task_details';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0775, true);
}

$originalName = basename((string)$_FILES['attachment']['name']);
$ext = pathinfo($originalName, PATHINFO_EXTENSION);
$safeExt = $ext !== '' ? '.' . $ext : '';
$fileName = 'taskdetail_' . $authId . '_' . time() . '_' . bin2hex(random_bytes(4)) . $safeExt;
$destPath = $uploadDir . '/' . $fileName;

if (!move_uploaded_file($_FILES['attachment']['tmp_name'], $destPath)) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to save attachment']);
    exit;
}

$meta = [
    'name' => $originalName,
    'path' => 'uploads/task_details/' . $fileName,
    'size' => (int)($_FILES['attachment']['size'] ?? 0),
    'mime' => (string)($_FILES['attachment']['type'] ?? ''),
];

echo json_encode(['success' => true, 'data' => $meta]);
