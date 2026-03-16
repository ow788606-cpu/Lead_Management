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

require_once __DIR__ . '/db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    if ($userId <= 0) {
        echo json_encode(['success' => true, 'data' => []]);
        exit;
    }

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
              AND l.owner_user_id = $userId
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
    exit;
}

if ($method === 'POST') {
    $payload = json_decode(file_get_contents('php://input'), true);
    
    // Check if this is an update request
    if (isset($payload['action']) && $payload['action'] === 'update_status') {
        $leadId = (int)($payload['lead_id'] ?? 0);
        $userId = (int)($payload['user_id'] ?? 0);
        $statusId = (int)($payload['status_id'] ?? 1);
        
        if ($leadId <= 0 || $userId <= 0) {
            http_response_code(422);
            echo json_encode(['success' => false, 'message' => 'Invalid update payload']);
            exit;
        }
        
        // Verify the lead belongs to the user
        $verifyStmt = $conn->prepare(
            "SELECT id FROM leads WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL LIMIT 1"
        );
        if (!$verifyStmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Prepare failed']);
            exit;
        }
        $verifyStmt->bind_param('ii', $leadId, $userId);
        $verifyStmt->execute();
        $lead = $verifyStmt->get_result()->fetch_assoc();
        $verifyStmt->close();
        
        if (!$lead) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Lead not found']);
            exit;
        }
        
        // Update the lead status
        $updateStmt = $conn->prepare(
            "UPDATE leads SET status = ?, updated_at = NOW() WHERE id = ? AND owner_user_id = ?"
        );
        if (!$updateStmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Prepare failed']);
            exit;
        }
        $updateStmt->bind_param('iii', $statusId, $leadId, $userId);
        $ok = $updateStmt->execute();
        $updateStmt->close();
        
        if (!$ok) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to update lead status']);
            exit;
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Lead status updated successfully',
        ]);
        exit;
    }
    
    // Original create lead logic
    $userId = (int)($payload['user_id'] ?? 0);
    $contactId = (int)($payload['contact_id'] ?? 0);
    $serviceName = trim((string)($payload['service_name'] ?? ''));
    $tags = trim((string)($payload['tags'] ?? ''));
    $description = trim((string)($payload['description'] ?? ''));
    $nextFollowUpAt = trim((string)($payload['next_followup_at'] ?? ''));
    $statusId = (int)($payload['status_id'] ?? 1);

    if ($userId <= 0 || $contactId <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid lead payload']);
        exit;
    }

    $contactStmt = $conn->prepare(
        "SELECT id
         FROM contacts
         WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL
         LIMIT 1"
    );
    if (!$contactStmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Prepare failed']);
        exit;
    }
    $contactStmt->bind_param('ii', $contactId, $userId);
    $contactStmt->execute();
    $contact = $contactStmt->get_result()->fetch_assoc();
    $contactStmt->close();

    if (!$contact) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Contact not found']);
        exit;
    }

    $serviceIdValue = null;
    if ($serviceName !== '') {
        $serviceStmt = $conn->prepare(
            "SELECT service_id
             FROM services
             WHERE service_user_id = ? AND deleted_at IS NULL AND service_name = ?
             ORDER BY service_id DESC
             LIMIT 1"
        );
        if (!$serviceStmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Prepare failed']);
            exit;
        }
        $serviceStmt->bind_param('is', $userId, $serviceName);
        $serviceStmt->execute();
        $service = $serviceStmt->get_result()->fetch_assoc();
        $serviceStmt->close();

        if ($service && isset($service['service_id'])) {
            $serviceIdValue = (string)$service['service_id'];
        }
    }

    $nextFollowUpAtValue = null;
    if ($nextFollowUpAt !== '') {
        $followUpDateTime = date_create($nextFollowUpAt);
        if ($followUpDateTime !== false) {
            $nextFollowUpAtValue = $followUpDateTime->format('Y-m-d H:i:s');
        }
    }

    $tagsValue = $tags === '' ? null : $tags;
    $descriptionValue = $description === '' ? null : $description;

    $insertStmt = $conn->prepare(
        "INSERT INTO leads (
            owner_user_id, created_by, assigned_to, contact_id, service_id, description, tags, next_followup_at, status, created_at, updated_at
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())"
    );
    if (!$insertStmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Prepare failed']);
        exit;
    }

    $insertStmt->bind_param(
        'iiiissssi',
        $userId,
        $userId,
        $userId,
        $contactId,
        $serviceIdValue,
        $descriptionValue,
        $tagsValue,
        $nextFollowUpAtValue,
        $statusId
    );
    $ok = $insertStmt->execute();
    $newId = $conn->insert_id;
    $insertStmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create lead']);
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

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
