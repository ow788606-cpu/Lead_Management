<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed',
    ]);
    exit;
}

require_once __DIR__ . '/db.php';

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
