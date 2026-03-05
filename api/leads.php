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
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

require_once __DIR__ . '/db.php';

$sql = "SELECT
            l.id,
            c.name AS contact_name,
            c.email,
            c.contact_number AS phone,
            COALESCE(GROUP_CONCAT(DISTINCT s.service_name ORDER BY s.service_id SEPARATOR ', '), '') AS service_name,
            l.tags,
            l.description,
            l.next_followup_at,
            l.created_at,
            l.status,
            st.name AS status_name
        FROM leads l
        LEFT JOIN contacts c ON c.id = l.contact_id
        LEFT JOIN services s ON FIND_IN_SET(s.service_id, l.service_id) > 0
        LEFT JOIN status st ON st.id = l.status
        WHERE l.deleted_at IS NULL
        GROUP BY l.id, c.name, c.email, c.contact_number, l.tags, l.description, l.next_followup_at, l.created_at, l.status, st.name
        ORDER BY l.id DESC";

$result = $conn->query($sql);
if (!$result) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to fetch leads']);
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
