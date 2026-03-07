<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed',
    ]);
    exit;
}

require_once __DIR__ . '/db.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $leadId = isset($_GET['lead_id']) ? (int)$_GET['lead_id'] : 0;
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    if ($leadId <= 0 || $userId <= 0) {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid lead id',
        ]);
        exit;
    }

    $stmt = $conn->prepare(
        "SELECT lh.id, lh.lead_id, lh.title, lh.description, lh.status_id, lh.priority, lh.scheduled_at, lh.result_notes, lh.meta, lh.created_at
         FROM lead_history lh
         INNER JOIN leads l ON l.id = lh.lead_id
         WHERE lh.lead_id = ? AND l.owner_user_id = ? AND lh.deleted_at IS NULL
         ORDER BY lh.id DESC"
    );

    if (!$stmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Prepare failed',
        ]);
        exit;
    }

    $stmt->bind_param('ii', $leadId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    $rows = [];
    while ($row = $result->fetch_assoc()) {
        $meta = [];
        if (!empty($row['meta'])) {
            $decodedMeta = json_decode((string)$row['meta'], true);
            if (is_array($decodedMeta)) {
                $meta = $decodedMeta;
            }
        }

        $rows[] = [
            'id' => (int)$row['id'],
            'lead_id' => (int)$row['lead_id'],
            'title' => $row['title'],
            'description' => $row['description'],
            'status_id' => isset($row['status_id']) ? (int)$row['status_id'] : 0,
            'priority' => $row['priority'],
            'scheduled_at' => $row['scheduled_at'],
            'result_notes' => $row['result_notes'],
            'created_at' => $row['created_at'],
            'activity' => $meta['activity'] ?? null,
            'result' => $meta['result'] ?? null,
            'lost_reason' => $meta['lost_reason'] ?? null,
            'amount' => $meta['amount'] ?? null,
            'due_at' => $meta['due_at'] ?? null,
            'meta' => $meta,
        ];
    }

    $stmt->close();

    echo json_encode([
        'success' => true,
        'data' => $rows,
    ]);
    exit;
}

$payload = json_decode(file_get_contents('php://input'), true);
$leadId = (int)($payload['lead_id'] ?? 0);
$userId = (int)($payload['user_id'] ?? 0);
$title = trim((string)($payload['title'] ?? ''));
$description = trim((string)($payload['description'] ?? ''));
$statusId = (int)($payload['status_id'] ?? 0);
$priority = strtolower(trim((string)($payload['priority'] ?? 'normal')));
$scheduledAt = trim((string)($payload['scheduled_at'] ?? ''));
$resultNotes = trim((string)($payload['result_notes'] ?? ''));
$meta = is_array($payload['meta'] ?? null) ? $payload['meta'] : [];

if ($leadId <= 0 || $userId <= 0) {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid lead id',
    ]);
    exit;
}

$allowedPriorities = ['low', 'normal', 'high', 'critical'];
if (!in_array($priority, $allowedPriorities, true)) {
    $priority = 'normal';
}

$leadStmt = $conn->prepare(
    "SELECT contact_id
     FROM leads
     WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL
     LIMIT 1"
);

if (!$leadStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Prepare failed',
    ]);
    exit;
}

$leadStmt->bind_param('ii', $leadId, $userId);
$leadStmt->execute();
$lead = $leadStmt->get_result()->fetch_assoc();
$leadStmt->close();

if (!$lead) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'message' => 'Lead not found',
    ]);
    exit;
}

$scheduledAtValue = null;
if ($scheduledAt !== '') {
    $scheduledAtDt = date_create($scheduledAt);
    if ($scheduledAtDt !== false) {
        $scheduledAtValue = $scheduledAtDt->format('Y-m-d H:i:s');
    }
}

$metaJson = !empty($meta) ? json_encode($meta, JSON_UNESCAPED_UNICODE) : null;
$contactId = isset($lead['contact_id']) ? (int)$lead['contact_id'] : 0;

$insertStmt = $conn->prepare(
    "INSERT INTO lead_history (
        contact_id, lead_id, owner_user_id, created_by, assigned_to, title, description, status_id,
        priority, scheduled_at, result_notes, meta, created_at, updated_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())"
);

if (!$insertStmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Prepare failed',
    ]);
    exit;
}

$insertStmt->bind_param(
    'iiiiississss',
    $contactId,
    $leadId,
    $userId,
    $userId,
    $userId,
    $title,
    $description,
    $statusId,
    $priority,
    $scheduledAtValue,
    $resultNotes,
    $metaJson
);
$ok = $insertStmt->execute();
$newId = $conn->insert_id;
$insertStmt->close();

if (!$ok) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to save lead history',
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
