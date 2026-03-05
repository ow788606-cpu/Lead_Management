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
if ($leadId <= 0) {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid lead id',
    ]);
    exit;
}

$stmt = $conn->prepare(
    "SELECT id, lead_id, title, description, status_id, priority, scheduled_at, result_notes, meta, created_at
     FROM lead_history
     WHERE lead_id = ? AND deleted_at IS NULL
     ORDER BY id DESC"
);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Prepare failed',
    ]);
    exit;
}

$stmt->bind_param('i', $leadId);
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
